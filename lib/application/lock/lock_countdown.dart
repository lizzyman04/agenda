import 'dart:async';

import 'package:agenda/domain/lock/lock_attempts.dart';

/// The D-07 cooldown countdown of the lock screen.
///
/// A cooldown is read, never remembered: the time left is recomputed from
/// the persisted [LockAttempts] on every tick, so restarting the app cannot
/// shorten the wait (T-05-26).
class LockCountdown {
  LockCountdown(this._clock);

  final DateTime Function() _clock;
  Timer? _timer;

  /// Calls [onTick] with the time left now and then every second. The last
  /// call gets [Duration.zero], after which the countdown stops by itself.
  void start(LockAttempts attempts, void Function(Duration left) onTick) {
    cancel();
    bool tick() {
      final left = attempts.cooldownRemaining(_clock());
      if (left > Duration.zero) {
        onTick(left);
        return true;
      }
      cancel();
      onTick(Duration.zero);
      return false;
    }

    if (tick()) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
  }

  /// Stops the countdown; no further ticks.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
