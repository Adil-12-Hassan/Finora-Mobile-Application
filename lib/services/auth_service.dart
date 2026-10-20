import 'package:dio/dio.dart';

import '../core/constants/api.constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final Dio _dio = ApiService().dio;

  Future<UserModel> getMe() async {
    try {
      final res = await _dio.get(ApiConstants.me);
      final data = res.data['user'] ?? res.data;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = res.data['user'] ?? res.data;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      final data = res.data['user'] ?? res.data;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
      await ApiService().clearCookies();
    } on DioException catch (e) {
      await ApiService().clearCookies();
      throw _handleError(e);
    }
  }

  Future<UserModel> updateProfile({
    String? name,
    String? currency,
    double? monthlyBudget,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name;
      if (currency != null) payload['currency'] = currency;
      if (monthlyBudget != null) payload['monthlyBudget'] = monthlyBudget;

      final res = await _dio.put(ApiConstants.updateProfile, data: payload);
      final data = res.data['user'] ?? res.data;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        ApiConstants.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        return data['message'] ?? data['error'] ?? 'Something went wrong';
      }
      if (data is String && data.isNotEmpty) {
        return data;
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to the server.';
      case DioExceptionType.badResponse:
        return 'Server error. Please try again.';
      default:
        return 'Something went wrong';
    }
  }
}
