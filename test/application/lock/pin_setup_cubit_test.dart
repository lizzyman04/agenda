// PinSetupCubit (DATA-05, D-06, D-07): create + confirm, mismatch, and the
// current-PIN step over the shared PinVerifier.

import 'package:agenda/application/lock/lock_screen_state.dart';
import 'package:agenda/application/lock/pin_verifier.dart';
import 'package:agenda/application/lock/setup/pin_setup_cubit.dart';
import 'package:agenda/application/lock/setup/pin_setup_state.dart';
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

  test('change starts at the current step; a correct PIN moves on', () async {
    when(
      () => verifier.verify(any(), any()),
    ).thenAnswer((_) async => const PinVerified());
    cubit.start(PinSetupMode.change);
    expect(cubit.state.step, PinSetupStep.current);

    await enter('1111');
    expect(cubit.state.step, PinSetupStep.create);
    verify(() => verifier.verify('1111', clock())).called(1);
  });
}
