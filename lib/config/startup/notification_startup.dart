import 'package:agenda/config/di/injection.dart';
import 'package:agenda/domain/notifications/local_notification_gateway.dart';
import 'package:agenda/infrastructure/notifications/gateway/timezone_bootstrap.dart';

/// Brings the notification stack up during `main()`.
///
/// Sets the local timezone, then initializes the gateway (channels only, no
/// permission prompt). A notification fault must never block launch, so every
/// failure is swallowed here: both steps already report failures as
/// `NotificationFailure` results, and anything unexpected is caught below.
///
/// Plan 04-12 adds the coordinator start and the app lifecycle observer to
/// this function.
Future<void> startNotifications() async {
  try {
    await bootstrapTimezone();
    await getIt<LocalNotificationGateway>().initialize();
  } on Object {
    // Intentionally ignored: the app works fully without notifications.
  }
}
