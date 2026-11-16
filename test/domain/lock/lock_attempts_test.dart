import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final base = DateTime.utc(2026, 1, 1, 12);

  /// Registers [count] failures one second apart, starting at [start].
  LockAttempts failTimes(LockAttempts from, int count, DateTime start) {
    var state = from;
    for (var i = 0; i < count; i++) {
      state = state.registerFailure(start.add(Duration(seconds: i)));
    }
    return state;
  }

  test('failures 1..4 count down remainingBeforeCooldown with no cooldown', () {
    var state = LockAttempts.none;
    for (var n = 1; n <= 4; n++) {
      state = state.registerFailure(base);
      expect(state.failures, n);
      expect(state.remainingBeforeCooldown, 5 - n);
      expect(state.lockouts, 0);
      expect(state.cooldownUntil, isNull);
      expect(state.isCoolingDown(base), isFalse);
    }
  });

  test('exactly the 5th failure starts a 30 s cooldown', () {
    final fourth = failTimes(LockAttempts.none, 4, base);
    expect(fourth.isCoolingDown(base), isFalse);

    final fifth = fourth.registerFailure(base);
    expect(fifth.lockouts, 1);
    expect(fifth.cooldownUntil, base.add(const Duration(seconds: 30)));
    expect(fifth.remainingBeforeCooldown, 0);
    expect(fifth.isCoolingDown(base), isTrue);
    expect(fifth.cooldownRemaining(base), const Duration(seconds: 30));
  });

  test('the cooldown ends exactly at cooldownUntil', () {
    final fifth = failTimes(LockAttempts.none, 4, base).registerFailure(base);
    expect(fifth.isCoolingDown(base.add(const Duration(seconds: 29))), isTrue);
    expect(fifth.isCoolingDown(base.add(const Duration(seconds: 30))), isFalse);
  });

  test('later failures escalate to 1, 5 and 15 min, then stay capped', () {
    var now = base;
    var state = failTimes(LockAttempts.none, 4, now).registerFailure(now);
    expect(state.cooldownUntil!.difference(now), const Duration(seconds: 30));

    const expected = [
      Duration(minutes: 1),
      Duration(minutes: 5),
      Duration(minutes: 15),
      Duration(minutes: 15),
      Duration(minutes: 15),
    ];
    for (var i = 0; i < expected.length; i++) {
      now = state.cooldownUntil!;
      expect(state.isCoolingDown(now), isFalse);
      state = state.registerFailure(now);
      expect(state.lockouts, i + 2);
      expect(state.remainingBeforeCooldown, 0);
      expect(state.cooldownUntil!.difference(now), expected[i]);
      expect(state.isCoolingDown(now), isTrue);
    }
  });

  test('a backwards clock cannot extend a cooldown past its ladder step', () {
    final tampered = LockAttempts(
      failures: 5,
      lockouts: 1,
      cooldownUntil: base.add(const Duration(hours: 1)),
    );
    expect(tampered.cooldownRemaining(base), const Duration(seconds: 30));
    expect(tampered.isCoolingDown(base), isTrue);
  });

  test('cooldownRemaining is zero once the cooldown ended', () {
    final fifth = failTimes(LockAttempts.none, 4, base).registerFailure(base);
    expect(
      fifth.cooldownRemaining(base.add(const Duration(seconds: 30))),
      Duration.zero,
    );
    expect(
      fifth.cooldownRemaining(base.add(const Duration(hours: 2))),
      Duration.zero,
    );
    expect(LockAttempts.none.cooldownRemaining(base), Duration.zero);
  });

  test('none equals a default instance and differs after any failure', () {
    // The default constructor is the subject here: value equality with none.
    // ignore: use_named_constants
    expect(LockAttempts.none, const LockAttempts());
    expect(LockAttempts.none.failures, 0);
    expect(LockAttempts.none.lockouts, 0);
    expect(LockAttempts.none.cooldownUntil, isNull);
    expect(LockAttempts.none.remainingBeforeCooldown, 5);
    expect(LockAttempts.none.registerFailure(base), isNot(LockAttempts.none));
  });

  test('ladder constants match D-07', () {
    expect(LockAttempts.maxFailuresBeforeCooldown, 5);
    expect(LockAttempts.cooldownLadder, const [
      Duration(seconds: 30),
      Duration(minutes: 1),
      Duration(minutes: 5),
      Duration(minutes: 15),
    ]);
  });
}
