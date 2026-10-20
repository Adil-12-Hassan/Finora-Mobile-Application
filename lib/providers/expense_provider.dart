import 'package:flutter/foundation.dart';

import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../core/utils/date_formatter.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  List<ExpenseModel> _expenses = [];
  bool _loading = false;
  String? _error = null;
  int _page = 1;
  int _totalPages = 1;
  String _month = DateFormatter.toMonthKey(DateTime.now());
  String? _category;

  List<ExpenseModel> get expenses => _expenses;
  bool get loading => _loading;
  String? get error => _error;
  int get page => _page;
  int get totalPages => _totalPages;
  String get month => _month;
  String? get category => _category;
  bool get hasMore => _page < _totalPages;

  // Initial load / refresh
  Future<void> fetchExpenses({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _expenses = [];
    }
    _setLoading(true);
    try {
      final result = await _expenseService.getExpenses(
        page: _page,
        month: _month,
        category: _category,
      );
      final fetched = result['expenses'] as List<ExpenseModel>;
      _expenses = refresh ? fetched : [..._expenses, ...fetched];
      _totalPages = result['totalPages'];
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Load next page
  Future<void> loadMore() async {
    if (!hasMore || _loading) return;
    _page++;
    await fetchExpenses();
  }

  // Add expense
  Future<bool> addExpense({
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    _setLoading(true);
    try {
      final newExpense = await _expenseService.addExpense(
        amount: amount,
        category: category,
        date: date,
        note: note,
      );
      // Prepend to list so it shows at top
      _expenses = [newExpense, ..._expenses];
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update expense
  Future<bool> updateExpense({
    required String id,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
  }) async {
    _setLoading(true);
    try {
      final updated = await _expenseService.updateExpense(
        id: id,
        amount: amount,
        category: category,
        date: date,
        note: note,
      );
      // Replace in list
      _expenses = _expenses.map((e) => e.id == id ? updated : e).toList();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete expense
  Future<bool> deleteExpense(String id) async {
    _setLoading(true);
    try {
      await _expenseService.deleteExpense(id);
      _expenses = _expenses.where((e) => e.id != id).toList();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Filter by month
  void setMonth(String month) {
    _month = month;
    fetchExpenses(refresh: true);
  }

  // Filter by category
  void setCategory(String? category) {
    _category = category;
    fetchExpenses(refresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }
}
