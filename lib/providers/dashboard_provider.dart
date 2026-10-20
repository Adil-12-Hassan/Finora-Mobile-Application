import 'package:flutter/foundation.dart';

import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';
import '../core/utils/date_formatter.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();

  DashboardModel? _dashboard;
  bool _loading = false;
  String? _error;
  String _month = DateFormatter.toMonthKey(DateTime.now());

  DashboardModel? get dashboard => _dashboard;
  bool get loading => _loading;
  String? get error => _error;
  String get month => _month;

  Future<void> fetchDashboard({String? month}) async {
    _setLoading(true);
    try {
      _dashboard = await _dashboardService.getDashboard(month: month ?? _month);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void setMonth(String month) {
    _month = month;
    fetchDashboard(month: month);
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
