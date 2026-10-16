import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/planner/kind_planner.dart';
import 'package:agenda/domain/notifications/planning/task_fire_time.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';

/// Plans one reminder per due task and per recurring task (NOTF-01,
/// NOTF-02, NOTF-04).
///
/// D-04 is satisfied structurally: the repository materialises only the next
/// occurrence of a recurring item, so exactly one open row per series
/// exists and this planner never expands a recurrence itself. Recurring
/// items use their own kind so the user can switch them off separately.
///
/// Completed, soft-deleted, project and undated items produce nothing, and
/// so does an item whose id cannot fit the notification id scheme.
final class TaskReminderPlanner implements KindPlanner {
  const TaskReminderPlanner();

  @override
  List<PlannedNotification> plan(PlannerInput input) {
    final planned = <PlannedNotification>[];
    for (final item in input.items) {
      if (!_isEligible(item)) continue;
      final fireAt = taskFireAt(
        item,
        briefingMinutes: input.prefs.briefingMinutes,
        now: input.now,
      );
      if (fireAt == null) continue;
      final kind =
          _isRecurring(item)
              ? NotificationKind.recurringTaskReminder
              : NotificationKind.taskReminder;
      final dueMinutes = item.dueTimeMinutes;
      planned.add(
        PlannedNotification(
          kind: kind,
          id: notificationId(
            base: kind.idBase,
            entityId: item.id,
            type: kind.idType,
          ),
          fireAt: fireAt,
          entityId: item.id,
          subject: item.title,
          variant: dueMinutes == null ? 1 : 0,
          extras: dueMinutes == null ? const [] : [formatHhmm(dueMinutes)],
        ),
      );
    }
    return planned;
  }

  static bool _isEligible(Item item) =>
      item.type != ItemType.project &&
      !item.isCompleted &&
      item.deletedAt == null &&
      item.dueDate != null &&
      item.id >= 0 &&
      item.id <= maxNotificationEntityId;

  static bool _isRecurring(Item item) {
    final rule = item.recurrenceRule;
    return rule != null && rule.isNotEmpty;
  }
}
