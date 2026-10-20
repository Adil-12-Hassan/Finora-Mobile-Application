import 'package:dio/dio.dart';

import '../core/constants/api.constants.dart';
import '../models/budget_model.dart';
import 'api_service.dart';

class BudgetService {
  final Dio _dio = ApiService().dio;

  // Get budgets for a month
  Future<List<BudgetModel>> getBudgets({String? month}) async {
    try {
      final res = await _dio.get(
        ApiConstants.budgets,
        queryParameters: {if (month != null) 'month': month},
      );
      return (res.data['budgets'] as List)
          .map((b) => BudgetModel.fromJson(b))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Set or update budget for a category
  Future<BudgetModel> setBudget({
    required String category,
    required double limit,
    required String month,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.budgets,
        data: {'category': category, 'limit': limit, 'month': month},
      );
      return BudgetModel.fromJson(res.data['budget']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Delete budget
  Future<void> deleteBudget(String id) async {
    try {
      await _dio.delete('${ApiConstants.budgets}/$id');
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
