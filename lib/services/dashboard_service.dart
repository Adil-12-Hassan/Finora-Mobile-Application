import 'package:dio/dio.dart';

import '../core/constants/api.constants.dart';
import '../models/dashboard_model.dart';
import 'api_service.dart';

class DashboardService {
  final Dio _dio = ApiService().dio;

  Future<DashboardModel> getDashboard({String? month}) async {
    try {
      final queryParameters = {if (month != null) 'month': month};
      final responses = await Future.wait([
        _dio.get(
          ApiConstants.dashboard,
          queryParameters: queryParameters,
        ),
        _dio.get(
          ApiConstants.reports,
          queryParameters: queryParameters,
        ),
      ]);
      final dashboardData = Map<String, dynamic>.from(responses[0].data);
      final reportsData = Map<String, dynamic>.from(responses[1].data);
      dashboardData['charts'] = reportsData['charts'];
      dashboardData['month'] ??= reportsData['month'];

      return DashboardModel.fromJson(dashboardData);
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
