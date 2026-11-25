import 'package:flutter/material.dart';
import '../core/dates.dart';
import '../models/wallet.dart';
import '../models/category.dart';
import '../models/transaction_entry.dart';
import '../models/budget.dart';
import '../services/database_helper.dart';
import '../services/security_service.dart';

class AppState extends ChangeNotifier {
  static final AppState instance = AppState._internal();
  AppState._internal();

  bool _initialized = false;
  bool get initialized => _initialized;

  // Keamanan
  bool _isLocked = false;
  bool get isLocked => _isLocked;

  bool _isPinSet = false;
  bool get isPinSet => _isPinSet;

  bool _isBiometricEnabled = false;
  bool get isBiometricEnabled => _isBiometricEnabled;

  // Tema
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // Data
  List<Wallet> _wallets = [];
  List<Wallet> get wallets => _wallets;

  Map<int, int> _walletBalances = {};
  Map<int, int> get walletBalances => _walletBalances;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  List<TransactionEntry> _transactions = [];
  List<TransactionEntry> get transactions => _transactions;

  List<Budget> _budgets = [];
  List<Budget> get budgets => _budgets;

  // Bulan aktif untuk analisis & anggaran
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime get selectedMonth => _selectedMonth;

  // ==================== INISIALISASI ====================

  Future<void> initialize() async {
    // Muat preferensi tema
    final savedTheme = await DatabaseHelper.instance.getSetting('app_theme');
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Cek status keamanan
    _isPinSet = await SecurityService.instance.isPinSet();
    _isBiometricEnabled = await SecurityService.instance.isBiometricEnabled();
    _isLocked = _isPinSet;

    await refreshAllData();
    _initialized = true;
    notifyListeners();
  }

  void unlock() {
    _isLocked = false;
    notifyListeners();
  }

  void lock() {
    if (_isPinSet) {
      _isLocked = true;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String val = 'system';
    if (mode == ThemeMode.dark) val = 'dark';
    if (mode == ThemeMode.light) val = 'light';
    await DatabaseHelper.instance.setSetting('app_theme', val);
    notifyListeners();
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month);
    refreshBudgets();
    notifyListeners();
  }

  // ==================== REFRESH DATA ====================

  Future<void> refreshAllData() async {
    _wallets = await DatabaseHelper.instance.getWallets();
    _walletBalances = await DatabaseHelper.instance.calculateWalletBalances();
    _categories = await DatabaseHelper.instance.getCategories();
    _transactions = await DatabaseHelper.instance.getTransactions();

    await refreshBudgets();
    _isPinSet = await SecurityService.instance.isPinSet();
    _isBiometricEnabled = await SecurityService.instance.isBiometricEnabled();

    notifyListeners();
  }

  Future<void> refreshBudgets() async {
    final monthKey =
        '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
    _budgets = await DatabaseHelper.instance.getBudgetsForMonth(monthKey);
    notifyListeners();
  }

  // ==================== KALKULASI & STATISTIK ====================

  int get totalNetWorth {
    int total = 0;
    for (var bal in _walletBalances.values) {
      total += bal;
    }
    return total;
  }

  int get monthlyIncome {
    final range = monthRange(_selectedMonth);
    return _transactions
        .where((t) => t.type == TransactionType.income && range.contains(t.dateTime))
        .fold(0, (sum, t) => sum + t.amount);
  }

  int get monthlyExpense {
    final range = monthRange(_selectedMonth);
    return _transactions
        .where((t) => t.type == TransactionType.expense && range.contains(t.dateTime))
        .fold(0, (sum, t) => sum + t.amount);
  }

  /// Pengeluaran per kategori untuk bulan terpilih (categoryId -> total)
  Map<int, int> get categoryMonthlyExpense {
    final range = monthRange(_selectedMonth);
    final map = <int, int>{};
    for (var tx in _transactions) {
      if (tx.type == TransactionType.expense &&
          tx.categoryId != null &&
          range.contains(tx.dateTime)) {
        map[tx.categoryId!] = (map[tx.categoryId!] ?? 0) + tx.amount;
      }
    }
    return map;
  }

  // ==================== OPERASI TRANSAKSI ====================

  Future<void> addTransaction(TransactionEntry tx) async {
    await DatabaseHelper.instance.insertTransaction(tx);
    await refreshAllData();
  }

  Future<void> updateTransaction(TransactionEntry tx) async {
    await DatabaseHelper.instance.updateTransaction(tx);
    await refreshAllData();
  }

  Future<void> deleteTransaction(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await refreshAllData();
  }

  // ==================== OPERASI DOMPET ====================

  Future<void> addWallet(Wallet w) async {
    await DatabaseHelper.instance.insertWallet(w);
    await refreshAllData();
  }

  Future<void> updateWallet(Wallet w) async {
    await DatabaseHelper.instance.updateWallet(w);
    await refreshAllData();
  }

  Future<void> deleteWallet(int id) async {
    await DatabaseHelper.instance.deleteWallet(id);
    await refreshAllData();
  }

  // ==================== OPERASI KATEGORI ====================

  Future<void> addCategory(Category c) async {
    await DatabaseHelper.instance.insertCategory(c);
    await refreshAllData();
  }

  Future<void> updateCategory(Category c) async {
    await DatabaseHelper.instance.updateCategory(c);
    await refreshAllData();
  }

  Future<void> deleteCategory(int id) async {
    await DatabaseHelper.instance.deleteCategory(id);
    await refreshAllData();
  }

  // ==================== OPERASI ANGGARAN ====================

  Future<void> setBudget(int categoryId, int monthlyLimit) async {
    final monthKey =
        '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
    final budget = Budget(
      categoryId: categoryId,
      monthlyLimit: monthlyLimit,
      monthYear: monthKey,
    );
    await DatabaseHelper.instance.setBudget(budget);
    await refreshBudgets();
  }

  Future<void> deleteBudget(int id) async {
    await DatabaseHelper.instance.deleteBudget(id);
    await refreshBudgets();
  }

  // ==================== KEAMANAN ====================

  Future<void> setPin(String pin) async {
    await SecurityService.instance.setPin(pin);
    _isPinSet = true;
    notifyListeners();
  }

  Future<void> removePin() async {
    await SecurityService.instance.removePin();
    _isPinSet = false;
    _isBiometricEnabled = false;
    _isLocked = false;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await SecurityService.instance.setBiometricEnabled(enabled);
    _isBiometricEnabled = enabled;
    notifyListeners();
  }
}
