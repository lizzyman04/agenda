/// Project-wide magic numbers and limits.
///
/// Prevents literal duplication across layers. All values are Dart constants.
abstract final class AppConstants {
  /// Duration of the undo snackbar for soft-deleted tasks (TASK-05).
  static const Duration undoSnackbarDuration = Duration(seconds: 5);

  /// Maximum number of iOS scheduled notifications (platform limit).
  /// Phase 4 notification manager must not exceed this.
  static const int iosMaxScheduledNotifications = 64;

  /// Budget alert threshold (80 %) — triggers NOTF-03 first alert.
  static const double budgetAlertThresholdLow = 0.80;

  /// Budget alert threshold (100 %) — triggers NOTF-03 second alert.
  // ignore: prefer_int_literals
  static const double budgetAlertThresholdHigh = 1.00;

  /// Default quiet hours start (22:00) — NOTF-10.
  static const int quietHoursStartHour = 22;

  /// Default quiet hours end (07:00) — NOTF-10.
  static const int quietHoursEndHour = 7;

  /// 1-3-5 Rule slot counts — TASK-08.
  static const int rule135BigTasks = 1;
  static const int rule135MediumTasks = 3;
  static const int rule135SmallTasks = 5;
}
