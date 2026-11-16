import 'dart:async';

import 'package:agenda/application/lock/lock_screen_cubit.dart';
import 'package:agenda/application/lock/lock_screen_state.dart';
import 'package:agenda/application/lock/pin_verifier.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:bloc_test/bloc_test.dart';
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

  LockScreenCubit build() =>
      LockScreenCubit(verifier, appLock, clock: clock.call);

  Future<LockScreenCubit> started() async {
    final cubit = build();
    await cubit.start();
    return cubit;
  }

  void enter(LockScreenCubit cubit, List<int> digits) {
    digits.forEach(cubit.addDigit);
  }

  const ready = LockScreenState(phase: LockEntryPhase.ready);

  blocTest<LockScreenCubit, LockScreenState>(
    'start moves from loading to ready',
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [ready],
  );

  test('three digits never call verify', () async {
    final cubit = await started();
    enter(cubit, [1, 2, 3]);
    expect(cubit.state, ready.copyWith(digitCount: 3));
    verifyNever(() => verifier.verify(any(), any()));
    await cubit.close();
  });

  test(
    'the 4th digit verifies once with the digits; PinVerified unlocks',
    () async {
      when(
        () => verifier.verify(any(), any()),
      ).thenAnswer((_) async => const PinVerified());
      final cubit = await started();
      enter(cubit, [1, 2, 3, 4]);
      expect(cubit.state.phase, LockEntryPhase.verifying);
      expect(cubit.state.digitCount, 4);
      await pumpEventQueue();
      verify(() => verifier.verify('1234', clock())).called(1);
      verify(() => appLock.unlock()).called(1);
      await cubit.close();
    },
  );

  for (final outcome in <PinVerifyOutcome>[
    const PinRejected(4),
    const PinCheckFailed(),
    const PinCoolingDown(LockAttempts.none),
  ]) {
    test(
      '${outcome.runtimeType} clears the digits and keeps the lock',
      () async {
        when(
          () => verifier.verify(any(), any()),
        ).thenAnswer((_) async => outcome);
        final cubit = await started();
        enter(cubit, [9, 9, 9, 9]);
        await pumpEventQueue();
        expect(cubit.state.phase, LockEntryPhase.ready);
        expect(cubit.state.digitCount, 0);
        expect(cubit.state.errorTick, 1);
        verifyNever(() => appLock.unlock());
        await cubit.close();
      },
    );
  }

  test('PinRejected(3) shows WrongPinMessage(3) and bumps errorTick', () async {
    when(
      () => verifier.verify(any(), any()),
    ).thenAnswer((_) async => const PinRejected(3));
    final cubit = await started();
    enter(cubit, [1, 1, 1, 1]);
    await pumpEventQueue();
    expect(
      cubit.state,
      const LockScreenState(
        phase: LockEntryPhase.ready,
        message: WrongPinMessage(3),
        errorTick: 1,
      ),
    );
    enter(cubit, [2, 2, 2, 2]);
    await pumpEventQueue();
    expect(cubit.state.errorTick, 2);
    await cubit.close();
  });

  test('PinCheckFailed shows CheckFailedMessage', () async {
    when(
      () => verifier.verify(any(), any()),
    ).thenAnswer((_) async => const PinCheckFailed());
    final cubit = await started();
    enter(cubit, [1, 2, 3, 4]);
    await pumpEventQueue();
    expect(cubit.state.message, const CheckFailedMessage());
    expect(cubit.state.errorTick, 1);
    await cubit.close();
  });

  test('typing a digit clears the message but keeps errorTick', () async {
    when(
      () => verifier.verify(any(), any()),
    ).thenAnswer((_) async => const PinRejected(2));
    final cubit = await started();
    enter(cubit, [1, 2, 3, 4]);
    await pumpEventQueue();
    expect(cubit.state.message, const WrongPinMessage(2));
    cubit.addDigit(5);
    expect(
      cubit.state,
      const LockScreenState(
        phase: LockEntryPhase.ready,
        digitCount: 1,
        errorTick: 1,
      ),
    );
    await cubit.close();
  });

  test('a verifier exception keeps the lock (fail closed)', () async {
    when(
      () => verifier.verify(any(), any()),
    ).thenThrow(StateError('storage'));
    final cubit = await started();
    enter(cubit, [1, 2, 3, 4]);
    await pumpEventQueue();
    expect(
      cubit.state,
      const LockScreenState(
        phase: LockEntryPhase.ready,
        message: CheckFailedMessage(),
        errorTick: 1,
      ),
    );
    verifyNever(() => appLock.unlock());
    await cubit.close();
  });

  test('input while loading is ignored', () async {
    final cubit = build();
    enter(cubit, [1, 2]);
    cubit
      ..removeDigit()
      ..clearDigits();
    expect(cubit.state, LockScreenState.initial);
    await cubit.close();
  });

  test('input while verifying is ignored', () async {
    final pending = Completer<PinVerifyOutcome>();
    when(
      () => verifier.verify(any(), any()),
    ).thenAnswer((_) => pending.future);
    final cubit = await started();
    enter(cubit, [1, 2, 3, 4, 5, 6]);
    cubit
      ..removeDigit()
      ..clearDigits();
    expect(
      cubit.state,
      const LockScreenState(phase: LockEntryPhase.verifying, digitCount: 4),
    );
    verify(() => verifier.verify('1234', any())).called(1);
    pending.complete(const PinRejected(4));
    await pumpEventQueue();
    expect(cubit.state.phase, LockEntryPhase.ready);
    expect(cubit.state.digitCount, 0);
    await cubit.close();
  });

  test('removeDigit and clearDigits edit the count', () async {
    final cubit = await started();
    enter(cubit, [1, 2, 3]);
    cubit.removeDigit();
    expect(cubit.state.digitCount, 2);
    cubit.clearDigits();
    expect(cubit.state.digitCount, 0);
    await cubit.close();
  });

  test('state never exposes the digits', () async {
    final pending = Completer<PinVerifyOutcome>();
    when(
      () => verifier.verify(any(), any()),
    ).thenAnswer((_) => pending.future);
    final cubit = await started();
    enter(cubit, [7, 3, 5]);
    expect(cubit.state.toString(), isNot(contains('735')));
    cubit.addDigit(8);
    expect(cubit.state.toString(), isNot(contains('7358')));
    expect(cubit.state.props, isNot(contains('7358')));
    pending.complete(const PinCheckFailed());
    await pumpEventQueue();
    await cubit.close();
  });
}
