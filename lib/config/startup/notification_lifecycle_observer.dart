import 'dart:async';

import 'package:agenda/infrastructure/notifications/gateway/timezone_bootstrap.dart';
import 'package:flutter/widgets.dart';

/// Reacts to the app returning to the foreground.
///
/// The user can change time zone or clock while the app is in the
/// background, so on resume the timezone is refreshed first and then every
/// registered hook runs. Hooks are plain callbacks: the reconcile request
/// is the first one, and the on-open evaluators of plan 04-14 append more.
final class NotificationLifecycleObserver with WidgetsBindingObserver {
  NotificationLifecycleObserver(this._resumeHooks);

  final List<void Function()> _resumeHooks;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(bootstrapTimezone());
    for (final hook in _resumeHooks) {
      try {
        hook();
      } on Object {
        // One failing hook must not stop the others.
      }
    }
  }
}
