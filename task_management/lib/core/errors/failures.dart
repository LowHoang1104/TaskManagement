import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
/// Use [Either<Failure, T>] as return type in use-cases and repositories.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// ─── Network Failures ────────────────────────────────────────────────────────

/// No internet connection.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

/// Server responded with an error (4xx / 5xx).
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure({String message = 'Server error.', this.statusCode})
      : super(message);

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

/// Request timed out.
class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timed out.']);
}

// ─── Auth Failures ───────────────────────────────────────────────────────────

/// User is not authenticated (no token or expired).
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized. Please login again.']);
}

/// User does not have permission to perform this action.
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = 'You do not have permission.']);
}

// ─── Cache / Storage Failures ────────────────────────────────────────────────

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error.']);
}

// ─── Validation Failures ─────────────────────────────────────────────────────

class ValidationFailure extends Failure {
  final Map<String, String> errors;
  const ValidationFailure({required this.errors, String message = 'Validation failed.'})
      : super(message);

  @override
  List<Object> get props => [message, errors];
}

// ─── Generic ─────────────────────────────────────────────────────────────────

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred.']);
}
