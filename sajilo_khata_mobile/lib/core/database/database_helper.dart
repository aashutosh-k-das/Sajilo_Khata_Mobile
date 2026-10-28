import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Opens an in-memory database through [factory] with the production schema and seed data.
  @visibleForTesting
  static Future<void> openForTesting(DatabaseFactory factory) async {
    await _database?.close();
    _database = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1, onCreate: instance._createDB),
    );
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sajilo_khata.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const numType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // 1. Inventory table
    await db.execute('''
      CREATE TABLE inventory (
        id $idType,
        name $textType,
        category $textType,
        stockQty $intType,
        buyingPrice $numType,
        sellingPrice $numType,
        minThreshold $intType
      )
    ''');

    // 2. Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id $idType,
        name $textType,
        phone $textType,
        balance $numType DEFAULT 0.0
      )
    ''');

    // 3. Bills (Invoices) Table
    await db.execute('''
      CREATE TABLE bills (
        id $idType,
        customerId $textNullable,
        customerName $textType,
        itemsJson $textType,
        subtotal $numType,
        vat $numType,
        total $numType,
        date $textType,
        paymentMethod $textType,
        syncStatus $intType DEFAULT 0
      )
    ''');

    // 4. Khata Transactions Table
    await db.execute('''
      CREATE TABLE khata_transactions (
        id $idType,
        customerId $intType,
        type $textType, -- 'credit' or 'payment'
        amount $numType,
        description $textType,
        date $textType,
        syncStatus $intType DEFAULT 0
      )
    ''');

    await _seed(db);
  }

  // Demo Birgunj kirana shop data, mirrors the web prototype's seed set
  Future _seed(Database db) async {
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

  // Common operations helpers
  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(table, row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await instance.database;
    return await db.query(table);
  }

  Future<int> update(String table, Map<String, dynamic> row, String idColumn,
      dynamic idVal) async {
    final db = await instance.database;
    return await db.update(
      table,
      row,
      where: '$idColumn = ?',
      whereArgs: [idVal],
    );
  }

  Future<int> delete(String table, String idColumn, dynamic idVal) async {
    final db = await instance.database;
    return await db.delete(
      table,
      where: '$idColumn = ?',
      whereArgs: [idVal],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
