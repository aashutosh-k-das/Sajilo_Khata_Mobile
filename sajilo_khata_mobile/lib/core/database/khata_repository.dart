import 'package:sqflite/sqflite.dart';
import '../../shared/models/models.dart';
import '../utils/vat_calculator.dart';
import 'database_helper.dart';

/// Business operations over the local SQLite store (offline-first).
/// Every write marks records as unsynced so [SyncService] can push them later.
class KhataRepository {
  KhataRepository(this._dbHelper);

  final DatabaseHelper _dbHelper;

  Future<Database> get _db => _dbHelper.database;

  // --- Inventory ---
  Future<List<InventoryItem>> getProducts() async {
    final db = await _db;
    final rows = await db.query('inventory', orderBy: 'name COLLATE NOCASE');
    return rows.map(InventoryItem.fromMap).toList();
  }

  Future<int> saveProduct(InventoryItem item) async {
    final db = await _db;
    if (item.id != null) {
      await db.update('inventory', item.toMap(),
          where: 'id = ?', whereArgs: [item.id]);
      return item.id!;
    }
    return db.insert('inventory', item.toMap());
  }

  Future<void> updateStock(int productId, int newQty) async {
    final db = await _db;
    await db.update(
      'inventory',
      {'stockQty': newQty < 0 ? 0 : newQty},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> deleteProduct(int productId) async {
    final db = await _db;
    await db.delete('inventory', where: 'id = ?', whereArgs: [productId]);
  }

  // --- Customers ---
  Future<List<Customer>> getCustomers() async {
    final db = await _db;
    final rows = await db.query('customers', orderBy: 'name COLLATE NOCASE');
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> getCustomer(int id) async {
    final db = await _db;
    final rows =
        await db.query('customers', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Customer.fromMap(rows.first);
  }

  Future<int> addCustomer(String name, String phone) async {
    final db = await _db;
    return db.insert(
        'customers', Customer(name: name.trim(), phone: phone.trim()).toMap());
  }

  // --- Khata ledger ---
  Future<List<KhataTransaction>> getTransactions(
      {int? customerId, int? limit}) async {
    final db = await _db;
    final rows = await db.query(
      'khata_transactions',
      where: customerId != null ? 'customerId = ?' : null,
      whereArgs: customerId != null ? [customerId] : null,
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map(KhataTransaction.fromMap).toList();
  }

  /// Records a ledger entry and adjusts the customer's balance.
  /// 'credit' = customer owes the shop more, 'payment' = customer paid back.
  Future<void> addTransaction({
    required int customerId,
    required String type,
    required double amount,
    required String description,
  }) async {
    final db = await _db;
    await db.transaction(
        (txn) => _addTransaction(txn, customerId, type, amount, description));
  }

  Future<void> _addTransaction(
    DatabaseExecutor txn,
    int customerId,
    String type,
    double amount,
    String description,
  ) async {
    await txn.insert(
      'khata_transactions',
      KhataTransaction(
        customerId: customerId,
        type: type,
        amount: amount,
        description: description,
        date: DateTime.now(),
      ).toMap(),
    );
    final delta = type == 'credit' ? amount : -amount;
    await txn.rawUpdate(
      'UPDATE customers SET balance = balance + ? WHERE id = ?',
      [delta, customerId],
    );
  }

  // --- Billing ---
  Future<List<Bill>> getBills() async {
    final db = await _db;
    final rows = await db.query('bills', orderBy: 'date DESC');
    return rows.map(Bill.fromMap).toList();
  }

  /// Saves a bill, deducts stock and, for credit sales, posts the total to the customer's khata.
  Future<Bill> saveBill({
    required List<CartItem> items,
    required String paymentMethod,
    Customer? customer,
    required String anonymousName,
  }) async {
    final subtotal = items.fold<double>(0, (sum, i) => sum + i.total);
    final bill = Bill(
      customerId: customer?.id,
      customerName: customer?.name ?? anonymousName,
      items: items,
      subtotal: subtotal,
      vat: VatCalculator.calculateVat(subtotal),
      total: VatCalculator.calculateTotal(subtotal),
      date: DateTime.now(),
      paymentMethod: paymentMethod,
    );

    final db = await _db;
    final id = await db.transaction((txn) async {
      final billId = await txn.insert('bills', bill.toMap());
      for (final item in items) {
        await txn.rawUpdate(
          'UPDATE inventory SET stockQty = MAX(0, stockQty - ?) WHERE '
          '${item.productId != null ? 'id = ?' : 'name = ?'}',
          [item.qty, item.productId ?? item.name],
        );
      }
      if (paymentMethod == 'credit' && customer?.id != null) {
        await _addTransaction(txn, customer!.id!, 'credit', bill.total,
            'Credit bill no. $billId');
      }
      return billId;
    });

    return Bill(
      id: id,
      customerId: bill.customerId,
      customerName: bill.customerName,
      items: bill.items,
      subtotal: bill.subtotal,
      vat: bill.vat,
      total: bill.total,
      date: bill.date,
      paymentMethod: bill.paymentMethod,
    );
  }

  // --- Dashboard ---
  Future<DashboardMetrics> getMetrics() async {
    final db = await _db;
    final now = DateTime.now();
    final startOfToday =
        DateTime(now.year, now.month, now.day).toIso8601String();

    final sales = await db.rawQuery(
      'SELECT COALESCE(SUM(total), 0) AS v FROM bills WHERE date >= ?',
      [startOfToday],
    );
    final credit = await db.rawQuery(
      'SELECT COALESCE(SUM(balance), 0) AS v FROM customers WHERE balance > 0',
    );
    final lowStock = await db.rawQuery(
      'SELECT COUNT(*) AS v FROM inventory WHERE stockQty <= minThreshold',
    );
    final customers = await db.rawQuery('SELECT COUNT(*) AS v FROM customers');

    return DashboardMetrics(
      todaySales: (sales.first['v'] as num).toDouble(),
      totalCredit: (credit.first['v'] as num).toDouble(),
      lowStockCount: lowStock.first['v'] as int,
      activeCustomers: customers.first['v'] as int,
      pendingSync: await pendingSyncCount(),
    );
  }

  // --- Sync bookkeeping ---
  Future<int> pendingSyncCount() async {
    final db = await _db;
    final bills = await db
        .rawQuery('SELECT COUNT(*) AS v FROM bills WHERE syncStatus = 0');
    final txs = await db.rawQuery(
      'SELECT COUNT(*) AS v FROM khata_transactions WHERE syncStatus = 0',
    );
    return (bills.first['v'] as int) + (txs.first['v'] as int);
  }

  Future<List<Bill>> getUnsyncedBills() async {
    final db = await _db;
    final rows = await db.query('bills', where: 'syncStatus = 0');
    return rows.map(Bill.fromMap).toList();
  }

  Future<List<KhataTransaction>> getUnsyncedTransactions() async {
    final db = await _db;
    final rows = await db.query('khata_transactions', where: 'syncStatus = 0');
    return rows.map(KhataTransaction.fromMap).toList();
  }

  Future<void> markSynced(String table, List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await _db;
    await db.update(
      table,
      {'syncStatus': 1},
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }
}
