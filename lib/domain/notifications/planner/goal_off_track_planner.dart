import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/planner/kind_planner.dart';
import 'package:agenda/domain/notifications/planning/goal_alert_keys.dart';
import 'package:agenda/domain/notifications/planning/goal_off_track.dart';
import 'package:agenda/domain/notifications/rules/day_math.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';

/// Plans at most one weekly off-track alert per goal (NOTF-06, D-06).
///
/// The candidate is the next Monday at the goal check hour. A fired marker
/// for that week (an immediate alert was already shown) moves it to the
/// following Monday, at most twice. The goal is judged as of the fire time,
/// so a goal that will be on track by then produces nothing. Completed,
/// deleted and undated goals, and goals with a non-positive target, are
/// skipped. Carries only the title (T-04-07-01).
final class GoalOffTrackPlanner implements KindPlanner {
  const GoalOffTrackPlanner();

  @override
  List<PlannedNotification> plan(PlannerInput input) {
    const kind = NotificationKind.goalOffTrack;
    final planned = <PlannedNotification>[];
    for (final progress in input.goals) {
      final goal = progress.goal;
      if (goal.isCompleted ||
          goal.deletedAt != null ||
          goal.deadline == null ||
          goal.targetAmountCents <= 0 ||
          goal.id < 0 ||
          goal.id > maxNotificationEntityId) {
        continue;
      }
      var fireAt = nextWeekdayAt(
        input.now,
        weekday: DateTime.monday,
        minutes: AppConstants.goalCheckHour * 60,
      );
      for (var i = 0; i < 2; i++) {
        if (input.firedAlertKeys.contains(
          goalFiredKey(goal.id, weekKey(fireAt)),
        )) {
          fireAt = addDays(fireAt, 7);
        }
      }
      final offTrack = isGoalOffTrack(
        savedCents: progress.savedCents,
        targetCents: goal.targetAmountCents,
        createdAt: goal.createdAt,
        deadline: goal.deadline,
        asOf: fireAt,
      );
      if (!offTrack) continue;
      planned.add(
        PlannedNotification(
          kind: kind,
          id: notificationId(
            base: kind.idBase,
            entityId: goal.id,
            type: kind.idType,
          ),
          fireAt: fireAt,
          entityId: goal.id,
          subject: goal.title,
        ),
      );
    }
    return planned;
  }
}
