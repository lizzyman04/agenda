import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:agenda/domain/lock/pin_record.dart';

/// Platform secure storage for the PIN record and the attempt state (D-05,
/// D-07).
///
/// Implementations live in `lib/infrastructure/lock/`. Every method returns
/// `Err(SecurityFailure)` instead of throwing, and no failure message ever
/// carries PIN material.
abstract interface class PinStore {
  /// The stored record, or null when absent or malformed.
  AsyncResult<PinRecord?> readRecord();

  /// Replaces the stored record.
  AsyncResult<void> writeRecord(PinRecord record);

  /// The persisted attempt state; [LockAttempts.none] when absent.
  AsyncResult<LockAttempts> readAttempts();

  /// Replaces the persisted attempt state.
  AsyncResult<void> writeAttempts(LockAttempts attempts);

  /// Deletes the record and the attempt state.
  AsyncResult<void> clear();
}
