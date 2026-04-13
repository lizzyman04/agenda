import 'package:agenda/core/failures/failure.dart';

/// Represents a successful computation holding a value of type [T].
final class Success<T> {
  const Success(this.value);

  /// The successful result value.
  final T value;
}

/// Represents a failed computation holding a [Failure].
final class Err<T> {
  const Err(this.failure);

  /// The failure that caused the operation to fail.
  final Failure failure;
}

/// The standard return type for fallible domain and data operations.
///
/// A method returning `Result<T>` either:
/// - Returns `Success(value)` on success
/// - Returns `Err(failure)` on failure — never throws
///
/// Pattern match at call sites:
/// ```dart
/// final result = await repository.getTask(id);
/// switch (result) {
///   case Success(:final value) => render(value);
///   case Err(:final failure) => handleFailure(failure);
/// }
/// ```
typedef Result<T> = Object; // Success<T> | Err<T>

/// The standard return type for async fallible domain and data operations.
///
/// All repository interface methods use `AsyncResult<T>` as their
/// return type signature.
typedef AsyncResult<T> = Future<Object>; // Future<Success<T> | Err<T>>
