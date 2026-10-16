import 'package:agenda/domain/notifications/rules/day_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('startOfDay / addDays / atMinutes', () {
    test('startOfDay drops the time part', () {
      expect(startOfDay(DateTime(2026, 10, 12, 14, 35)),
          DateTime(2026, 10, 12));
    });

    test('addDays keeps the wall-clock hour across a DST change', () {
      final result = addDays(DateTime(2026, 3, 28, 8), 2);
      expect(result, DateTime(2026, 3, 30, 8));
      expect(result.hour, 8);
    });

    test('addDays rolls over month ends', () {
      expect(addDays(DateTime(2026, 1, 31, 9, 15), 1),
          DateTime(2026, 2, 1, 9, 15));
    });

    test('atMinutes places a time of day and normalises overflow', () {
      final day = DateTime(2026, 10, 12);
      expect(atMinutes(day, 90), DateTime(2026, 10, 12, 1, 30));
      expect(atMinutes(day, -30), DateTime(2026, 10, 11, 23, 30));
      expect(atMinutes(day, 1500), DateTime(2026, 10, 13, 1));
    });

    test('minutesOfDay is hour * 60 + minute', () {
      expect(minutesOfDay(DateTime(2026, 10, 12, 7, 5)), 425);
    });
  });

  group('epochDay', () {
    test('is 0 on 1970-01-01 and 1 on 1970-01-02', () {
      expect(epochDay(DateTime(1970)), 0);
      expect(epochDay(DateTime(1970, 1, 2)), 1);
    });

    test('ignores the time of day', () {
      expect(epochDay(DateTime(2026, 10, 12, 23, 59)),
          epochDay(DateTime(2026, 10, 12)));
    });
  });

  group('mondayOf / weekKey', () {
    test('mondayOf a Wednesday is the Monday of that ISO week', () {
      expect(mondayOf(DateTime(2026, 10, 14)), DateTime(2026, 10, 12));
    });

    test('mondayOf a Monday is itself, a Sunday belongs to the week', () {
      expect(mondayOf(DateTime(2026, 10, 12, 18)), DateTime(2026, 10, 12));
      expect(mondayOf(DateTime(2026, 10, 18)), DateTime(2026, 10, 12));
    });

    test('weekKey is the zero-padded Monday date', () {
      expect(weekKey(DateTime(2026, 10, 14)), '2026-10-12');
      expect(weekKey(DateTime(2026, 10, 18, 23)), '2026-10-12');
      expect(weekKey(DateTime(2026, 3, 4)), '2026-03-02');
    });

    test('weekKey crosses a year boundary', () {
      expect(weekKey(DateTime(2027)), '2026-12-28');
    });
  });

  group('nextWeekdayAt', () {
    test('later the same Monday returns that Monday', () {
      final now = DateTime(2026, 10, 12, 8);
      expect(
        nextWeekdayAt(now, weekday: DateTime.monday, minutes: 540),
        DateTime(2026, 10, 12, 9),
      );
    });

    test('exactly at the moment returns the following week', () {
      final now = DateTime(2026, 10, 12, 9);
      expect(
        nextWeekdayAt(now, weekday: DateTime.monday, minutes: 540),
        DateTime(2026, 10, 19, 9),
      );
    });

    test('on a Tuesday returns the next Monday', () {
      final now = DateTime(2026, 10, 13, 10);
      expect(
        nextWeekdayAt(now, weekday: DateTime.monday, minutes: 540),
        DateTime(2026, 10, 19, 9),
      );
    });
  });
}
