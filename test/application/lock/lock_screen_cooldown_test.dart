// D-07 cooldown on the lock screen: countdown, app-kill resume, storage
// failure. testWidgets so `tester.pump` drives the periodic ticker; the
// FakeClock is advanced in lockstep.

import 'package:agenda/application/lock/lock_screen_cubit.dart';
import 'package:agenda/application/lock/lock_screen_state.dart';
import 'package:agenda/application/lock/pin_verifier.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:agenda/presentation/lock/keypad/lock_status_line.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fake_clock.dart';
import '../../support/lock_fakes.dart';

void main() {
  late MockPinVerifier verifier;
  late MockAppLockCubit appLock;
  late FakeClock clock;

  setUpAll(registerLockFallbacks);

  setUp(() {
    verifier = MockPinVerifier();
    appLock = MockAppLockCubit();
    clock = FakeClock();
    when(
      () => verifier.loadAttempts(),
    ).thenAnswer((_) async => const Success(LockAttempts.none));
  });

  LockScreenCubit build() => LockScreenCubit(
    verifier,
    appLock,
    pinOnlyDeviceAuth(),
    clock: clock.call,
  );

  /// Attempts whose [lockouts]-th cooldown has [left] to run.
  LockAttempts coolingDown(int lockouts, Duration left) => LockAttempts(
    failures: 4 + lockouts,
    lockouts: lockouts,
    cooldownUntil: clock().add(left),
  );

  String? countdown(LockScreenCubit cubit) => switch (cubit.state.message) {
    CooldownMessage(:final remaining) => formatCooldown(remaining),
    _ => null,
  };

  Future<void> tick(WidgetTester tester, [int seconds = 1]) async {
    for (var i = 0; i < seconds; i++) {
      clock.advance(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }
  }

  Future<void> wrongPin(
    WidgetTester tester,
    LockScreenCubit cubit,
    PinVerifyOutcome outcome,
  ) async {
    when(() => verifier.verify(any(), any())).thenAnswer((_) async => outcome);
    [9, 9, 9, 9].forEach(cubit.addDigit);
    await tester.pump();
  }

  testWidgets('5th wrong PIN: 30 s countdown, input ignored, then ready', (
    tester,
  ) async {
    final cubit = build();
    await cubit.start();
    await wrongPin(
      tester,
      cubit,
      PinCoolingDown(coolingDown(1, const Duration(seconds: 30))),
    );

    expect(cubit.state.phase, LockEntryPhase.coolingDown);
    expect(cubit.state.digitCount, 0);
    expect(cubit.state.errorTick, 1, reason: 'the 5th wrong PIN shakes too');
    expect(countdown(cubit), '0:30');

    await tick(tester);
    expect(countdown(cubit), '0:29');

    cubit
      ..addDigit(1)
      ..removeDigit()
      ..clearDigits();
    expect(cubit.state.digitCount, 0);
    expect(cubit.state.phase, LockEntryPhase.coolingDown);

    await tick(tester, 28);
    expect(countdown(cubit), '0:01');
    await tick(tester);
    expect(
      cubit.state,
      const LockScreenState(phase: LockEntryPhase.ready, errorTick: 1),
    );

    // The next wrong PIN escalates to the 1 min step (05-02 ladder).
    await wrongPin(
      tester,
      cubit,
      PinCoolingDown(coolingDown(2, const Duration(minutes: 1))),
    );
    expect(countdown(cubit), '1:00');
    expect(cubit.state.errorTick, 2);
    verify(() => verifier.verify('9999', any())).called(2);
    verifyNever(() => appLock.unlock());
    await cubit.close();
  });

  test(
    're-opening during a cooldown: the first state is the countdown',
    () async {
      when(() => verifier.loadAttempts()).thenAnswer(
        (_) async => Success(coolingDown(3, const Duration(minutes: 2))),
      );
      final cubit = build();
      final states = <LockScreenState>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.start();
      await pumpEventQueue();
      expect(states, [
        const LockScreenState(
          phase: LockEntryPhase.coolingDown,
          message: CooldownMessage(Duration(minutes: 2)),
        ),
      ]);
      await sub.cancel();
      await cubit.close();
    },
  );

  testWidgets('re-opening during a cooldown keeps counting down', (
    tester,
  ) async {
    when(() => verifier.loadAttempts()).thenAnswer(
      (_) async => Success(coolingDown(3, const Duration(minutes: 2))),
    );
    final cubit = build();
    await cubit.start();

    expect(cubit.state.phase, LockEntryPhase.coolingDown);
    expect(countdown(cubit), '2:00');
    cubit.addDigit(1);
    expect(cubit.state.digitCount, 0);
    await tick(tester);
    expect(countdown(cubit), '1:59');
    verifyNever(() => verifier.verify(any(), any()));

    await cubit.close();
    // A closed cubit's ticker is cancelled: no emits, no pending timer.
    await tick(tester, 3);
  });

  testWidgets('unreadable attempt state: CheckFailedMessage, retry allowed', (
    tester,
  ) async {
    when(
      () => verifier.loadAttempts(),
    ).thenAnswer((_) async => const Err(SecurityFailure('r: TestFault')));
    final cubit = build();
    await cubit.start();

    expect(
      cubit.state,
      const LockScreenState(
        phase: LockEntryPhase.ready,
        message: CheckFailedMessage(),
      ),
    );
    cubit.addDigit(4);
    expect(cubit.state.digitCount, 1);
    expect(cubit.state.message, isNull);
    verifyNever(() => appLock.unlock());
    await cubit.close();
  });

  testWidgets('a throwing load also fails closed but stays retryable', (
    tester,
  ) async {
    when(() => verifier.loadAttempts()).thenThrow(StateError('storage'));
    final cubit = build();
    await cubit.start();
    expect(cubit.state.phase, LockEntryPhase.ready);
    expect(cubit.state.message, const CheckFailedMessage());
    await cubit.close();
  });

  testWidgets('an expired persisted cooldown starts ready', (tester) async {
    final expired = coolingDown(1, const Duration(seconds: 30));
    clock.advance(const Duration(seconds: 31));
    when(
      () => verifier.loadAttempts(),
    ).thenAnswer((_) async => Success(expired));
    final cubit = build();
    await cubit.start();
    expect(cubit.state, const LockScreenState(phase: LockEntryPhase.ready));
    await cubit.close();
  });
}
