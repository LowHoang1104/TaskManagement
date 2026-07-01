import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

/// Automatically attaches Bearer token to every request.
/// On 401 response, attempts to refresh the token once.
class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;
  final Dio _dio; // same Dio instance for token refresh

  AuthInterceptor({
    required SecureStorage secureStorage,
    required Dio dio,
  })  : _secureStorage = secureStorage,
        _dio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      try {
        final refreshToken = await _secureStorage.getRefreshToken();
        if (refreshToken == null) {
          return handler.next(err);
        }

        final response = await _dio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken = response.data['accessToken'] as String;
        await _secureStorage.saveAccessToken(newAccessToken);

        // Retry original request with new token
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(options);
        return handler.resolve(retryResponse);
      } catch (_) {
        // Refresh failed → clear tokens, force re-login
        await _secureStorage.clearTokens();
        return handler.next(err);
      }
    }
    handler.next(err);
  }
}
