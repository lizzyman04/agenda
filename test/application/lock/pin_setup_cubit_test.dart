// PinSetupCubit (DATA-05, D-06, D-07): create + confirm, mismatch, and the
// current-PIN step over the shared PinVerifier.

import 'package:agenda/application/lock/lock_screen_state.dart';
import 'package:agenda/application/lock/pin_verifier.dart';
import 'package:agenda/application/lock/setup/pin_setup_cubit.dart';
import 'package:agenda/application/lock/setup/pin_setup_state.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fake_clock.dart';
import '../../support/lock_fakes.dart';

void main() {
  late MockPinLifecycle lifecycle;
  late MockPinVerifier verifier;
  late FakeClock clock;
  late PinSetupCubit cubit;

  setUpAll(registerLockFallbacks);

  setUp(() {
    lifecycle = MockPinLifecycle();
    verifier = MockPinVerifier();
    clock = FakeClock();
    when(() => lifecycle.enable(any())).thenAnswer((_) async => true);
    when(() => lifecycle.change(any())).thenAnswer((_) async => true);
    when(() => lifecycle.reset(any())).thenAnswer((_) async => true);
    when(() => lifecycle.disable()).thenAnswer((_) async => true);
    cubit = PinSetupCubit(lifecycle, verifier, clock: clock.call);
  });

  tearDown(() => cubit.close());

  Future<void> enter(String pin) async {
    for (final unit in pin.codeUnits) {
      cubit.addDigit(unit - 0x30);
    }
    await pumpEventQueue();
  }

  void verifyNoSave() {
    verifyNever(() => lifecycle.enable(any()));
    verifyNever(() => lifecycle.change(any()));
    verifyNever(() => lifecycle.reset(any()));
    verifyNever(() => lifecycle.disable());
  }

  group('create', () {
    test('1234 then 1234 enables 1234 and finishes', () async {
      cubit.start(PinSetupMode.create);
      expect(cubit.state.step, PinSetupStep.create);

      await enter('1234');
      expect(cubit.state.step, PinSetupStep.confirm);
      expect(cubit.state.digitCount, 0);
      verifyNoSave();

      await enter('1234');
      verify(() => lifecycle.enable('1234')).called(1);
      expect(cubit.state.phase, PinSetupPhase.done);
    });

    test('a different confirmation: mismatch, back to create', () async {
      cubit.start(PinSetupMode.create);
      await enter('1234');
      await enter('1235');

      expect(cubit.state.message, const MismatchMessage());
      expect(cubit.state.step, PinSetupStep.create);
      expect(cubit.state.phase, PinSetupPhase.entering);
      expect(cubit.state.errorTick, 1);
      expect(cubit.state.digitCount, 0);
      verifyNoSave();
    });

    test('a failed save shows the check failure and asks again', () async {
      when(() => lifecycle.enable(any())).thenAnswer((_) async => false);
      cubit.start(PinSetupMode.create);
      await enter('1234');
      await enter('1234');

      expect(cubit.state.message, const CheckFailedMessage());
      expect(cubit.state.step, PinSetupStep.create);
      expect(cubit.state.phase, PinSetupPhase.entering);
    });

    test('state never carries the digits', () async {
      cubit.start(PinSetupMode.create);
      await enter('987');
      expect(cubit.state.toString(), isNot(contains('987')));
      expect(cubit.state.digitCount, 3);
    });
  });

  void answer(PinVerifyOutcome outcome) => when(
    () => verifier.verify(any(), any()),
  ).thenAnswer((_) async => outcome);

  group('change', () {
    test('correct current PIN, then new PIN + confirmation', () async {
      answer(const PinVerified());
      cubit.start(PinSetupMode.change);
      expect(cubit.state.step, PinSetupStep.current);

      await enter('1111');
      verify(() => verifier.verify('1111', clock())).called(1);
      expect(cubit.state.step, PinSetupStep.create);
      expect(cubit.state.digitCount, 0);

      await enter('2222');
      await enter('2222');
      verify(() => lifecycle.change('2222')).called(1);
      expect(cubit.state.phase, PinSetupPhase.done);
    });

    test('a wrong current PIN shows lockWrongPin; nothing saved', () async {
      answer(const PinRejected(4));
      cubit.start(PinSetupMode.change);

      await enter('9999');

      expect(cubit.state.message, const WrongPinMessage(4));
      expect(cubit.state.step, PinSetupStep.current);
      expect(cubit.state.phase, PinSetupPhase.entering);
      expect(cubit.state.errorTick, 1);
      verifyNoSave();
    });

    test('a failed check stays on the current step, fail closed', () async {
      answer(const PinCheckFailed());
      cubit.start(PinSetupMode.change);

      await enter('1111');

      expect(cubit.state.message, const CheckFailedMessage());
      expect(cubit.state.step, PinSetupStep.current);
      verifyNoSave();
    });
  });

  group('verify', () {
    test('a correct current PIN disables the lock and finishes', () async {
      answer(const PinVerified());
      cubit.start(PinSetupMode.verify);
      expect(cubit.state.step, PinSetupStep.current);

      await enter('1111');

      verify(() => lifecycle.disable()).called(1);
      expect(cubit.state.phase, PinSetupPhase.done);
    });

    test('a failed disable shows the check failure', () async {
      answer(const PinVerified());
      when(() => lifecycle.disable()).thenAnswer((_) async => false);
      cubit.start(PinSetupMode.verify);

      await enter('1111');

      expect(cubit.state.message, const CheckFailedMessage());
      expect(cubit.state.step, PinSetupStep.current);
      expect(cubit.state.phase, PinSetupPhase.entering);
    });
  });

  testWidgets('5th wrong current PIN: countdown, digits ignored, then entry', (
    tester,
  ) async {
    final attempts = LockAttempts(
      failures: 5,
      lockouts: 1,
      cooldownUntil: clock().add(const Duration(seconds: 30)),
    );
    answer(PinCoolingDown(attempts));
    cubit.start(PinSetupMode.verify);
    [9, 9, 9, 9].forEach(cubit.addDigit);
    await tester.pump();

    expect(cubit.state.phase, PinSetupPhase.coolingDown);
    expect(cubit.state.message, const CooldownMessage(Duration(seconds: 30)));
    cubit.addDigit(1);
    expect(cubit.state.digitCount, 0);
    verify(() => verifier.verify(any(), any())).called(1);

    clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(cubit.state.message, const CooldownMessage(Duration(seconds: 29)));

    clock.advance(const Duration(seconds: 29));
    await tester.pump(const Duration(seconds: 1));
    expect(cubit.state.phase, PinSetupPhase.entering);
    expect(cubit.state.message, isNull);
    expect(cubit.state.step, PinSetupStep.current);
    verifyNoSave();
  });

  test('reset: new PIN + confirmation calls reset and finishes', () async {
    cubit.start(PinSetupMode.reset);
    expect(cubit.state.step, PinSetupStep.create);

    await enter('4321');
    await enter('4321');

    verify(() => lifecycle.reset('4321')).called(1);
    verifyNever(() => verifier.verify(any(), any()));
    expect(cubit.state.phase, PinSetupPhase.done);
  });

  test('closing before the final step saves nothing in any mode', () async {
    answer(const PinVerified());
    for (final mode in PinSetupMode.values) {
      final c = PinSetupCubit(lifecycle, verifier, clock: clock.call)
        ..start(mode);
      final last = mode == PinSetupMode.verify;
      (last ? [1, 2] : [1, 2, 3, 4, 1, 2]).forEach(c.addDigit);
      await pumpEventQueue();
      await c.close();
    }
    verifyNoSave();
  });
}
