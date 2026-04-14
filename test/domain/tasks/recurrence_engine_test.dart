import 'package:agenda/domain/tasks/recurrence_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal concrete implementation of RecurrenceEngine for domain tests.
///
/// Tests the parse() contract documented on the abstract interface.
/// nextOccurrence() tests live in Plan 02 (RecurrenceEngineImpl).
class _TestRecurrenceEngine implements RecurrenceEngine {
  @override
  ParsedRrule? parse(String? rrule) {
    if (rrule == null) return null;

    final parts = rrule.split(';');
    final props = <String, String>{};
    for (final part in parts) {
      final eq = part.indexOf('=');
      if (eq == -1) return null;
      props[part.substring(0, eq)] = part.substring(eq + 1);
    }

    final freqStr = props['FREQ'];
    if (freqStr == null) return null;

    final RruleFreq freq;
    switch (freqStr) {
      case 'DAILY':
        freq = RruleFreq.daily;
      case 'WEEKLY':
        freq = RruleFreq.weekly;
      case 'MONTHLY':
        freq = RruleFreq.monthly;
      case 'YEARLY':
        freq = RruleFreq.yearly;
      default:
        return null;
    }

    final byDayStr = props['BYDAY'];
    final byDay =
        byDayStr != null ? byDayStr.split(',') : const <String>[];

    final byMonthDayStr = props['BYMONTHDAY'];
    final byMonthDay =
        byMonthDayStr != null ? int.tryParse(byMonthDayStr) : null;

    return ParsedRrule(freq: freq, byDay: byDay, byMonthDay: byMonthDay);
  }

  @override
  DateTime nextOccurrence(DateTime from, ParsedRrule rule) {
    // Not tested at domain layer — implementation tested in Plan 02.
    throw UnimplementedError(
      'nextOccurrence tested against RecurrenceEngineImpl in Plan 02',
    );
  }
}

void main() {
  late _TestRecurrenceEngine engine;

  setUp(() {
    engine = _TestRecurrenceEngine();
  });

  group('RecurrenceEngine.parse — null and invalid input', () {
    test('parse(null) returns null', () {
      expect(engine.parse(null), isNull);
    });

    test('parse("INVALID") returns null', () {
      expect(engine.parse('INVALID'), isNull);
    });
  });

  group('RecurrenceEngine.parse — DAILY', () {
    test('parse("FREQ=DAILY") returns RruleFreq.daily', () {
      final result = engine.parse('FREQ=DAILY');
      expect(result, isNotNull);
      expect(result!.freq, RruleFreq.daily);
    });
  });

  group('RecurrenceEngine.parse — WEEKLY', () {
    test('parse("FREQ=WEEKLY;BYDAY=MO") returns byDay == ["MO"]', () {
      final result = engine.parse('FREQ=WEEKLY;BYDAY=MO');
      expect(result, isNotNull);
      expect(result!.freq, RruleFreq.weekly);
      expect(result.byDay, ['MO']);
    });

    test(
        'parse("FREQ=WEEKLY;BYDAY=MO,WE,FR") returns byDay == '
        '["MO", "WE", "FR"]', () {
      final result = engine.parse('FREQ=WEEKLY;BYDAY=MO,WE,FR');
      expect(result, isNotNull);
      expect(result!.byDay, ['MO', 'WE', 'FR']);
    });
  });

  group('RecurrenceEngine.parse — MONTHLY', () {
    test(
        'parse("FREQ=MONTHLY;BYMONTHDAY=15") returns byMonthDay == 15',
        () {
      final result = engine.parse('FREQ=MONTHLY;BYMONTHDAY=15');
      expect(result, isNotNull);
      expect(result!.freq, RruleFreq.monthly);
      expect(result.byMonthDay, 15);
    });
  });

  group('RecurrenceEngine.parse — YEARLY', () {
    test('parse("FREQ=YEARLY") returns RruleFreq.yearly', () {
      final result = engine.parse('FREQ=YEARLY');
      expect(result, isNotNull);
      expect(result!.freq, RruleFreq.yearly);
    });
  });
}
