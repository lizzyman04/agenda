import 'package:agenda/domain/notifications/planner/briefing_planner.dart';
import 'package:agenda/domain/notifications/planner/debt_reminder_planner.dart';
import 'package:agenda/domain/notifications/planner/goal_off_track_planner.dart';
import 'package:agenda/domain/notifications/planner/payment_reminder_planner.dart';
import 'package:agenda/domain/notifications/planner/quote_planner.dart';
import 'package:agenda/domain/notifications/planner/reminder_planner.dart';
import 'package:agenda/domain/notifications/planner/task_reminder_planner.dart';
import 'package:injectable/injectable.dart';

/// DI registrations for the notification domain.
///
/// The planners are pure Dart values, so the composition lives here and not
/// in the domain layer. The infrastructure classes (gateway, loader, runner,
/// coordinator) self-register through their own annotations.
@module
abstract class NotificationsModule {
  /// The six kind planners composed into one schedule planner.
  @lazySingleton
  ReminderPlanner get reminderPlanner => const ReminderPlanner([
    TaskReminderPlanner(),
    BriefingPlanner(),
    DebtReminderPlanner(),
    PaymentReminderPlanner(),
    GoalOffTrackPlanner(),
    QuotePlanner(),
  ]);
}
