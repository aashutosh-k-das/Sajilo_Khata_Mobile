class VatCalculator {
  static const double vatRate = 0.13; // 13% standard VAT in Nepal

  /// Calculates the VAT amount for a given subtotal
  static double calculateVat(double subtotal) {
    return subtotal * vatRate;
  }

  /// Calculates the total including 13% VAT
  static double calculateTotal(double subtotal) {
    return subtotal * (1.0 + vatRate);
  }

  /// Formats double as a Nepalese Currency String (NPR)
  static String formatCurrency(double amount) {
    return 'रु. ${amount.toStringAsFixed(2)}';
  }
}
