import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _error;
  bool _loading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get loading => _loading;
  bool get isAuth => _status == AuthStatus.authenticated;

  // Called on app start - checks if session cookie is still valid
  Future<void> checkAuth() async {
    try {
      _user = await _authService.getMe();
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      _user = await _authService.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      _user = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
    } finally {
      _user = null;
      _status = AuthStatus.unauthenticated;
      _error = null;
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? currency,
    double? monthlyBudget,
  }) async {
    _setLoading(true);
    try {
      _user = await _authService.updateProfile(
        name: name,
        currency: currency,
        monthlyBudget: monthlyBudget,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
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
