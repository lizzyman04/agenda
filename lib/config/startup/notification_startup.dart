import 'dart:async';

import 'package:agenda/application/notifications/budget_alert_evaluator.dart';
import 'package:agenda/application/notifications/goal_alert_evaluator.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/config/startup/notification_lifecycle_observer.dart';
import 'package:agenda/domain/notifications/local_notification_gateway.dart';
import 'package:agenda/domain/notifications/notification_reconciler.dart';
import 'package:agenda/infrastructure/notifications/gateway/timezone_bootstrap.dart';
import 'package:flutter/widgets.dart';

/// Brings the notification stack up during `main()`.
///
/// Sets the local timezone, initializes the gateway (channels only, no
/// permission prompt), starts the schedule coordinator and registers the
/// lifecycle observer. A notification fault must never block launch, so
/// every failure is swallowed here: the steps already report failures as
/// `NotificationFailure` results, and anything unexpected is caught below.
///
/// The coordinator start is fire and forget: the first reconcile runs in
/// the background while the first frame is drawn. The budget evaluator starts
/// listening for changes, and the goal evaluator runs once now and again each
/// time the app returns to the foreground. Each of those calls is isolated,
/// so one failing alert cannot stop the others.
Future<void> startNotifications() async {
  try {
    await bootstrapTimezone();
    await getIt<LocalNotificationGateway>().initialize();
    final reconciler = getIt<NotificationReconciler>();
    unawaited(reconciler.start().onError<Object>((_, _) {}));
    _fireAndForget(() => getIt<BudgetAlertEvaluator>().start());
    _fireAndForget(() => getIt<GoalAlertEvaluator>().evaluateOnOpen());
    WidgetsBinding.instance.addObserver(
      NotificationLifecycleObserver([
        () => reconciler.requestReconcile(ReconcileReason.appResume),
        () =>
            _fireAndForget(() => getIt<GoalAlertEvaluator>().evaluateOnOpen()),
      ]),
    );
  } on Object {
    // Intentionally ignored: the app works fully without notifications.
  }
}

/// Runs [action] without awaiting it and swallows any failure, including
/// one thrown before the first await (an unregistered dependency).
void _fireAndForget(Future<void> Function() action) {
  try {
    unawaited(action().onError<Object>((_, _) {}));
  } on Object {
    // Alerts are optional: the app works fully without them.
  }
}
