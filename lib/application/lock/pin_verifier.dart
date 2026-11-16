import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:agenda/domain/lock/pin_hasher.dart';
import 'package:agenda/domain/lock/pin_store.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

/// The answer to one PIN attempt.
sealed class PinVerifyOutcome extends Equatable {
  const PinVerifyOutcome();

  @override
  List<Object?> get props => [];
}

/// The PIN matched; the attempt state was reset.
final class PinVerified extends PinVerifyOutcome {
  const PinVerified();
}

/// Wrong PIN; [remaining] more wrong PINs before the first cooldown.
final class PinRejected extends PinVerifyOutcome {
  const PinRejected(this.remaining);

  final int remaining;

  @override
  List<Object?> get props => [remaining];
}

/// PIN entry is blocked until [attempts]' cooldown ends.
final class PinCoolingDown extends PinVerifyOutcome {
  const PinCoolingDown(this.attempts);

  final LockAttempts attempts;

  @override
  List<Object?> get props => [attempts];
}

/// The attempt could not be checked (bad input, missing or malformed
/// record, storage fault). Never an unlock: the lock fails closed.
final class PinCheckFailed extends PinVerifyOutcome {
  const PinCheckFailed();
}

/// Checks PIN attempts against the stored record and the D-07 ladder.
///
/// Every answer comes from persisted state, so killing the app cannot reset
/// the counter: a counted failure is written to secure storage BEFORE the
/// result is returned (T-05-09). Any storage fault or missing record yields
/// [PinCheckFailed], never [PinVerified] (T-05-12). No PIN material is ever
/// logged.
@lazySingleton
class PinVerifier {
  PinVerifier(this._store, this._hasher);

  final PinStore _store;
  final PinHasher _hasher;

  /// The persisted attempt state.
  AsyncResult<LockAttempts> loadAttempts() => _store.readAttempts();

  /// Checks [pin] at wall-clock [now].
  Future<PinVerifyOutcome> verify(String pin, DateTime now) async {
    if (!isValidPin(pin)) return const PinCheckFailed();

    final LockAttempts attempts;
    switch (await _store.readAttempts()) {
      case Success(:final value):
        attempts = value;
      case Err():
        return const PinCheckFailed();
    }
    if (attempts.isCoolingDown(now)) return PinCoolingDown(attempts);

    final record = switch (await _store.readRecord()) {
      Success(:final value) => value,
      Err() => null,
    };
    if (record == null) return const PinCheckFailed();

    if (await _hasher.verify(pin, record)) {
      // The PIN was proven; a failed reset write does not undo that.
      await _store.writeAttempts(LockAttempts.none);
      return const PinVerified();
    }

    final next = attempts.registerFailure(now);
    if (await _store.writeAttempts(next) is Err) {
      return const PinCheckFailed();
    }
    if (next.isCoolingDown(now)) return PinCoolingDown(next);
    return PinRejected(next.remainingBeforeCooldown);
  }

  /// Clears failures, lockouts and cooldown (biometric or forgot-PIN
  /// success). Best effort.
  Future<void> resetAttempts() async {
    await _store.writeAttempts(LockAttempts.none);
  }
}
