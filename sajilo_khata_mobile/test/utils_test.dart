import 'package:flutter_test/flutter_test.dart';
import 'package:sajilo_khata_mobile/core/l10n/app_strings.dart';
import 'package:sajilo_khata_mobile/core/utils/vat_calculator.dart';
import 'package:sajilo_khata_mobile/features/billing/receipt_dialog.dart';
import 'package:sajilo_khata_mobile/shared/models/models.dart';

void main() {
  test('VAT is 13% of subtotal', () {
    expect(VatCalculator.calculateVat(1000), closeTo(130, 0.0001));
    expect(VatCalculator.calculateTotal(1000), closeTo(1130, 0.0001));
    expect(VatCalculator.formatCurrency(1234.5), 'रु. 1234.50');
  });

  test('both languages define the same keys', () {
    expect(AppStrings.keysFor('ne'), AppStrings.keysFor('en'));
    expect(const AppStrings('en')['checkout'], 'Create Bill');
  });

  test('receipt text includes items and totals', () {
    final bill = Bill(
      id: 7,
      customerName: 'Ramesh Parsa',
      items: [CartItem(name: 'Sugar / Sakhar (1kg)', qty: 2, price: 98)],
      subtotal: 196,
      vat: 25.48,
      total: 221.48,
      date: DateTime(2026, 1, 15, 10, 30),
      paymentMethod: 'cash',
    );
    final text = buildReceiptText(bill);
    expect(text, contains('Invoice: #7'));
    expect(text, contains('Ramesh Parsa'));
    expect(text, contains('2x98'));
    expect(text, contains('Rs. 221.48'));
  });
}
