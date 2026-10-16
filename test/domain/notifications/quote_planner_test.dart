import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/notifications/model/planned_notification.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/model/quote_frequency.dart';
import 'package:agenda/domain/notifications/planner/quote_planner.dart';
import 'package:agenda/domain/notifications/planner/reminder_planner.dart';
import 'package:agenda/domain/notifications/planning/quote_picker.dart';
import 'package:agenda/domain/notifications/quotes/quotes_catalog.dart';
import 'package:agenda/domain/notifications/quotes/quotes_en.dart';
import 'package:agenda/domain/notifications/quotes/quotes_pt.dart';
import 'package:flutter_test/flutter_test.dart';

// Tuesday 2026-10-13 10:00.
final DateTime _now = DateTime(2026, 10, 13, 10);

NotificationPrefs _prefs({
  int minutes = 540,
  QuoteFrequency frequency = QuoteFrequency.daily,
  bool enabled = true,
}) => NotificationPrefs.defaults().copyWith(
  quoteMinutes: minutes,
  quoteFrequency: frequency,
  quoteSeed: 42,
  enabled: {NotificationKind.motivationalQuote: enabled},
);

PlannerInput _input(
  NotificationPrefs prefs, {
  List<String> quotes = const ['a one', 'b two', 'c three', 'd four'],
}) => PlannerInput(now: _now, prefs: prefs, quotes: quotes);

List<String> _days(List<PlannedNotification> out) => [
  for (final e in out) '${e.fireAt.month}-${e.fireAt.day}',
];

void main() {
  group('seededPermutation', () {
    test('is a stable permutation that depends on the seed', () {
      final a = seededPermutation(50, 7);
      expect(a, seededPermutation(50, 7));
      expect(a.toSet(), {for (var i = 0; i < 50; i++) i});
      expect(a, isNot(seededPermutation(50, 8)));
    });

    test('handles lengths 0 and 1', () {
      expect(seededPermutation(0, 3), isEmpty);
      expect(seededPermutation(1, 3), [0]);
    });
  });

  group('pickQuote', () {
    test('50 consecutive slots give 50 distinct quotes', () {
      final picked = {
        for (var i = 1000; i < 1050; i++) pickQuote(quotesEn, i, 9),
      };
      expect(picked, hasLength(50));
    });

    test('empty list is null and a negative index does not throw', () {
      expect(pickQuote(const [], 3, 1), isNull);
      expect(pickQuote(quotesEn, -7, 1), isNotNull);
    });
  });

  group('bundled quotes', () {
    for (final entry in {'en': quotesEn, 'pt': quotesPt}.entries) {
      test('${entry.key} list is large, unique and short', () {
        final list = entry.value;
        expect(list.length, greaterThanOrEqualTo(50));
        final lower = list.map((q) => q.toLowerCase()).toSet();
        expect(lower, hasLength(list.length));
        for (final q in list) {
          expect(q.trim(), isNotEmpty);
          expect(q.length, inInclusiveRange(10, 140), reason: q);
        }
      });
    }

    test('quotesFor picks the list by locale', () {
      expect(quotesFor('en'), same(quotesEn));
      expect(quotesFor('pt'), same(quotesPt));
      expect(quotesFor('xx'), same(quotesPt));
    });
  });

  group('QuotePlanner', () {
    const planner = QuotePlanner();

    test('daily after 09:00 plans 7 slots starting tomorrow', () {
      final out = planner.plan(_input(_prefs()));
      expect(out, hasLength(7));
      expect(_days(out).first, '10-14');
      expect(_days(out).last, '10-20');
      expect(out.first.fireAt.hour, 9);
    });

    test('daily at 20:00 includes today', () {
      final out = planner.plan(_input(_prefs(minutes: 1200)));
      expect(out, hasLength(7));
      expect(_days(out).first, '10-13');
      expect(out.first.fireAt.hour, 20);
    });

    test('weekly plans the next 7 Mondays', () {
      final out = planner.plan(
        _input(_prefs(frequency: QuoteFrequency.weekly)),
      );
      expect(out, hasLength(7));
      expect(_days(out).first, '10-19');
      expect(_days(out)[1], '10-26');
      expect(out.every((e) => e.fireAt.weekday == DateTime.monday), isTrue);
    });

    test('ids are unique and carry the quote type', () {
      final out = planner.plan(_input(_prefs()));
      expect(out.map((e) => e.id).toSet(), hasLength(7));
      expect(out.every((e) => e.id % 10 == 1), isTrue);
      expect(out.every((e) => e.subject.isNotEmpty), isTrue);
    });

    test('disabled (default) or empty list plans nothing', () {
      expect(planner.plan(_input(_prefs(enabled: false))), isEmpty);
      expect(
        planner.plan(
          PlannerInput(now: _now, prefs: NotificationPrefs.defaults()),
        ),
        isEmpty,
      );
      expect(planner.plan(_input(_prefs(), quotes: const [])), isEmpty);
    });

    test('quiet hours defer a 23:00 quote to 07:00 next day', () {
      final result = const ReminderPlanner([QuotePlanner()]).plan(
        _input(_prefs(minutes: 1380)),
      );
      final first = result.planned.first.fireAt;
      expect([first.month, first.day, first.hour], [10, 14, 7]);
    });
  });
}
