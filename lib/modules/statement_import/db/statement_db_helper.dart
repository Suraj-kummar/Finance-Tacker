import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/imported_transaction.dart';

class StatementDBHelper {
  static final StatementDBHelper instance = StatementDBHelper._init();
  static Database? _database;

  StatementDBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('statements.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE imported_transactions ( 
  id $idType, 
  date $textType,
  personName $textType,
  upiId $textType,
  amount $realType,
  type $textType,
  category $textType,
  note $textType,
  sourceBank $textType,
  isEditable $intType
  )
''');


    await db.execute('''
CREATE TABLE person_map ( 
  id $idType, 
  identifiers $textType,
  finalName $textType
  )
''');
  }

  // CRUD for Transactions
  Future<int> createTransaction(ImportedTransaction transaction) async {
    final db = await instance.database;
    return await db.insert('imported_transactions', transaction.toMap());
  }

  Future<ImportedTransaction> readTransaction(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'imported_transactions',
      columns: null,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ImportedTransaction.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<ImportedTransaction>> readAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('imported_transactions', orderBy: 'date DESC');
    return result.map((json) => ImportedTransaction.fromMap(json)).toList();
  }

  Future<int> updateTransaction(ImportedTransaction transaction) async {
    final db = await instance.database;
    return db.update(
      'imported_transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'imported_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Advanced Filter Query
  Future<List<ImportedTransaction>> filterTransactions({
      DateTime? startDate,
      DateTime? endDate,
      double? minAmount,
      double? maxAmount,
      String? personName,
      String? category,
      String? type,
      String? bank,
  }) async {
      final db = await instance.database;
      String whereClause = '1=1';
      List<dynamic> args = [];

      if (startDate != null) {
          whereClause += ' AND date >= ?';
          args.add(startDate.toIso8601String());
      }
      if (endDate != null) {
          whereClause += ' AND date <= ?';
          args.add(endDate.toIso8601String());
      }
      if (minAmount != null) {
          whereClause += ' AND amount >= ?';
          args.add(minAmount);
      }
      if (maxAmount != null) {
          whereClause += ' AND amount <= ?';
          args.add(maxAmount);
      }
      if (personName != null && personName.isNotEmpty) {
          whereClause += ' AND personName LIKE ?';
          args.add('%$personName%');
      }
      if (category != null && category != 'All') {
           whereClause += ' AND category = ?';
           args.add(category);
      }
      if (type != null && type != 'All') {
           whereClause += ' AND type = ?';
           args.add(type);
      }
       if (bank != null && bank.isNotEmpty) {
           whereClause += ' AND sourceBank = ?';
           args.add(bank);
      }

      final result = await db.query(
          'imported_transactions',
          where: whereClause,
          whereArgs: args,
          orderBy: 'date DESC'
      );
      
      return result.map((json) => ImportedTransaction.fromMap(json)).toList();
  }
  
  Future<void> clearAll() async {
      final db = await instance.database;
      await db.delete('imported_transactions');
  }
}
