import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Failed-PIN bookkeeping and the D-07 attempt ladder (DATA-05).
///
/// Four wrong PINs are counted warnings. Exactly the 5th starts a 30 s
/// cooldown, and each later failure escalates it to 1 min, 5 min, then
/// 15 min (cap). A success, a biometric unlock or a forgot-PIN reset returns
/// the state to [none]. Every method takes the caller's wall-clock `now`.
final class LockAttempts extends Equatable {
  const LockAttempts({
    this.failures = 0,
    this.lockouts = 0,
    this.cooldownUntil,
  });

  /// The reset state: no failures, no lockouts, no cooldown.
  static const LockAttempts none = LockAttempts();

  /// Wrong PINs allowed before the first cooldown starts.
  static const int maxFailuresBeforeCooldown = 5;

  /// Cooldown per lockout; the last step is the cap.
  static const List<Duration> cooldownLadder = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
  ];

  /// Consecutive wrong PINs since the last reset.
  final int failures;

  /// Cooldowns started since the last reset.
  final int lockouts;

  /// When the current cooldown ends, or null when none was started.
  final DateTime? cooldownUntil;

  /// The state after one more wrong PIN entered at [now].
  LockAttempts registerFailure(DateTime now) {
    final nextFailures = failures + 1;
    if (lockouts == 0 && nextFailures < maxFailuresBeforeCooldown) {
      return LockAttempts(
        failures: nextFailures,
        lockouts: lockouts,
        cooldownUntil: cooldownUntil,
      );
    }
    final nextLockouts = lockouts + 1;
    return LockAttempts(
      failures: nextFailures,
      lockouts: nextLockouts,
      cooldownUntil: now.add(_stepFor(nextLockouts)),
    );
  }

  /// Wrong PINs left before the first cooldown; 0 once any cooldown started.
  int get remainingBeforeCooldown =>
      lockouts == 0 ? math.max(0, maxFailuresBeforeCooldown - failures) : 0;

  /// Time left in the cooldown at [now], clamped to the step that started it
  /// so a clock moved back cannot lengthen it. [Duration.zero] when idle.
  Duration cooldownRemaining(DateTime now) {
    final until = cooldownUntil;
    if (until == null || lockouts == 0) return Duration.zero;
    final remaining = until.difference(now);
    if (remaining <= Duration.zero) return Duration.zero;
    final step = _stepFor(lockouts);
    return remaining > step ? step : remaining;
  }

  /// Whether PIN entry is blocked at [now].
  bool isCoolingDown(DateTime now) => cooldownRemaining(now) > Duration.zero;

  static Duration _stepFor(int lockouts) =>
      cooldownLadder[math.min(lockouts - 1, cooldownLadder.length - 1)];

  @override
  List<Object?> get props => [failures, lockouts, cooldownUntil];
}
