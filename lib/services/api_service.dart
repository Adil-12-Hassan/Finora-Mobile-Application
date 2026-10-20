import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/api.constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;
  late final CookieJar cookieJar;

  ApiService._internal() {
    cookieJar = CookieJar();

    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiConstants.receiveTimeout,
        ),
        contentType: 'application/json',
        responseType: ResponseType.json,
        extra: {if (kIsWeb) 'withCredentials': true},
      ),
    );

    // Cookie manager - handles httpOnly JWT cookie automatically
    if (!kIsWeb) {
      dio.interceptors.add(CookieManager(cookieJar));
    }

    // Logging in debug mode only
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );
    }

    // Global error interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          debugPrint('API Error: ${e.response?.statusCode} - ${e.message}');
          handler.next(e);
        },
      ),
    );
  }

  // Clear cookies on logout
  Future<void> clearCookies() async {
    await cookieJar.deleteAll();
  }
}
