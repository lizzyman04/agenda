import 'package:agenda/domain/lock/lock_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hiddenAt = DateTime.utc(2026, 1, 1, 12);

  bool lockAfter(
    int elapsedSeconds,
    int timeoutSeconds, {
    bool excursion = false,
  }) => shouldLockOnResume(
    hiddenAt: hiddenAt,
    now: hiddenAt.add(Duration(seconds: elapsedSeconds)),
    timeoutSeconds: timeoutSeconds,
    hiddenDuringExcursion: excursion,
  );

  group('shouldLockOnResume', () {
    test('never locks when the app never reached hidden', () {
      for (final timeout in LockPolicy.timeoutOptionsSeconds) {
        for (final excursion in [false, true]) {
          expect(
            shouldLockOnResume(
              hiddenAt: null,
              now: hiddenAt.add(const Duration(hours: 5)),
              timeoutSeconds: timeout,
              hiddenDuringExcursion: excursion,
            ),
            isFalse,
          );
        }
      }
    });

    test('timeout 60 locks at elapsed >= 60 s', () {
      expect(lockAfter(59, 60), isFalse);
      expect(lockAfter(60, 60), isTrue);
      expect(lockAfter(61, 60), isTrue);
    });

    test('timeout 0 (Immediately) locks at elapsed 0', () {
      expect(lockAfter(0, 0), isTrue);
    });

    test('each option locks exactly at its timeout', () {
      for (final timeout in [30, 300, 900]) {
        expect(lockAfter(timeout - 1, timeout), isFalse, reason: '$timeout');
        expect(lockAfter(timeout, timeout), isTrue, reason: '$timeout');
      }
    });

    test('negative elapsed (clock moved back) locks, fail-closed', () {
      expect(lockAfter(-1, 900), isTrue);
      expect(lockAfter(-3600, 60, excursion: true), isTrue);
    });

    test('excursion trips are capped at max(timeout, 300 s)', () {
      expect(lockAfter(299, 0, excursion: true), isFalse);
      expect(lockAfter(300, 0, excursion: true), isTrue);
      expect(lockAfter(899, 900, excursion: true), isFalse);
      expect(lockAfter(900, 900, excursion: true), isTrue);
    });
  });

  group('LockPolicy', () {
    test('options and default match D-02', () {
      expect(LockPolicy.timeoutOptionsSeconds, const [0, 30, 60, 300, 900]);
      expect(LockPolicy.defaultTimeoutSeconds, 60);
      expect(LockPolicy.excursionCapSeconds, 300);
    });

    test('effectiveTimeoutSeconds falls back to 60 for unknown values', () {
      expect(LockPolicy.effectiveTimeoutSeconds(null), 60);
      expect(LockPolicy.effectiveTimeoutSeconds(45), 60);
      expect(LockPolicy.effectiveTimeoutSeconds(-1), 60);
      for (final option in LockPolicy.timeoutOptionsSeconds) {
        expect(LockPolicy.effectiveTimeoutSeconds(option), option);
      }
    });
  });
}
