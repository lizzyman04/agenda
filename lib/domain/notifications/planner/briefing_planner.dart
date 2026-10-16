import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/planner/kind_planner.dart';
import 'package:agenda/domain/notifications/rules/day_math.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';

const int _topTitles = 3;
const int _maxTitleLength = 60;

/// Plans the daily morning briefing (NOTF-02, D-03): one notification per day
/// of the horizon that has at least one due task.
///
/// The content (count and top titles) is computed here, at schedule time,
/// because a delivered local notification cannot run code. Every in-app
/// change to a task re-runs the planner through the coordinator, which
/// keeps the scheduled text current. Empty days and a today whose briefing
/// time has passed produce nothing.
final class BriefingPlanner implements KindPlanner {
  const BriefingPlanner();

  @override
  List<PlannedNotification> plan(PlannerInput input) {
    final planned = <PlannedNotification>[];
    final today = startOfDay(input.now);
    for (var offset = 0; offset < AppConstants.plannerHorizonDays; offset++) {
      final day = addDays(today, offset);
      final fireAt = atMinutes(day, input.prefs.briefingMinutes);
      if (!fireAt.isAfter(input.now)) continue;
      final tasks = _tasksDueOn(input.windowItems, day);
      if (tasks.isEmpty) continue;
      final dayNumber = epochDay(day);
      planned.add(
        PlannedNotification(
          kind: NotificationKind.morningBriefing,
          id: notificationId(
            base: NotificationKind.morningBriefing.idBase,
            entityId: dayNumber,
            type: NotificationKind.morningBriefing.idType,
          ),
          fireAt: fireAt,
          entityId: dayNumber,
          count: tasks.length,
          extras: [for (final t in tasks.take(_topTitles)) _clip(t.title)],
        ),
      );
    }
    return planned;
  }

  /// Open tasks due on [day]: timed ones by time first, then date-only ones.
  static List<Item> _tasksDueOn(List<Item> items, DateTime day) {
    final due = [
      for (final item in items)
        if (_isOpenTask(item) && _sameDay(item.dueDate!, day)) item,
    ];
    return due..sort(_byDueTimeThenTitle);
  }

  static bool _isOpenTask(Item item) =>
      item.type != ItemType.project &&
      !item.isCompleted &&
      item.deletedAt == null &&
      item.dueDate != null;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int _byDueTimeThenTitle(Item a, Item b) {
    final aTime = a.dueTimeMinutes;
    final bTime = b.dueTimeMinutes;
    if (aTime != null && bTime == null) return -1;
    if (aTime == null && bTime != null) return 1;
    if (aTime != null && bTime != null && aTime != bTime) {
      return aTime.compareTo(bTime);
    }
    final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
  }

  static String _clip(String title) =>
      title.length <= _maxTitleLength
          ? title
          : '${title.substring(0, _maxTitleLength)}…';
}
