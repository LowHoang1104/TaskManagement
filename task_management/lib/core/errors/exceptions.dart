/// Thrown when the remote API returns an error.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Thrown when there is no internet connection.
class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection.']);

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when a request times out.
class TimeoutException implements Exception {
  final String message;
  const TimeoutException([this.message = 'Request timed out.']);

  @override
  String toString() => 'TimeoutException: $message';
}

/// Thrown when the user is not authenticated.
class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'Unauthorized.']);

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Thrown when reading/writing from local cache fails.
class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error.']);

  @override
  String toString() => 'CacheException: $message';
}
