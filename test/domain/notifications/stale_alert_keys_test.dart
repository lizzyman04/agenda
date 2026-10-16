import 'package:agenda/domain/notifications/planning/stale_alert_keys.dart';
import 'package:flutter_test/flutter_test.dart';

// Monday of the current week is 2026-10-12.
final DateTime _now = DateTime(2026, 10, 16, 12);

void main() {
  group('budget markers', () {
    test('the current and two previous months survive', () {
      expect(isStaleAlertKey('b:2026-10:1:80', _now), isFalse);
      expect(isStaleAlertKey('b:2026-09:1:100', _now), isFalse);
      expect(isStaleAlertKey('b:2026-08:1:80', _now), isFalse);
    });

    test('older months are stale', () {
      expect(isStaleAlertKey('b:2026-07:1:80', _now), isTrue);
      expect(isStaleAlertKey('b:2025-12:9:100', _now), isTrue);
    });

    test('the year boundary counts months, not digits', () {
      final january = DateTime(2027, 1, 5);
      expect(isStaleAlertKey('b:2026-11:1:80', january), isFalse);
      expect(isStaleAlertKey('b:2026-10:1:80', january), isTrue);
    });

    test('a seeded marker of an older month is stale', () {
      expect(isStaleAlertKey('seeded:2026-10', _now), isFalse);
      expect(isStaleAlertKey('seeded:2026-09', _now), isTrue);
    });
  });

  group('goal markers', () {
    test('recent weeks survive', () {
      expect(isStaleAlertKey('gf:1:2026-10-12', _now), isFalse);
      expect(isStaleAlertKey('gs:1:2026-08-24', _now), isFalse);
    });

    test('weeks older than eight are stale', () {
      expect(isStaleAlertKey('gf:1:2026-08-10', _now), isTrue);
      expect(isStaleAlertKey('gs:4:2026-01-05', _now), isTrue);
    });
  });

  test('unknown or malformed keys are never stale', () {
    expect(isStaleAlertKey('mystery', _now), isFalse);
    expect(isStaleAlertKey('b:oops', _now), isFalse);
    expect(isStaleAlertKey('gf:1:not-a-date', _now), isFalse);
    expect(isStaleAlertKey('gf:1', _now), isFalse);
    expect(isStaleAlertKey('seeded:', _now), isFalse);
  });
}
