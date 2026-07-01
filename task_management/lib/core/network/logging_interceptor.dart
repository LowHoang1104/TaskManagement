import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs all HTTP requests and responses in debug mode.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌─── REQUEST ──────────────────────────────────');
      debugPrint('│ ${options.method} ${options.uri}');
      if (options.data != null) {
        debugPrint('│ Body: ${options.data}');
      }
      debugPrint('└──────────────────────────────────────────────');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌─── RESPONSE ─────────────────────────────────');
      debugPrint('│ ${response.statusCode} ${response.requestOptions.uri}');
      debugPrint('│ Data: ${response.data}');
      debugPrint('└──────────────────────────────────────────────');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌─── ERROR ────────────────────────────────────');
      debugPrint('│ ${err.response?.statusCode} ${err.requestOptions.uri}');
      debugPrint('│ ${err.message}');
      debugPrint('└──────────────────────────────────────────────');
    }
    handler.next(err);
  }
}
