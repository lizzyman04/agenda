import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/planner/briefing_planner.dart';
import 'package:agenda/domain/notifications/planner/reminder_planner.dart';
import 'package:agenda/domain/notifications/rules/day_math.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _now = DateTime(2026, 10, 12, 8);
final DateTime _tomorrow = DateTime(2026, 10, 13);

Item _item(
  int id,
  String title, {
  DateTime? dueDate,
  int? dueTimeMinutes,
  ItemType type = ItemType.task,
  bool isCompleted = false,
  DateTime? deletedAt,
}) => Item(
  id: id,
  type: type,
  title: title,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  dueDate: dueDate ?? _tomorrow,
  dueTimeMinutes: dueTimeMinutes,
  isCompleted: isCompleted,
  deletedAt: deletedAt,
);

PlannerInput _input(
  List<Item> items, {
  DateTime? now,
  NotificationPrefs? prefs,
}) => PlannerInput(
  now: now ?? _now,
  prefs: prefs ?? NotificationPrefs.defaults(),
  windowItems: items,
);

List<PlannedNotification> _plan(
  List<Item> items, {
  DateTime? now,
  NotificationPrefs? prefs,
}) => const BriefingPlanner().plan(_input(items, now: now, prefs: prefs));

void _expectAt(DateTime actual, int y, int m, int d, int h, int min) {
  expect(
    [actual.year, actual.month, actual.day, actual.hour, actual.minute],
    [y, m, d, h, min],
  );
}

void main() {
  group('BriefingPlanner', () {
    test('one briefing per day with count and ordered top titles', () {
      final result = _plan([
        _item(1, 'Nine', dueTimeMinutes: 9 * 60),
        _item(2, 'Dateonly'),
        _item(3, 'Eight', dueTimeMinutes: 8 * 60),
      ]);
      expect(result, hasLength(1));
      final n = result.single;
      _expectAt(n.fireAt, 2026, 10, 13, 8, 0);
      expect(n.kind, NotificationKind.morningBriefing);
      expect(n.count, 3);
      expect(n.extras, ['Eight', 'Nine', 'Dateonly']);
    });

    test('keeps only the top three titles but counts every task', () {
      final result = _plan([for (var i = 1; i <= 5; i++) _item(i, 'Task $i')]);
      expect(result.single.count, 5);
      expect(result.single.extras, ['Task 1', 'Task 2', 'Task 3']);
    });

    test('ties are broken by case-insensitive title then id', () {
      final result = _plan([
        _item(4, 'beta'),
        _item(3, 'Alpha'),
        _item(2, 'alpha'),
      ]);
      expect(result.single.extras, ['alpha', 'Alpha', 'beta']);
    });

    test('empty days produce no briefing', () {
      expect(_plan(const []), isEmpty);
    });

    test('completed, deleted and project items are not counted', () {
      final result = _plan([
        _item(1, 'Done', isCompleted: true),
        _item(2, 'Gone', deletedAt: DateTime(2026, 10, 2)),
        _item(3, 'Proj', type: ItemType.project),
        _item(4, 'Real'),
      ]);
      expect(result.single.count, 1);
      expect(result.single.extras, ['Real']);
    });

    test('items with no due date are ignored', () {
      final undated = Item(
        id: 9,
        type: ItemType.task,
        title: 'Undated',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(_plan([undated]), isEmpty);
    });

    test('today is omitted once its time passed, tomorrow is kept', () {
      final result = _plan([
        _item(1, 'Today', dueDate: DateTime(2026, 10, 12)),
        _item(2, 'Tomorrow'),
      ]);
      expect(result, hasLength(1));
      _expectAt(result.single.fireAt, 2026, 10, 13, 8, 0);
    });

    test('today is kept while its briefing time is still ahead', () {
      final result = _plan([
        _item(1, 'Today', dueDate: DateTime(2026, 10, 12)),
      ], now: DateTime(2026, 10, 12, 7));
      expect(result, hasLength(1));
      _expectAt(result.single.fireAt, 2026, 10, 12, 8, 0);
    });

    test('the horizon is seven days starting today', () {
      final result = _plan([
        _item(1, 'Day six', dueDate: DateTime(2026, 10, 18)),
        _item(2, 'Day seven', dueDate: DateTime(2026, 10, 19)),
      ]);
      expect(result.map((n) => n.extras.single), ['Day six']);
    });

    test('ids are unique per day in the system namespace', () {
      final result = _plan([
        _item(1, 'A'),
        _item(2, 'B', dueDate: DateTime(2026, 10, 14)),
      ]);
      expect(result, hasLength(2));
      expect(result.map((n) => n.id).toSet(), hasLength(2));
      final first = result.first;
      expect(first.entityId, epochDay(_tomorrow));
      expect(
        first.id,
        notificationId(base: 30, entityId: epochDay(_tomorrow), type: 0),
      );
    });

    test('long titles are clipped to 60 characters plus an ellipsis', () {
      final long = 'x' * 80;
      final result = _plan([_item(1, long), _item(2, 'y' * 60)]);
      expect(result.single.extras.first, '${'x' * 60}…');
      expect(result.single.extras.last, 'y' * 60);
    });

    test('quiet hours defer a 06:00 briefing to 07:00 the same day', () {
      final prefs = NotificationPrefs.defaults().copyWith(
        briefingMinutes: 6 * 60,
      );
      final result = const ReminderPlanner([
        BriefingPlanner(),
      ]).plan(_input([_item(1, 'Early')], prefs: prefs));
      expect(result.planned, hasLength(1));
      _expectAt(result.planned.single.fireAt, 2026, 10, 13, 7, 0);
    });
  });
}
