import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runs [_action] after a quiet period and never twice at once.
///
/// A burst of [request] calls collapses into one run. A request that
/// arrives while a run is in progress queues exactly one more run behind it
/// (T-04-14-04). Errors are logged by type only and never escape.
class DebouncedSingleFlight {
  DebouncedSingleFlight(this._action, this._delay);

  final Future<void> Function() _action;
  final Duration Function() _delay;

  Timer? _timer;
  bool _running = false;
  bool _again = false;
  bool _disposed = false;

  /// Schedules a run once the burst settles.
  void request() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(_delay(), () => unawaited(_run()));
  }

  Future<void> _run() async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        await _action();
      } while (_again && !_disposed);
    } on Object catch (error) {
      debugPrint('Notification evaluation failed (${error.runtimeType})');
    } finally {
      _running = false;
    }
  }

  /// Cancels the pending run. Safe to call more than once.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }
}
