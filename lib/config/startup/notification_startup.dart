import 'dart:async';

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
/// the background while the first frame is drawn. Plan 04-14 appends the
/// on-open evaluator hooks to the resume hook list below.
Future<void> startNotifications() async {
  try {
    await bootstrapTimezone();
    await getIt<LocalNotificationGateway>().initialize();
    final reconciler = getIt<NotificationReconciler>();
    unawaited(reconciler.start().onError<Object>((_, _) {}));
    WidgetsBinding.instance.addObserver(
      NotificationLifecycleObserver([
        () => reconciler.requestReconcile(ReconcileReason.appResume),
      ]),
    );
  } on Object {
    // Intentionally ignored: the app works fully without notifications.
  }
}
