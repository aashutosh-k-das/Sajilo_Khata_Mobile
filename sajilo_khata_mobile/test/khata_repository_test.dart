import 'package:flutter_test/flutter_test.dart';
import 'package:sajilo_khata_mobile/core/database/database_helper.dart';
import 'package:sajilo_khata_mobile/core/database/khata_repository.dart';
import 'package:sajilo_khata_mobile/shared/models/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'demo_shop.dart';

void main() {
  late KhataRepository repo;

  setUpAll(sqfliteFfiInit);

  test('a new install starts with no products, customers or entries', () async {
    await DatabaseHelper.openForTesting(databaseFactoryFfi);
    final empty = KhataRepository(DatabaseHelper.instance);
    expect(await empty.getProducts(), isEmpty);
    expect(await empty.getCustomers(), isEmpty);
    expect(await empty.getTransactions(), isEmpty);
  });

  setUp(() async {
    await DatabaseHelper.openForTesting(databaseFactoryFfi);
    await seedDemoShop(await DatabaseHelper.instance.database);
    repo = KhataRepository(DatabaseHelper.instance);
  });

  test('demo shop fixture loads', () async {
    expect(await repo.getProducts(), hasLength(6));
    expect(await repo.getCustomers(), hasLength(4));
    expect(await repo.getTransactions(), hasLength(4));
  });

  test('cash bill deducts stock and applies 13% VAT without touching khata',
      () async {
    final rice =
        (await repo.getProducts()).firstWhere((p) => p.name.startsWith('Jira'));
    final bill = await repo.saveBill(
      items: [
        CartItem(productId: rice.id, name: rice.name, qty: 2, price: 2450)
      ],
      paymentMethod: 'cash',
      anonymousName: 'Walk-in',
    );

    expect(bill.id, isNotNull);
    expect(bill.subtotal, 4900);
    expect(bill.vat, closeTo(637, 0.001));
    expect(bill.total, closeTo(5537, 0.001));
    expect(bill.customerName, 'Walk-in');

    final after = (await repo.getProducts()).firstWhere((p) => p.id == rice.id);
    expect(after.stockQty, rice.stockQty - 2);
    expect(await repo.getTransactions(), hasLength(4));
  });

  test('credit bill posts the total to the customer ledger', () async {
    final customer =
        (await repo.getCustomers()).firstWhere((c) => c.name == 'Ramesh Parsa');
    final bill = await repo.saveBill(
      items: [CartItem(name: 'Tokla Chiya (500g)', qty: 1, price: 220)],
      paymentMethod: 'credit',
      customer: customer,
      anonymousName: 'Walk-in',
    );

    final updated = await repo.getCustomer(customer.id!);
    expect(updated!.balance, closeTo(customer.balance + bill.total, 0.001));
    final ledger = await repo.getTransactions(customerId: customer.id);
    expect(ledger.first.description, 'Credit bill no. ${bill.id}');
  });

  test('payment reduces balance; metrics reflect outstanding credit', () async {
    final sita = (await repo.getCustomers())
        .firstWhere((c) => c.name == 'Sita Devi Sah');
    await repo.addTransaction(
        customerId: sita.id!,
        type: 'payment',
        amount: 1200,
        description: 'Cleared');

    expect((await repo.getCustomer(sita.id!))!.balance, 0);
    final metrics = await repo.getMetrics();
    expect(metrics.totalCredit, 4500); // Only Ramesh still owes
    expect(metrics.lowStockCount, 3); // Ghee, Atta, Wai Wai
    expect(metrics.activeCustomers, 4);
  });

  test('stock never goes negative', () async {
    final noodles =
        (await repo.getProducts()).firstWhere((p) => p.stockQty == 0);
    await repo.updateStock(noodles.id!, -5);
    expect(
        (await repo.getProducts())
            .firstWhere((p) => p.id == noodles.id)
            .stockQty,
        0);
  });

  test('sync bookkeeping marks records as synced', () async {
    final pending = await repo.pendingSyncCount();
    expect(pending, 4);
    final txs = await repo.getUnsyncedTransactions();
    await repo.markSynced('khata_transactions', txs.map((t) => t.id!).toList());
    expect(await repo.pendingSyncCount(), 0);
  });
}
