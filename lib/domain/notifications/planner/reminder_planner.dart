import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/planner/kind_planner.dart';
import 'package:agenda/domain/notifications/rules/quiet_hours.dart';
import 'package:agenda/domain/notifications/rules/slot_budget.dart';

/// The planned schedule and how many reminders were left out of it.
final class PlanResult {
  const PlanResult({required this.planned, required this.truncated});

  final List<PlannedNotification> planned;
  final int truncated;
}

/// Composes any list of [KindPlanner]s into one schedule.
///
/// Order of operations is fixed:
/// 1. concatenate every planner's output;
/// 2. drop kinds that are not enabled in the prefs;
/// 3. drop entries not strictly after `now`;
/// 4. when quiet hours are on, defer every entry out of the window (D-08,
///    all kinds, briefing included);
/// 5. de-duplicate by id, keeping the earliest fire time;
/// 6. fit the result into the slot budget.
///
/// Budget alerts never pass through this planner: the evaluator raises them.
final class ReminderPlanner {
  const ReminderPlanner(this.planners);

  final List<KindPlanner> planners;

  PlanResult plan(PlannerInput input) {
    final prefs = input.prefs;
    final byId = <int, PlannedNotification>{};
    for (final planner in planners) {
      for (final entry in planner.plan(input)) {
        if (!prefs.isEnabled(entry.kind)) continue;
        if (!entry.fireAt.isAfter(input.now)) continue;
        final fireAt = prefs.quietHoursEnabled
            ? deferOutOfQuietHours(
                entry.fireAt,
                startMinutes: prefs.quietStartMinutes,
                endMinutes: prefs.quietEndMinutes,
              )
            : entry.fireAt;
        final deferred = entry.copyWith(fireAt: fireAt);
        final existing = byId[deferred.id];
        if (existing == null || deferred.fireAt.isBefore(existing.fireAt)) {
          byId[deferred.id] = deferred;
        }
      }
    }
    final selection = selectWithinBudget(
      byId.values.toList(),
      budget: input.slotBudget,
    );
    return PlanResult(
      planned: selection.kept,
      truncated: selection.truncated,
    );
  }
}
