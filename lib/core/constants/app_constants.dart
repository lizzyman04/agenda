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

  /// Minutes before a timed task at which its reminder fires (D-01).
  static const int taskReminderLeadMinutes = 30;

  /// Hour (local) of the day-before reminder for debts and bills (D-02).
  static const int dueReminderHour = 9;

  /// Hour (local) of the weekly goal off-track check (D-06).
  static const int goalCheckHour = 9;

  /// Number of days the planner looks ahead when building the schedule.
  static const int plannerHorizonDays = 7;

  /// Most morning-briefing notifications kept in the schedule at once.
  static const int maxBriefingSlots = 7;

  /// Most motivational-quote notifications kept in the schedule at once.
  static const int maxQuoteSlots = 7;

  /// How many days of quotes are pre-scheduled ahead of today (D-07).
  static const int quoteSlotsAhead = 7;

  /// Goal off-track tolerance: ten percentage points of the target
  /// (D-06, D-15).
  static const double goalOffTrackTolerance = 0.10;

  /// Default morning briefing time, 08:00 as minutes of day (D-03).
  static const int defaultBriefingMinutes = 480;

  /// Default motivational quote time, 09:00 as minutes of day.
  static const int defaultQuoteMinutes = 540;

  /// Planner slots on iOS: the 64 pending cap minus 4 spare for alerts.
  static const int iosPlannerSlotBudget = 60;

  /// Planner slots on Android, which has no practical pending cap.
  static const int androidPlannerSlotBudget = 200;

  /// 1-3-5 Rule slot counts — TASK-08.
  static const int rule135BigTasks = 1;
  static const int rule135MediumTasks = 3;
  static const int rule135SmallTasks = 5;
}
