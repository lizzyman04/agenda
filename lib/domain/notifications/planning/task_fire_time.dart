import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/notifications/rules/day_math.dart';
import 'package:agenda/domain/tasks/item.dart';

/// When a task reminder fires (D-01), or null when there is nothing to fire.
///
/// A task with a due time fires `taskReminderLeadMinutes` before it; a
/// date-only task fires at [briefingMinutes] on its due day. Only the
/// calendar components of `dueDate` are used. The result is built from
/// components, so a DST change cannot shift it by an hour, and a due time
/// close to midnight normalises to the previous evening.
///
/// Returns null when the item has no due date or the fire time is not
/// strictly after [now].
DateTime? taskFireAt(
  Item item, {
  required int briefingMinutes,
  required DateTime now,
}) {
  final due = item.dueDate;
  if (due == null) return null;
  final day = startOfDay(due);
  final dueMinutes = item.dueTimeMinutes;
  final fireAt =
      dueMinutes == null
          ? atMinutes(day, briefingMinutes)
          : atMinutes(day, dueMinutes - AppConstants.taskReminderLeadMinutes);
  return fireAt.isAfter(now) ? fireAt : null;
}

/// Zero-padded `HH:mm` for [minutesOfDay], with no intl dependency.
String formatHhmm(int minutesOfDay) {
  final hours = (minutesOfDay ~/ 60).toString().padLeft(2, '0');
  final minutes = (minutesOfDay % 60).toString().padLeft(2, '0');
  return '$hours:$minutes';
}
