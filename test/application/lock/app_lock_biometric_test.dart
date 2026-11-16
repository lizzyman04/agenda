// DATA-06 / D-08 on the lock-screen cubit: biometrics are offered from the
// preference (default on) and enrolment, only a success unlocks (and resets
// the D-07 counter), the auto-prompt fires once per episode, and the
// biometric path works during a cooldown.

import 'package:agenda/application/lock/lock_device_auth.dart';
import 'package:agenda/application/lock/lock_screen_cubit.dart';
import 'package:agenda/application/lock/lock_screen_state.dart';
import 'package:agenda/application/lock/pin_verifier.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/lock/device_auth_gateway.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_clock.dart';
import '../../support/lock_fakes.dart';

void main() {
  late MockPinVerifier verifier;
  late MockAppLockCubit appLock;
  late MockDeviceAuthGateway gateway;
  late FakeClock clock;

  setUpAll(registerLockFallbacks);

  setUp(() {
    verifier = MockPinVerifier();
    appLock = MockAppLockCubit();
    gateway = MockDeviceAuthGateway();
    clock = FakeClock();
    when(
      () => verifier.loadAttempts(),
    ).thenAnswer((_) async => const Success(LockAttempts.none));
    when(() => verifier.resetAttempts()).thenAnswer((_) async {});
    when(
      gateway.biometricAvailability,
    ).thenAnswer((_) async => BiometricAvailability.enrolled);
  });

  void answer(DeviceAuthResult result) => when(
    () =>
        gateway.authenticate(any(), biometricOnly: any(named: 'biometricOnly')),
  ).thenAnswer((_) async => result);

  Future<LockScreenCubit> build({Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final auth = LockDeviceAuth(
      gateway,
      await SharedPreferences.getInstance(),
    );
    return LockScreenCubit(verifier, appLock, auth, clock: clock.call);
  }

  group('LockDeviceAuth.biometricOffered', () {
    Future<bool> offered(Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
      return LockDeviceAuth(
        gateway,
        await SharedPreferences.getInstance(),
      ).biometricOffered();
    }

    test('absent preference is the D-08 default: on when enrolled', () async {
      expect(await offered({}), isTrue);
    });

    test('preference false: never offered, enrolment not even read', () async {
      expect(await offered({StorageKeys.biometricUnlockEnabled: false}), false);
      verifyNever(gateway.biometricAvailability);
    });

    test('not enrolled or no hardware: not offered', () async {
      for (final a in [
        BiometricAvailability.notEnrolled,
        BiometricAvailability.noHardware,
      ]) {
        when(gateway.biometricAvailability).thenAnswer((_) async => a);
        expect(
          await offered({StorageKeys.biometricUnlockEnabled: true}),
          false,
        );
      }
    });

    test('a non-bool preference counts as absent', () async {
      expect(await offered({StorageKeys.biometricUnlockEnabled: 'x'}), true);
    });
  });

  group('LockScreenCubit biometrics', () {
    test('start() resolves biometricOffered into the state', () async {
      final cubit = await build();
      await cubit.start();
      expect(
        cubit.state,
        const LockScreenState(
          phase: LockEntryPhase.ready,
          biometricOffered: true,
        ),
      );
      await cubit.close();
    });

    test('success resets the attempts, then unlocks', () async {
      answer(DeviceAuthResult.success);
      final cubit = await build();
      await cubit.start();
      await cubit.requestBiometric(fakeAuthPrompt);
      verifyInOrder([() => verifier.resetAttempts(), () => appLock.unlock()]);
      verify(
        () => gateway.authenticate(fakeAuthPrompt, biometricOnly: true),
      ).called(1);
      await cubit.close();
    });

    for (final result in [
      DeviceAuthResult.cancelled,
      DeviceAuthResult.lockedOut,
      DeviceAuthResult.noDeviceCredential,
    ]) {
      blocTest<LockScreenCubit, LockScreenState>(
        '${result.name}: no unlock, no message, no state change',
        build: () {
          final auth = MockLockDeviceAuth();
          when(auth.biometricOffered).thenAnswer((_) async => true);
          when(
            () => auth.unlockWithBiometrics(any()),
          ).thenAnswer((_) async => result);
          return LockScreenCubit(verifier, appLock, auth, clock: clock.call);
        },
        act: (cubit) async {
          await cubit.start();
          await cubit.requestBiometric(fakeAuthPrompt);
        },
        expect:
            () => const [
              LockScreenState(
                phase: LockEntryPhase.ready,
                biometricOffered: true,
              ),
            ],
        verify: (_) {
          verifyNever(() => appLock.unlock());
          verifyNever(() => verifier.resetAttempts());
        },
      );
    }

    test('a throwing prompt is a cancel and never unlocks', () async {
      when(
        () => gateway.authenticate(
          any(),
          biometricOnly: any(named: 'biometricOnly'),
        ),
      ).thenThrow(StateError('platform'));
      final cubit = await build();
      await cubit.start();
      await cubit.requestBiometric(fakeAuthPrompt);
      verifyNever(() => appLock.unlock());
      expect(cubit.state.message, isNull);
      await cubit.close();
    });

    test('unavailable hides the biometric key for this episode', () async {
      answer(DeviceAuthResult.unavailable);
      final cubit = await build();
      await cubit.start();
      await cubit.requestBiometric(fakeAuthPrompt);
      expect(cubit.state.biometricOffered, isFalse);
      expect(cubit.state.phase, LockEntryPhase.ready);
      // A later tap no longer reaches the OS.
      await cubit.requestBiometric(fakeAuthPrompt);
      verify(
        () => gateway.authenticate(any(), biometricOnly: true),
      ).called(1);
      verifyNever(() => appLock.unlock());
      await cubit.close();
    });

    test('autoPromptBiometric twice: one authenticate call', () async {
      answer(DeviceAuthResult.cancelled);
      final cubit = await build();
      await cubit.start();
      await cubit.autoPromptBiometric(fakeAuthPrompt);
      await cubit.autoPromptBiometric(fakeAuthPrompt);
      verify(
        () => gateway.authenticate(any(), biometricOnly: true),
      ).called(1);
      // The key still re-opens the prompt after the auto-prompt.
      await cubit.requestBiometric(fakeAuthPrompt);
      verify(
        () => gateway.authenticate(any(), biometricOnly: true),
      ).called(1);
      await cubit.close();
    });

    test('preference false: not offered and no prompt at all', () async {
      answer(DeviceAuthResult.success);
      final cubit = await build(
        prefs: {StorageKeys.biometricUnlockEnabled: false},
      );
      await cubit.start();
      expect(cubit.state.biometricOffered, isFalse);
      await cubit.autoPromptBiometric(fakeAuthPrompt);
      await cubit.requestBiometric(fakeAuthPrompt);
      verifyNever(
        () => gateway.authenticate(
          any(),
          biometricOnly: any(named: 'biometricOnly'),
        ),
      );
      verifyNever(() => appLock.unlock());
      await cubit.close();
    });

    test('ignored while a PIN is being verified', () async {
      answer(DeviceAuthResult.success);
      when(
        () => verifier.verify(any(), any()),
      ).thenAnswer(
        (_) => Future.delayed(
          const Duration(milliseconds: 1),
          () => const PinRejected(3),
        ),
      );
      final cubit = await build();
      await cubit.start();
      [1, 2, 3, 4].forEach(cubit.addDigit);
      expect(cubit.state.phase, LockEntryPhase.verifying);
      await cubit.requestBiometric(fakeAuthPrompt);
      verifyNever(
        () => gateway.authenticate(
          any(),
          biometricOnly: any(named: 'biometricOnly'),
        ),
      );
      await cubit.close();
    });

    test('success during a cooldown unlocks and keeps the key', () async {
      when(() => verifier.loadAttempts()).thenAnswer(
        (_) async => Success(
          LockAttempts(
            failures: 5,
            lockouts: 1,
            cooldownUntil: clock().add(const Duration(seconds: 30)),
          ),
        ),
      );
      answer(DeviceAuthResult.success);
      final cubit = await build();
      await cubit.start();
      expect(cubit.state.phase, LockEntryPhase.coolingDown);
      expect(cubit.state.biometricOffered, isTrue);
      await cubit.requestBiometric(fakeAuthPrompt);
      verifyInOrder([() => verifier.resetAttempts(), () => appLock.unlock()]);
      await cubit.close();
    });
  });
}
