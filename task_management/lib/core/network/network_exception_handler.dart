import 'package:dio/dio.dart';
import '../errors/exceptions.dart';

/// Maps [DioException] to typed [Exception]s.
/// Call this in every data source's catch block.
Exception mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return const TimeoutException();
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        return const UnauthorizedException();
      }
      final message = _extractMessage(e.response?.data) ?? 'Server error.';
      return ServerException(message: message, statusCode: statusCode);
    default:
      return ServerException(
        message: e.message ?? 'An unexpected error occurred.',
      );
  }
}

String? _extractMessage(dynamic data) {
  if (data is Map) {
    return data['message']?.toString() ??
        data['error']?.toString();
  }
  return null;
}
