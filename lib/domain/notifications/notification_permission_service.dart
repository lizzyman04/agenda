/// Whether the user allowed the app to post notifications.
enum NotificationPermission { granted, denied }

/// Notification and exact-alarm permissions (Android 13+ and 14+, iOS).
///
/// Implementations live in `lib/infrastructure/notifications/gateway/`.
/// Every method resolves to a safe default instead of throwing. Prompts are
/// raised in context by the caller, never during initialization.
abstract interface class NotificationPermissionService {
  /// The current state, without prompting.
  Future<NotificationPermission> notificationPermission();

  /// Prompts the user when the platform allows it and returns the result.
  Future<NotificationPermission> requestNotificationPermission();

  /// Whether exact alarms may be scheduled. True where the platform has no
  /// such restriction.
  Future<bool> canScheduleExact();

  /// Opens the system screen where the user grants exact alarms (Android
  /// 12+). A no-op elsewhere.
  Future<void> requestExactAlarmPermission();

  /// Opens the operating system's notification settings page for this app.
  /// True when the page was launched, false when the platform cannot. Never
  /// throws.
  Future<bool> openNotificationSettings();
}
