import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';

/// Singleton Dio instance with all interceptors configured.
/// Inject this via get_it.
class DioClient {
  late final Dio _dio;

  DioClient({required AuthInterceptor authInterceptor}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: kBaseUrl,
        connectTimeout: const Duration(seconds: kConnectTimeout),
        receiveTimeout: const Duration(seconds: kReceiveTimeout),
        sendTimeout: const Duration(seconds: kSendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      authInterceptor,
      LoggingInterceptor(),
    ]);
  }

  Dio get dio => _dio;
}
