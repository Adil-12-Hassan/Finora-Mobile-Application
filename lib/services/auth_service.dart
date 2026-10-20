import 'package:dio/dio.dart';
import '../core/constants/api.constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final Dio _dio = ApiService().dio;

  // Register
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.register,
        data: {
          'name':     name,
          'email':    email,
          'password': password,
        },
      );
      return UserModel.fromJson(res.data['user']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Login
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.login,
        data: {
          'email':    email,
          'password': password,
        },
      );
      return UserModel.fromJson(res.data['user']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get current user - used to check if session is still valid
  Future<UserModel> getMe() async {
    try {
      final res = await _dio.get(ApiConstants.me);
      return UserModel.fromJson(res.data['user']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
      await ApiService().clearCookies();
    } on DioException catch (e) {
      // Clear cookies regardless
      await ApiService().clearCookies();
      throw _handleError(e);
    }
  }

  // Update profile
  Future<UserModel> updateProfile({
    String? name,
    String? currency,
    double? monthlyBudget,
  }) async {
    try {
      final res = await _dio.put(
        ApiConstants.updateProfile,
        data: {
          if (name != null)          'name': name,
          if (currency != null)      'currency': currency,
          if (monthlyBudget != null) 'monthlyBudget': monthlyBudget,
        },
      );
      return UserModel.fromJson(res.data['user']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.put(
        ApiConstants.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword':     newPassword,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handler - extracts backend message
  String _handleError(DioException e) {
    if (e.response?.data != null) {
      return e.response?.data['message'] ?? 'Something went wrong';
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Check your internet.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server.';
    }
    return 'Something went wrong';
  }
}