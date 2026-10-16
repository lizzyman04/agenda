import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/planner/reminder_planner.dart';
import 'package:agenda/domain/notifications/planner/task_reminder_planner.dart';
import 'package:agenda/domain/notifications/planning/task_fire_time.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _now = DateTime(2026, 10, 12, 8);

Item _item({
  int id = 1,
  String title = 'Write report',
  ItemType type = ItemType.task,
  DateTime? dueDate,
  int? dueTimeMinutes,
  String? recurrenceRule,
  bool isCompleted = false,
  DateTime? deletedAt,
}) => Item(
  id: id,
  type: type,
  title: title,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  dueDate: dueDate,
  dueTimeMinutes: dueTimeMinutes,
  recurrenceRule: recurrenceRule,
  isCompleted: isCompleted,
  deletedAt: deletedAt,
);

PlannerInput _input(List<Item> items, {NotificationPrefs? prefs}) =>
    PlannerInput(
      now: _now,
      prefs: prefs ?? NotificationPrefs.defaults(),
      items: items,
    );

List<PlannedNotification> _plan(List<Item> items, {NotificationPrefs? prefs}) =>
    const TaskReminderPlanner().plan(_input(items, prefs: prefs));

void _expectAt(DateTime actual, int y, int m, int d, int h, int min) {
  expect(
    [actual.year, actual.month, actual.day, actual.hour, actual.minute],
    [y, m, d, h, min],
  );
}

void main() {
  group('TaskReminderPlanner', () {
    test('a timed task fires 30 minutes before its due time', () {
      final result = _plan([
        _item(dueDate: DateTime(2026, 10, 14), dueTimeMinutes: 14 * 60),
      ]);
      expect(result, hasLength(1));
      final n = result.single;
      _expectAt(n.fireAt, 2026, 10, 14, 13, 30);
      expect(n.variant, 0);
      expect(n.extras, ['14:00']);
      expect(n.kind, NotificationKind.taskReminder);
      expect(n.id, notificationId(base: 10, entityId: 1, type: 0));
      expect(n.entityId, 1);
      expect(n.subject, 'Write report');
    });

    test('a date-only task fires at the briefing time of its due day', () {
      final result = _plan([_item(dueDate: DateTime(2026, 10, 14))]);
      final n = result.single;
      _expectAt(n.fireAt, 2026, 10, 14, 8, 0);
      expect(n.variant, 1);
      expect(n.extras, isEmpty);
    });

    test('the due date time component is ignored', () {
      final result = _plan([_item(dueDate: DateTime(2026, 10, 14, 23, 59))]);
      _expectAt(result.single.fireAt, 2026, 10, 14, 8, 0);
    });

    test('a due time of 00:20 fires the previous evening at 23:50', () {
      final item = _item(dueDate: DateTime(2026, 10, 14), dueTimeMinutes: 20);
      _expectAt(_plan([item]).single.fireAt, 2026, 10, 13, 23, 50);
    });

    test('quiet hours defer that reminder to 07:00 of the due day', () {
      final item = _item(dueDate: DateTime(2026, 10, 14), dueTimeMinutes: 20);
      final result = const ReminderPlanner([
        TaskReminderPlanner(),
      ]).plan(_input([item]));
      expect(result.planned, hasLength(1));
      _expectAt(result.planned.single.fireAt, 2026, 10, 14, 7, 0);
    });

    test('a fire time at or before now produces no entry', () {
      final earlier = _item(
        dueDate: DateTime(2026, 10, 12),
        dueTimeMinutes: 8 * 60,
      );
      final dateOnly = _item(id: 2, dueDate: DateTime(2026, 10, 12));
      final later = DateTime(2026, 10, 12, 9);
      final input = PlannerInput(
        now: later,
        prefs: NotificationPrefs.defaults(),
        items: [earlier, dateOnly],
      );
      expect(const TaskReminderPlanner().plan(input), isEmpty);
    });

    test('a fire time equal to now is not planned', () {
      final item = _item(
        dueDate: DateTime(2026, 10, 12),
        dueTimeMinutes: 8 * 60 + 30,
      );
      expect(_plan([item]), isEmpty);
    });

    test('completed, deleted, project and undated items are skipped', () {
      final due = DateTime(2026, 10, 14);
      final result = _plan([
        _item(dueDate: due, isCompleted: true),
        _item(id: 2, dueDate: due, deletedAt: DateTime(2026, 10)),
        _item(id: 3, dueDate: due, type: ItemType.project),
        _item(id: 4),
      ]);
      expect(result, isEmpty);
    });

    test('a recurring item uses its own kind and id type', () {
      final item = _item(
        id: 5,
        dueDate: DateTime(2026, 10, 14),
        recurrenceRule: 'FREQ=WEEKLY',
      );
      final n = _plan([item]).single;
      expect(n.kind, NotificationKind.recurringTaskReminder);
      expect(n.id, notificationId(base: 10, entityId: 5, type: 1));
    });

    test('an empty recurrence rule is a plain task', () {
      final item = _item(dueDate: DateTime(2026, 10, 14), recurrenceRule: '');
      expect(_plan([item]).single.kind, NotificationKind.taskReminder);
    });

    test('disabling the recurring kind drops only recurring reminders', () {
      final due = DateTime(2026, 10, 14);
      final prefs = NotificationPrefs.defaults().withEnabled(
        NotificationKind.recurringTaskReminder,
        value: false,
      );
      final result = const ReminderPlanner([
        TaskReminderPlanner(),
      ]).plan(
        _input([
          _item(dueDate: due),
          _item(id: 2, dueDate: due, recurrenceRule: 'FREQ=DAILY'),
        ], prefs: prefs),
      );
      expect(result.planned.map((n) => n.entityId), [1]);
    });

    test('an id beyond the notification id range is skipped', () {
      final item = _item(
        id: maxNotificationEntityId + 1,
        dueDate: DateTime(2026, 10, 14),
      );
      expect(() => _plan([item]), returnsNormally);
      expect(_plan([item]), isEmpty);
    });

    test('a subtask is treated as a task', () {
      final item = _item(
        type: ItemType.subtask,
        dueDate: DateTime(2026, 10, 14),
      );
      expect(_plan([item]), hasLength(1));
    });
  });

  group('taskFireAt', () {
    test('returns null without a due date', () {
      expect(taskFireAt(_item(), briefingMinutes: 480, now: _now), isNull);
    });

    test('formatHhmm zero-pads hours and minutes', () {
      expect(formatHhmm(0), '00:00');
      expect(formatHhmm(9 * 60 + 5), '09:05');
      expect(formatHhmm(23 * 60 + 59), '23:59');
    });
  });
}
