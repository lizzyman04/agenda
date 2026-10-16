import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/rules/slot_budget.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _base = DateTime(2026, 10, 12, 8);

PlannedNotification _n(NotificationKind kind, int id, int hours) =>
    PlannedNotification(
      kind: kind,
      id: id,
      fireAt: _base.add(Duration(hours: hours)),
    );

List<PlannedNotification> _many(
  NotificationKind kind,
  int count, {
  int idStart = 0,
}) => [for (var i = 0; i < count; i++) _n(kind, idStart + i, i + 1)];

void main() {
  const briefing = NotificationKind.morningBriefing;
  const quote = NotificationKind.motivationalQuote;
  const task = NotificationKind.taskReminder;

  test('caps briefings and quotes at 7 each', () {
    final result = selectWithinBudget(
      [..._many(briefing, 10), ..._many(quote, 10, idStart: 100)],
      budget: 200,
    );
    expect(result.kept.where((p) => p.kind == briefing).length, 7);
    expect(result.kept.where((p) => p.kind == quote).length, 7);
    expect(result.truncated, 6);
  });

  test('reserves briefings and quotes then fills with soonest tasks', () {
    final tasks = _many(task, 70, idStart: 1000);
    final result = selectWithinBudget(
      [
        ..._many(briefing, 3, idStart: 10),
        ..._many(quote, 3, idStart: 20),
        ...tasks,
      ],
      budget: 60,
    );
    expect(result.kept.length, 60);
    expect(result.truncated, 16);
    expect(result.kept.where((p) => p.kind == briefing).length, 3);
    expect(result.kept.where((p) => p.kind == quote).length, 3);
    final keptTasks = result.kept.where((p) => p.kind == task).toList();
    expect(keptTasks.length, 54);
    expect(keptTasks.map((p) => p.id), tasks.take(54).map((p) => p.id));
  });

  test('output is sorted by fireAt then id', () {
    final result = selectWithinBudget(
      [_n(task, 5, 2), _n(task, 3, 2), _n(task, 9, 1)],
      budget: 10,
    );
    expect(result.kept.map((p) => p.id), [9, 3, 5]);
  });

  test('a tiny budget honours briefings first, then the soonest quotes', () {
    final result = selectWithinBudget(
      [
        ..._many(briefing, 3, idStart: 10),
        ..._many(quote, 3, idStart: 20),
        ..._many(task, 4, idStart: 30),
      ],
      budget: 5,
    );
    expect(result.kept.length, 5);
    expect(result.truncated, 5);
    expect(result.kept.where((p) => p.kind == briefing).length, 3);
    final quoteIds = result.kept
        .where((p) => p.kind == quote)
        .map((p) => p.id)
        .toList();
    expect(quoteIds, [20, 21]);
    expect(result.kept.any((p) => p.kind == task), isFalse);
  });

  test('budget 0 keeps nothing and truncates every entry', () {
    final input = _many(task, 4);
    final result = selectWithinBudget(input, budget: 0);
    expect(result.kept, isEmpty);
    expect(result.truncated, input.length);
  });

  test('everything fits: nothing truncated', () {
    final result = selectWithinBudget(_many(task, 4), budget: 60);
    expect(result.kept.length, 4);
    expect(result.truncated, 0);
  });
}
