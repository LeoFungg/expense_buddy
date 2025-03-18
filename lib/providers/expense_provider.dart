import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../services/database_helper.dart';

enum SortOption {
  dateNewest,
  dateOldest,
  amountHigh,
  amountLow,
  category,
}

class ExpenseProvider with ChangeNotifier {
  final List<Expense> _expenses = [];
  String _searchQuery = '';
  String? _selectedCategory;
  DateTimeRange? _dateRange;
  double? _minAmount;
  double? _maxAmount;
  SortOption _sortOption = SortOption.dateNewest;
  double _monthlyBudget = 1000.0; // Default monthly budget
  String _currency = 'USD';
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  final List<ExpenseCategory> _customCategories = [];

  ExpenseProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    // Load expenses
    _expenses.addAll(await DatabaseHelper.instance.getAllExpenses());

    // Load custom categories
    _customCategories.addAll(await DatabaseHelper.instance.getAllCategories());

    // Load settings
    _monthlyBudget = double.parse(
      await DatabaseHelper.instance.getSetting('monthly_budget') ?? '1000.0',
    );
    _currency = await DatabaseHelper.instance.getSetting('currency') ?? 'USD';
    _notificationsEnabled = await DatabaseHelper.instance.getSetting('notifications_enabled') == 'true';
    _biometricEnabled = await DatabaseHelper.instance.getSetting('biometric_enabled') == 'true';

    notifyListeners();
  }

  List<Expense> get expenses => _expenses;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  DateTimeRange? get dateRange => _dateRange;
  double? get minAmount => _minAmount;
  double? get maxAmount => _maxAmount;
  SortOption get sortOption => _sortOption;
  double get monthlyBudget => _monthlyBudget;
  String get currency => _currency;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get biometricEnabled => _biometricEnabled;
  List<ExpenseCategory> get customCategories => _customCategories;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    notifyListeners();
  }

  void setAmountRange(double? min, double? max) {
    _minAmount = min;
    _maxAmount = max;
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  Future<void> setMonthlyBudget(double budget) async {
    _monthlyBudget = budget;
    await DatabaseHelper.instance.updateSetting('monthly_budget', budget.toString());
    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    _currency = currency;
    await DatabaseHelper.instance.updateSetting('currency', currency);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await DatabaseHelper.instance.updateSetting('notifications_enabled', enabled.toString());
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    await DatabaseHelper.instance.updateSetting('biometric_enabled', enabled.toString());
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    await DatabaseHelper.instance.insertExpense(expense);
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      await DatabaseHelper.instance.insertExpense(expense);
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((expense) => expense.id == id);
    await DatabaseHelper.instance.deleteExpense(id);
    notifyListeners();
  }

  Future<void> addCustomCategory(ExpenseCategory category) async {
    _customCategories.add(category);
    await DatabaseHelper.instance.insertCategory(category);
    notifyListeners();
  }

  Future<void> deleteCustomCategory(String id) async {
    _customCategories.removeWhere((category) => category.id == id);
    await DatabaseHelper.instance.deleteCategory(id);
    notifyListeners();
  }

  List<Expense> get filteredExpenses {
    return _filterExpenses();
  }

  List<Expense> _filterExpenses() {
    var filtered = List<Expense>.from(_expenses);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((expense) =>
          expense.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((expense) => expense.category == _selectedCategory).toList();
    }

    // Apply date range filter
    if (_dateRange != null) {
      filtered = filtered.where((expense) =>
          expense.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(_dateRange!.end.add(const Duration(days: 1)))).toList();
    }

    // Apply amount range filter
    if (_minAmount != null) {
      filtered = filtered.where((expense) => expense.amount >= _minAmount!).toList();
    }
    if (_maxAmount != null) {
      filtered = filtered.where((expense) => expense.amount <= _maxAmount!).toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case SortOption.dateNewest:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOption.dateOldest:
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortOption.amountHigh:
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortOption.amountLow:
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case SortOption.category:
        filtered.sort((a, b) => a.category.compareTo(b.category));
        break;
    }

    return filtered;
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _dateRange = null;
    _minAmount = null;
    _maxAmount = null;
    notifyListeners();
  }

  double get totalSpentThisMonth {
    final now = DateTime.now();
    return _expenses
        .where((expense) =>
            expense.date.year == now.year && expense.date.month == now.month)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  bool get isOverBudget => totalSpentThisMonth > _monthlyBudget;

  List<Expense> get recentExpenses {
    final sortedExpenses = List<Expense>.from(_expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedExpenses.take(5).toList();
  }

  List<ExpenseCategory> get allCategories {
    return [...ExpenseCategory.defaultCategories, ..._customCategories];
  }
} 