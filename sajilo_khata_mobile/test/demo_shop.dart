import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Demo Birgunj kirana shop data (mirrors the web prototype's seed set).
/// Test-only: real installs start with an empty database.
Future<void> seedDemoShop(Database db) async {
  const products = [
    ['Jira Masino Chamal (25kg)', 'Groceries', 12, 2100.0, 2450.0, 3],
    ['DDC Ghee (1 Litre)', 'Dairy', 5, 1050.0, 1200.0, 5],
    ['Tokla Chiya (500g)', 'Tea & Sugar', 18, 180.0, 220.0, 4],
    ['Sugar / Sakhar (1kg)', 'Tea & Sugar', 45, 85.0, 98.0, 10],
    ['Aashirvaad Atta (5kg)', 'Groceries', 2, 480.0, 540.0, 5],
    ['Wai Wai Noodles (1 Case)', 'Snacks', 0, 650.0, 720.0, 2],
  ];
  for (final p in products) {
    await db.insert('inventory', {
      'name': p[0],
      'category': p[1],
      'stockQty': p[2],
      'buyingPrice': p[3],
      'sellingPrice': p[4],
      'minThreshold': p[5],
    });
  }

  const customers = [
    ['Ramesh Parsa', '9855012345', 4500.0],
    ['Sita Devi Sah', '9845098765', 1200.0],
    ['Birgunj Kirana Supplier', '9804011223', 0.0],
    ['Hari Prasad Acharya', '9812345678', -500.0],
  ];
  for (final c in customers) {
    await db
        .insert('customers', {'name': c[0], 'phone': c[1], 'balance': c[2]});
  }

  final now = DateTime.now();
  final txs = [
    [
      1,
      'credit',
      3500.0,
      'Basmati rice & oil groceries',
      now.subtract(const Duration(days: 3))
    ],
    [
      1,
      'credit',
      1000.0,
      'Sugar and tea',
      now.subtract(const Duration(days: 2))
    ],
    [
      2,
      'credit',
      2000.0,
      'DDC Ghee bottle',
      now.subtract(const Duration(days: 1))
    ],
    [
      2,
      'payment',
      800.0,
      'Partial payment via cash',
      now.subtract(const Duration(hours: 4))
    ],
  ];
  for (final t in txs) {
    await db.insert('khata_transactions', {
      'customerId': t[0],
      'type': t[1],
      'amount': t[2],
      'description': t[3],
      'date': (t[4] as DateTime).toIso8601String(),
    });
  }
}
