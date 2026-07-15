import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

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
  }

  // Common operations helpers
  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await instance.database;
    return await db.query(table);
  }

  Future<int> update(String table, Map<String, dynamic> row, String idColumn, dynamic idVal) async {
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
