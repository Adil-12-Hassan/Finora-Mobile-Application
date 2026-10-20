import 'package:flutter/foundation.dart';

import '../models/budget_model.dart';
import '../services/budget_service.dart';
import '../core/utils/date_formatter.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _budgetService = BudgetService();

  List<BudgetModel> _budgets = [];
  bool _loading = false;
  String? _error;
  String _month = DateFormatter.toMonthKey(DateTime.now());

  List<BudgetModel> get budgets => _budgets;
  bool get loading => _loading;
  String? get error => _error;
  String get month => _month;

  Future<void> fetchBudgets({String? month}) async {
    _setLoading(true);
    try {
      _budgets = await _budgetService.getBudgets(month: month ?? _month);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> setBudget({
    required String category,
    required double limit,
  }) async {
    _setLoading(true);
    try {
      final budget = await _budgetService.setBudget(
        category: category,
        limit: limit,
        month: _month,
      );
      // Update existing or add new
      final index = _budgets.indexWhere((b) => b.category == category);
      if (index != -1) {
        _budgets[index] = budget;
      } else {
        _budgets = [..._budgets, budget];
      }
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteBudget(String id) async {
    _setLoading(true);
    try {
      await _budgetService.deleteBudget(id);
      _budgets = _budgets.where((b) => b.id != id).toList();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void setMonth(String month) {
    _month = month;
    fetchBudgets(month: month);
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
