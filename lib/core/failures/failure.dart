/// Domain failure hierarchy.
///
/// All domain and data layer methods that can fail MUST return
/// `Result<T>` (see result.dart) rather than throwing exceptions.
///
/// Pattern matching at call sites is exhaustive because this is a
/// sealed class — adding a new subtype here forces all switch
/// expressions to handle it or the compiler issues an error (D-05).
///
/// Usage:
/// ```dart
/// switch (failure) {
///   case DatabaseFailure(:final message) => handleDb(message);
///   case ValidationFailure(:final message) => handleValidation(message);
///   case NotificationFailure(:final message) => handleNotification(message);
///   case BackupFailure(:final message) => handleBackup(message);
///   case SecurityFailure(:final message) => handleSecurity(message);
/// }
/// ```
sealed class Failure {
  const Failure(this.message);

  /// Human-readable failure description for logging and debug UI.
  ///
  /// Do NOT display raw messages directly to end users — map to
  /// localised strings at the presentation layer.
  final String message;
}

/// Isar read/write or transaction failure.
final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

/// Input validation failure (missing fields, value out of range, etc.).
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// flutter_local_notifications scheduling or permission failure.
final class NotificationFailure extends Failure {
  const NotificationFailure(super.message);
}

/// JSON/CSV export or import failure.
final class BackupFailure extends Failure {
  const BackupFailure(super.message);
}

/// PIN or biometric authentication failure.
final class SecurityFailure extends Failure {
  const SecurityFailure(super.message);
}
