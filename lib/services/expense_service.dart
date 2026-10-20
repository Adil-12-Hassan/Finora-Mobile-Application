import 'package:dio/dio.dart';

import '../core/constants/api.constants.dart';
import '../models/expense_model.dart';
import 'api_service.dart';

class ExpenseService {
  final Dio _dio = ApiService().dio;

  // Get paginated expenses
  Future<Map<String, dynamic>> getExpenses({
    int page = 1,
    int limit = 20,
    String? month, // "2026-10"
    String? category,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.expenses,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (month != null) 'month': month,
          if (category != null) 'category': category,
        },
      );
      final expenses = (res.data['expenses'] as List)
          .map((e) => ExpenseModel.fromJson(e))
          .toList();
      return {
        'expenses': expenses,
        'total': res.data['total'] ?? 0,
        'totalPages': res.data['totalPages'] ?? 1,
        'page': res.data['page'] ?? 1,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Add expense
  Future<ExpenseModel> addExpense({
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.expenses,
        data: {
          'amount': amount,
          'category': category,
          'date': date.toIso8601String(),
          if (note != null) 'note': note,
        },
      );
      return ExpenseModel.fromJson(res.data['expense']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Edit expense
  Future<ExpenseModel> updateExpense({
    required String id,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
  }) async {
    try {
      final res = await _dio.put(
        '${ApiConstants.expenses}/$id',
        data: {
          if (amount != null) 'amount': amount,
          if (category != null) 'category': category,
          if (date != null) 'date': date.toIso8601String(),
          if (note != null) 'note': note,
        },
      );
      return ExpenseModel.fromJson(res.data['expense']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Delete expense
  Future<void> deleteExpense(String id) async {
    try {
      await _dio.delete('${ApiConstants.expenses}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response?.data != null) {
      return e.response?.data['message'] ?? 'Something went wrong';
    }
    if (e.type == DioExceptionType.connectionTimeout)
      return 'Connection timeout.';
    if (e.type == DioExceptionType.connectionError)
      return 'Cannot connect to server.';
    return 'Something went wrong';
  }
}
