import 'package:dio/dio.dart';

import '../core/constants/api.constants.dart';
import '../models/dashboard_model.dart';
import 'api_service.dart';

class DashboardService {
  final Dio _dio = ApiService().dio;

  Future<DashboardModel> getDashboard({String? month}) async {
    try {
      final res = await _dio.get(
        ApiConstants.dashboard,
        queryParameters: {if (month != null) 'month': month},
      );
      return DashboardModel.fromJson(res.data);
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
