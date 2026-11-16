import 'dart:async';

import 'package:agenda/domain/lock/lock_attempts.dart';

/// The D-07 cooldown countdown, shared by the lock screen and the
/// current-PIN step of the PIN setup screen.
///
/// A cooldown is read, never remembered: the time left is recomputed from
/// the persisted [LockAttempts] on every tick, so restarting the app cannot
/// shorten the wait (T-05-26).
class CooldownTicker {
  CooldownTicker({required DateTime Function() clock}) : _clock = clock;

  final DateTime Function() _clock;
  Timer? _timer;

  /// Calls [onTick] with the time left now and then every second while it
  /// is above zero; then calls [onDone] once and stops by itself.
  void start(
    LockAttempts attempts, {
    required void Function(Duration remaining) onTick,
    required void Function() onDone,
  }) {
    cancel();
    bool tick() {
      final left = attempts.cooldownRemaining(_clock());
      if (left > Duration.zero) {
        onTick(left);
        return true;
      }
      cancel();
      onDone();
      return false;
    }

    if (tick()) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
  }

  /// Stops the countdown; no further ticks. Safe to call any number of
  /// times.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
