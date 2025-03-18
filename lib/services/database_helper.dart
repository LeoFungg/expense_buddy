import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_buddy.db');
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

  Future<void> _createDB(Database db, int version) async {
    // Create expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    // Create settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Insert default settings
    await db.insert('settings', {
      'key': 'monthly_budget',
      'value': '1000.0',
    });
    await db.insert('settings', {
      'key': 'currency',
      'value': 'HKD',
    });
    await db.insert('settings', {
      'key': 'notifications_enabled',
      'value': 'true',
    });
    await db.insert('settings', {
      'key': 'biometric_enabled',
      'value': 'false',
    });
  }

  // Expense operations
  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert(
      'expenses',
      {
        'id': expense.id,
        'description': expense.description,
        'amount': expense.amount,
        'category': expense.category,
        'date': expense.date.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('expenses');
    return List.generate(maps.length, (i) {
      return Expense(
        id: maps[i]['id'],
        description: maps[i]['description'],
        amount: maps[i]['amount'],
        category: maps[i]['category'],
        date: DateTime.parse(maps[i]['date']),
      );
    });
  }

  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Category operations
  Future<void> insertCategory(ExpenseCategory category) async {
    final db = await database;
    await db.insert(
      'categories',
      {
        'id': category.id,
        'name': category.name,
        'icon': category.icon.codePoint.toString(),
        'color': category.color.value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseCategory>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) {
      return ExpenseCategory(
        id: maps[i]['id'],
        name: maps[i]['name'],
        icon: IconData(int.parse(maps[i]['icon']), fontFamily: 'MaterialIcons'),
        color: Color(maps[i]['color']),
      );
    });
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Settings operations
  Future<void> updateSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  // Close database
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
} 