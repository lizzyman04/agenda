import 'package:agenda/domain/tasks/recurrence_engine.dart';
import 'package:agenda/infrastructure/tasks/recurrence_engine_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = RecurrenceEngineImpl();

  group('RecurrenceEngineImpl.parse', () {
    test('parse(null) returns null', () {
      expect(engine.parse(null), isNull);
    });

    test("parse('') returns null", () {
      expect(engine.parse(''), isNull);
    });

    test("parse('INVALID') returns null", () {
      expect(engine.parse('INVALID'), isNull);
    });

    test("parse('FREQ=DAILY') returns daily with empty byDay", () {
      final result = engine.parse('FREQ=DAILY');
      expect(result, isNotNull);
      expect(result!.freq, RruleFreq.daily);
      expect(result.byDay, isEmpty);
      expect(result.byMonthDay, isNull);
    });

    test("parse('FREQ=WEEKLY;BYDAY=MO') returns byDay=['MO']", () {
      final result = engine.parse('FREQ=WEEKLY;BYDAY=MO');
      expect(result, isNotNull);
      expect(result!.freq, RruleFreq.weekly);
      expect(result.byDay, ['MO']);
    });

    test("parse('FREQ=WEEKLY;BYDAY=MO,WE,FR') returns byDay=['MO','WE','FR']",
        () {
      final result = engine.parse('FREQ=WEEKLY;BYDAY=MO,WE,FR');
      expect(result, isNotNull);
      expect(result!.byDay, ['MO', 'WE', 'FR']);
    });

    test("parse('FREQ=MONTHLY;BYMONTHDAY=15') returns byMonthDay=15", () {
      final result = engine.parse('FREQ=MONTHLY;BYMONTHDAY=15');
      expect(result, isNotNull);
      expect(result!.freq, RruleFreq.monthly);
      expect(result.byMonthDay, 15);
    });

    test("parse('FREQ=YEARLY') returns yearly freq", () {
      final result = engine.parse('FREQ=YEARLY');
      expect(result, isNotNull);
      expect(result!.freq, RruleFreq.yearly);
    });
  });

  group('RecurrenceEngineImpl.nextOccurrence', () {
    test('DAILY: adds 1 day', () {
      final from = DateTime(2024, 3, 10);
      const rule = ParsedRrule(freq: RruleFreq.daily);
      final next = engine.nextOccurrence(from, rule);
      expect(next, DateTime(2024, 3, 11));
    });

    test('WEEKLY (no BYDAY): adds 7 days', () {
      final from = DateTime(2024, 3, 10); // Sunday
      const rule = ParsedRrule(freq: RruleFreq.weekly);
      final next = engine.nextOccurrence(from, rule);
      expect(next, DateTime(2024, 3, 17));
    });

    test('WEEKLY (BYDAY=MO): returns the next Monday after from', () {
      // from = Thursday 2024-03-07; next Monday = 2024-03-11
      final from = DateTime(2024, 3, 7); // Thursday
      const rule = ParsedRrule(freq: RruleFreq.weekly, byDay: ['MO']);
      final next = engine.nextOccurrence(from, rule);
      expect(next.weekday, DateTime.monday);
      expect(next.isAfter(from), isTrue);
    });

    test('MONTHLY (BYMONTHDAY=15): returns the 15th of next month', () {
      final from = DateTime(2024, 3, 10);
      const rule = ParsedRrule(freq: RruleFreq.monthly, byMonthDay: 15);
      final next = engine.nextOccurrence(from, rule);
      expect(next.month, 4);
      expect(next.day, 15);
      expect(next.year, 2024);
    });

    test('YEARLY: same day next year', () {
      final from = DateTime(2024, 6, 15, 9, 30);
      const rule = ParsedRrule(freq: RruleFreq.yearly);
      final next = engine.nextOccurrence(from, rule);
      expect(next, DateTime(2025, 6, 15, 9, 30));
    });
  });
}
