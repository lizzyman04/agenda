import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/model/quote_frequency.dart';
import 'package:agenda/domain/notifications/planner/kind_planner.dart';
import 'package:agenda/domain/notifications/planner/reminder_planner.dart';
import 'package:flutter_test/flutter_test.dart';

class _Stub implements KindPlanner {
  const _Stub(this.entries);

  final List<PlannedNotification> entries;

  @override
  List<PlannedNotification> plan(PlannerInput input) => entries;
}

final DateTime _now = DateTime(2026, 10, 12, 8);

PlannedNotification _n(
  int id,
  DateTime fireAt, {
  NotificationKind kind = NotificationKind.taskReminder,
}) => PlannedNotification(kind: kind, id: id, fireAt: fireAt);

PlannerInput _input(NotificationPrefs prefs, {int slotBudget = 200}) =>
    PlannerInput(now: _now, prefs: prefs, slotBudget: slotBudget);

void main() {
  group('NotificationPrefs', () {
    test('defaults enable everything except quotes', () {
      final prefs = NotificationPrefs.defaults();
      for (final kind in NotificationKind.values) {
        expect(
          prefs.isEnabled(kind),
          kind != NotificationKind.motivationalQuote,
          reason: kind.name,
        );
      }
      expect(prefs.quietHoursEnabled, isTrue);
      expect(prefs.quietStartMinutes, 1320);
      expect(prefs.quietEndMinutes, 420);
      expect(prefs.briefingMinutes, 480);
      expect(prefs.quoteFrequency, QuoteFrequency.daily);
      expect(prefs.quoteMinutes, 540);
    });

    test('withEnabled changes only the given kind', () {
      final base = NotificationPrefs.defaults();
      final off = base.withEnabled(NotificationKind.taskReminder, value: false);
      expect(off.isEnabled(NotificationKind.taskReminder), isFalse);
      for (final kind in NotificationKind.values) {
        if (kind == NotificationKind.taskReminder) continue;
        expect(off.isEnabled(kind), base.isEnabled(kind), reason: kind.name);
      }
      expect(base.isEnabled(NotificationKind.taskReminder), isTrue);
    });

    test('equal preferences are ==', () {
      expect(NotificationPrefs.defaults(), NotificationPrefs.defaults());
      final on = NotificationPrefs.defaults().withEnabled(
        NotificationKind.motivationalQuote,
        value: true,
      );
      expect(on, isNot(NotificationPrefs.defaults()));
    });
  });

  group('ReminderPlanner', () {
    final prefs = NotificationPrefs.defaults();

    test('a disabled kind is absent', () {
      final planner = ReminderPlanner([
        _Stub([
          _n(1, DateTime(2026, 10, 12, 10)),
          _n(
            2,
            DateTime(2026, 10, 12, 11),
            kind: NotificationKind.debtReminder,
          ),
        ]),
      ]);
      final off = prefs.withEnabled(
        NotificationKind.debtReminder,
        value: false,
      );
      expect(planner.plan(_input(off)).planned.map((p) => p.id), [1]);
    });

    test('a quote entry is dropped while quotes are off by default', () {
      final planner = ReminderPlanner([
        _Stub([
          _n(
            1,
            DateTime(2026, 10, 12, 10),
            kind: NotificationKind.motivationalQuote,
          ),
        ]),
      ]);
      expect(planner.plan(_input(prefs)).planned, isEmpty);
    });

    test('23:00 defers to 07:00 next day with quiet hours, else stays', () {
      final planner = ReminderPlanner([
        _Stub([_n(1, DateTime(2026, 10, 12, 23))]),
      ]);
      final on = planner.plan(_input(prefs)).planned.single.fireAt;
      expect(on, DateTime(2026, 10, 13, 7));
      final off = planner
          .plan(_input(prefs.copyWith(quietHoursEnabled: false)))
          .planned
          .single
          .fireAt;
      expect(off, DateTime(2026, 10, 12, 23));
    });

    test('entries at or before now are dropped', () {
      final planner = ReminderPlanner([
        _Stub([
          _n(1, _now),
          _n(2, _now.subtract(const Duration(minutes: 1))),
          _n(3, _now.add(const Duration(minutes: 1))),
        ]),
      ]);
      expect(planner.plan(_input(prefs)).planned.map((p) => p.id), [3]);
    });

    test('same id keeps the earlier fire time', () {
      final planner = ReminderPlanner([
        _Stub([_n(1, DateTime(2026, 10, 12, 15))]),
        _Stub([_n(1, DateTime(2026, 10, 12, 12))]),
      ]);
      final result = planner.plan(_input(prefs)).planned;
      expect(result.length, 1);
      expect(result.single.fireAt, DateTime(2026, 10, 12, 12));
    });

    test('slot budget keeps the soonest and reports truncated', () {
      final planner = ReminderPlanner([
        _Stub([
          for (var i = 1; i <= 5; i++) _n(i, DateTime(2026, 10, 12, 8 + i)),
        ]),
      ]);
      final result = planner.plan(_input(prefs, slotBudget: 3));
      expect(result.planned.map((p) => p.id), [1, 2, 3]);
      expect(result.truncated, 2);
    });

    test('several planners are concatenated before filtering', () {
      final planner = ReminderPlanner([
        _Stub([_n(1, DateTime(2026, 10, 12, 10))]),
        _Stub([
          _n(
            2,
            DateTime(2026, 10, 12, 11),
            kind: NotificationKind.recurringPayment,
          ),
        ]),
      ]);
      expect(planner.plan(_input(prefs)).planned.map((p) => p.id), [1, 2]);
    });
  });
}
