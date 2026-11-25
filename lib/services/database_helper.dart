import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/wallet.dart';
import '../models/category.dart';
import '../models/transaction_entry.dart';
import '../models/budget.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'awan_cash.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        initial_balance INTEGER NOT NULL DEFAULT 0,
        color INTEGER NOT NULL,
        icon TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        wallet_id INTEGER NOT NULL,
        to_wallet_id INTEGER,
        category_id INTEGER,
        date_time TEXT NOT NULL,
        notes TEXT,
        receipt_path TEXT,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id) ON DELETE CASCADE,
        FOREIGN KEY (to_wallet_id) REFERENCES wallets (id) ON DELETE SET NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        monthly_limit INTEGER NOT NULL,
        month_year TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Seed data bawaan awal
    await _seedDefaults(db);
  }

  Future<void> _seedDefaults(Database db) async {
    // Dompet Awal
    await db.insert('wallets', {
      'name': 'Uang Tunai',
      'type': 'cash',
      'initial_balance': 150000,
      'color': 0xFF10B981, // Emerald
      'icon': 'payments',
    });
    await db.insert('wallets', {
      'name': 'Bank BCA',
      'type': 'bank',
      'initial_balance': 2500000,
      'color': 0xFF0EA5E9, // Sky Blue
      'icon': 'savings',
    });
    await db.insert('wallets', {
      'name': 'GoPay',
      'type': 'ewallet',
      'initial_balance': 75000,
      'color': 0xFF6366F1, // Indigo
      'icon': 'phone_android',
    });

    // Kategori Pengeluaran
    final defaultExpenses = [
      {'name': 'Makanan & Minuman', 'icon': 'restaurant', 'color': 0xFFF97316},
      {'name': 'Transportasi', 'icon': 'directions_car', 'color': 0xFF0EA5E9},
      {'name': 'Belanja Harian', 'icon': 'shopping_bag', 'color': 0xFFEC4899},
      {'name': 'Tagihan & Utilitas', 'icon': 'bolt', 'color': 0xFFEAB308},
      {'name': 'Hiburan & Hobi', 'icon': 'sports_esports', 'color': 0xFF8B5CF6},
      {'name': 'Kesehatan', 'icon': 'local_hospital', 'color': 0xFFEF4444},
      {'name': 'Pendidikan', 'icon': 'school', 'color': 0xFF3B82F6},
      {'name': 'Keluarga & Donasi', 'icon': 'volunteer_activism', 'color': 0xFF10B981},
      {'name': 'Lain-lain', 'icon': 'more_horiz', 'color': 0xFF64748B},
    ];

    for (var exp in defaultExpenses) {
      await db.insert('categories', {
        'name': exp['name'],
        'type': 'expense',
        'icon': exp['icon'],
        'color': exp['color'],
      });
    }

    // Kategori Pemasukan
    final defaultIncomes = [
      {'name': 'Gaji Pokok', 'icon': 'payments', 'color': 0xFF10B981},
      {'name': 'Bonus & Tunjangan', 'icon': 'card_giftcard', 'color': 0xFF06B6D4},
      {'name': 'Hasil Usaha / Jual', 'icon': 'storefront', 'color': 0xFF3B82F6},
      {'name': 'Hasil Investasi', 'icon': 'trending_up', 'color': 0xFF8B5CF6},
      {'name': 'Hadiah / Pemberian', 'icon': 'redeem', 'color': 0xFFEC4899},
      {'name': 'Pemasukan Lain', 'icon': 'savings', 'color': 0xFF64748B},
    ];

    for (var inc in defaultIncomes) {
      await db.insert('categories', {
        'name': inc['name'],
        'type': 'income',
        'icon': inc['icon'],
        'color': inc['color'],
      });
    }
  }

  // ==================== WALLET OPERATIONS ====================

  Future<List<Wallet>> getWallets() async {
    final db = await database;
    final maps = await db.query('wallets', orderBy: 'id ASC');
    return maps.map((e) => Wallet.fromMap(e)).toList();
  }

  Future<int> insertWallet(Wallet wallet) async {
    final db = await database;
    return await db.insert('wallets', wallet.toMap());
  }

  Future<int> updateWallet(Wallet wallet) async {
    final db = await database;
    return await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  Future<int> deleteWallet(int id) async {
    final db = await database;
    return await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  /// Menghitung saldo riil setiap dompet berdasarkan saldo awal dan mutasi transaksi
  Future<Map<int, int>> calculateWalletBalances() async {
    final wallets = await getWallets();
    final balances = <int, int>{};

    for (var w in wallets) {
      balances[w.id!] = w.initialBalance;
    }

    final txs = await getTransactions();
    for (var tx in txs) {
      if (tx.type == TransactionType.expense) {
        if (balances.containsKey(tx.walletId)) {
          balances[tx.walletId] = balances[tx.walletId]! - tx.amount;
        }
      } else if (tx.type == TransactionType.income) {
        if (balances.containsKey(tx.walletId)) {
          balances[tx.walletId] = balances[tx.walletId]! + tx.amount;
        }
      } else if (tx.type == TransactionType.transfer) {
        // Keluar dari dompet asal
        if (balances.containsKey(tx.walletId)) {
          balances[tx.walletId] = balances[tx.walletId]! - tx.amount;
        }
        // Masuk ke dompet tujuan
        if (tx.toWalletId != null && balances.containsKey(tx.toWalletId)) {
          balances[tx.toWalletId!] = balances[tx.toWalletId!]! + tx.amount;
        }
      }
    }

    return balances;
  }

  // ==================== CATEGORY OPERATIONS ====================

  Future<List<Category>> getCategories({TransactionType? type}) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: type != null ? 'type = ?' : null,
      whereArgs: type != null ? [type.name] : null,
      orderBy: 'id ASC',
    );
    return maps.map((e) => Category.fromMap(e)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== TRANSACTION OPERATIONS ====================

  Future<List<TransactionEntry>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? walletId,
    TransactionType? type,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('date_time >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('date_time < ?');
      whereArgs.add(endDate.toIso8601String());
    }
    if (walletId != null) {
      whereClauses.add('(wallet_id = ? OR to_wallet_id = ?)');
      whereArgs.addAll([walletId, walletId]);
    }
    if (type != null) {
      whereClauses.add('type = ?');
      whereArgs.add(type.name);
    }

    final maps = await db.query(
      'transactions',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date_time DESC, id DESC',
    );

    return maps.map((e) => TransactionEntry.fromMap(e)).toList();
  }

  Future<int> insertTransaction(TransactionEntry tx) async {
    final db = await database;
    return await db.insert('transactions', tx.toMap());
  }

  Future<int> updateTransaction(TransactionEntry tx) async {
    final db = await database;
    return await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== BUDGET OPERATIONS ====================

  Future<List<Budget>> getBudgetsForMonth(String monthYear) async {
    final db = await database;
    final maps = await db.query(
      'budgets',
      where: 'month_year = ?',
      whereArgs: [monthYear],
      orderBy: 'id ASC',
    );
    return maps.map((e) => Budget.fromMap(e)).toList();
  }

  Future<int> setBudget(Budget budget) async {
    final db = await database;
    final existing = await db.query(
      'budgets',
      where: 'category_id = ? AND month_year = ?',
      whereArgs: [budget.categoryId, budget.monthYear],
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.update(
        'budgets',
        {'monthly_limit': budget.monthlyLimit},
        where: 'id = ?',
        whereArgs: [id],
      );
      return id;
    } else {
      return await db.insert('budgets', budget.toMap());
    }
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== SETTINGS (KEY-VALUE) ====================

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==================== BACKUP & RESTORE ====================

  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    final wallets = await db.query('wallets');
    final categories = await db.query('categories');
    final transactions = await db.query('transactions');
    final budgets = await db.query('budgets');
    final settings = await db.query('settings');

    return {
      'app': 'Awan Cash',
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'wallets': wallets,
      'categories': categories,
      'transactions': transactions,
      'budgets': budgets,
      'settings': settings,
    };
  }

  Future<bool> importData(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final db = await database;

      await db.transaction((txn) async {
        // Hapus data lama
        await txn.delete('transactions');
        await txn.delete('budgets');
        await txn.delete('wallets');
        await txn.delete('categories');
        await txn.delete('settings');

        // Pulihkan data
        if (data['wallets'] != null) {
          for (var item in data['wallets']) {
            await txn.insert('wallets', Map<String, dynamic>.from(item));
          }
        }
        if (data['categories'] != null) {
          for (var item in data['categories']) {
            await txn.insert('categories', Map<String, dynamic>.from(item));
          }
        }
        if (data['transactions'] != null) {
          for (var item in data['transactions']) {
            await txn.insert('transactions', Map<String, dynamic>.from(item));
          }
        }
        if (data['budgets'] != null) {
          for (var item in data['budgets']) {
            await txn.insert('budgets', Map<String, dynamic>.from(item));
          }
        }
        if (data['settings'] != null) {
          for (var item in data['settings']) {
            await txn.insert('settings', Map<String, dynamic>.from(item));
          }
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
