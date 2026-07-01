import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Extension methods on [Either] for cleaner code in use-cases and ViewModels.
extension EitherExtensions<L extends Failure, R> on Either<L, R> {
  /// Returns the right value or null.
  R? getOrNull() => fold((_) => null, (r) => r);

  /// Returns the left (Failure) or null.
  L? getFailureOrNull() => fold((l) => l, (_) => null);

  /// Returns true if this is a Right (success).
  bool get isSuccess => isRight();

  /// Returns true if this is a Left (failure).
  bool get isFailure => isLeft();

  /// Run a side-effect on success without transforming.
  Either<L, R> onSuccess(void Function(R value) action) {
    if (isRight()) {
      action(getOrElse(() => throw StateError('Expected Right')));
    }
    return this;
  }

  /// Run a side-effect on failure without transforming.
  Either<L, R> onFailure(void Function(L failure) action) {
    if (isLeft()) {
      fold(action, (_) {});
    }
    return this;
  }
}
