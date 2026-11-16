// LocalAuthGateway: local_auth answers and errors mapped to DeviceAuthResult
// and BiometricAvailability (DATA-06, T-05-33), every prompt inside the
// excursion guard (D-03, T-05-34).

import 'package:agenda/domain/lock/device_auth_gateway.dart';
import 'package:agenda/infrastructure/lock/excursion_guard_impl.dart';
import 'package:agenda/infrastructure/lock/local_auth_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/lock_fakes.dart';

void main() {
  late MockLocalAuthentication auth;
  late ExcursionGuardImpl guard;
  late LocalAuthGateway gateway;

  setUpAll(() {
    registerLockFallbacks();
    registerFallbackValue(<AuthMessages>[]);
  });

  setUp(() {
    auth = MockLocalAuthentication();
    guard = ExcursionGuardImpl();
    gateway = LocalAuthGateway(auth, guard);
  });

  Future<bool> authenticateCall() => auth.authenticate(
    localizedReason: any(named: 'localizedReason'),
    authMessages: any(named: 'authMessages'),
    biometricOnly: any(named: 'biometricOnly'),
    sensitiveTransaction: any(named: 'sensitiveTransaction'),
    persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
  );

  Future<DeviceAuthResult> unlock() =>
      gateway.authenticate(fakeAuthPrompt, biometricOnly: true);

  group('authenticate', () {
    test('true is success, false is cancelled', () async {
      when(authenticateCall).thenAnswer((_) async => true);
      expect(await unlock(), DeviceAuthResult.success);
      when(authenticateCall).thenAnswer((_) async => false);
      expect(await unlock(), DeviceAuthResult.cancelled);
    });

    const expected = <LocalAuthExceptionCode, DeviceAuthResult>{
      LocalAuthExceptionCode.userCanceled: DeviceAuthResult.cancelled,
      LocalAuthExceptionCode.systemCanceled: DeviceAuthResult.cancelled,
      LocalAuthExceptionCode.timeout: DeviceAuthResult.cancelled,
      LocalAuthExceptionCode.userRequestedFallback: DeviceAuthResult.cancelled,
      LocalAuthExceptionCode.authInProgress: DeviceAuthResult.cancelled,
      LocalAuthExceptionCode.uiUnavailable: DeviceAuthResult.cancelled,
      LocalAuthExceptionCode.deviceError: DeviceAuthResult.cancelled,
      LocalAuthExceptionCode.unknownError: DeviceAuthResult.cancelled,
      LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          DeviceAuthResult.cancelled,
      LocalAuthExceptionCode.noBiometricsEnrolled: DeviceAuthResult.unavailable,
      LocalAuthExceptionCode.noBiometricHardware: DeviceAuthResult.unavailable,
      LocalAuthExceptionCode.noCredentialsSet:
          DeviceAuthResult.noDeviceCredential,
      LocalAuthExceptionCode.temporaryLockout: DeviceAuthResult.lockedOut,
      LocalAuthExceptionCode.biometricLockout: DeviceAuthResult.lockedOut,
    };

    test('the table covers every LocalAuthExceptionCode', () {
      expect(expected.keys.toSet(), LocalAuthExceptionCode.values.toSet());
    });

    for (final entry in expected.entries) {
      test('${entry.key.name} -> ${entry.value.name}', () async {
        when(authenticateCall).thenThrow(LocalAuthException(code: entry.key));
        expect(await unlock(), entry.value);
      });
    }

    test('any other exception is cancelled, never success', () async {
      when(authenticateCall).thenThrow(StateError('platform'));
      expect(await unlock(), DeviceAuthResult.cancelled);
      when(authenticateCall).thenAnswer((_) async => throw Exception('async'));
      expect(await unlock(), DeviceAuthResult.cancelled);
    });

    test('runs inside the excursion guard', () async {
      bool? activeInside;
      when(authenticateCall).thenAnswer((_) async {
        // Far in the future: only an in-flight run, not the grace window,
        // can make the guard active here.
        activeInside = guard.isActive(
          DateTime.now().add(const Duration(days: 1)),
        );
        return true;
      });
      expect(guard.isActive(DateTime.now()), isFalse);
      await unlock();
      expect(activeInside, isTrue);
    });

    test('unlock: localized Android sheet, biometric only, not sticky, '
        'no extra confirm', () async {
      when(authenticateCall).thenAnswer((_) async => true);
      await unlock();
      final captured =
          verify(
                () => auth.authenticate(
                  localizedReason: 'reason',
                  authMessages: captureAny(named: 'authMessages'),
                  biometricOnly: true,
                  sensitiveTransaction: false,
                  persistAcrossBackgrounding: any(
                    named: 'persistAcrossBackgrounding',
                    that: isFalse,
                  ),
                ),
              ).captured.single
              as Iterable<AuthMessages>;
      expect(captured.single, isA<AndroidAuthMessages>());
      final android = captured.single as AndroidAuthMessages;
      expect(android.signInTitle, 'title');
      expect(android.signInHint, 'hint');
      expect(android.cancelButton, 'cancel');
    });

    test('device credential prompt keeps the sensitive confirm', () async {
      when(authenticateCall).thenAnswer((_) async => true);
      await gateway.authenticate(fakeAuthPrompt, biometricOnly: false);
      verify(
        () => auth.authenticate(
          localizedReason: 'reason',
          authMessages: any(named: 'authMessages'),
          biometricOnly: any(named: 'biometricOnly', that: isFalse),
          sensitiveTransaction: any(
            named: 'sensitiveTransaction',
            that: isTrue,
          ),
          persistAcrossBackgrounding: any(
            named: 'persistAcrossBackgrounding',
            that: isFalse,
          ),
        ),
      ).called(1);
    });
  });

  group('biometricAvailability', () {
    test('no hardware', () async {
      when(() => auth.canCheckBiometrics).thenAnswer((_) async => false);
      expect(
        await gateway.biometricAvailability(),
        BiometricAvailability.noHardware,
      );
      verifyNever(() => auth.getAvailableBiometrics());
    });

    test('hardware with nothing enrolled', () async {
      when(() => auth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => auth.getAvailableBiometrics()).thenAnswer((_) async => []);
      expect(
        await gateway.biometricAvailability(),
        BiometricAvailability.notEnrolled,
      );
    });

    test('hardware with [BiometricType.strong]', () async {
      when(() => auth.canCheckBiometrics).thenAnswer((_) async => true);
      when(
        () => auth.getAvailableBiometrics(),
      ).thenAnswer((_) async => [BiometricType.strong]);
      expect(
        await gateway.biometricAvailability(),
        BiometricAvailability.enrolled,
      );
    });

    test('a failing check is noHardware', () async {
      when(() => auth.canCheckBiometrics).thenThrow(StateError('platform'));
      expect(
        await gateway.biometricAvailability(),
        BiometricAvailability.noHardware,
      );
    });
  });

  group('hasDeviceCredential', () {
    test('follows isDeviceSupported; false on a throw', () async {
      when(() => auth.isDeviceSupported()).thenAnswer((_) async => true);
      expect(await gateway.hasDeviceCredential(), isTrue);
      when(() => auth.isDeviceSupported()).thenAnswer((_) async => false);
      expect(await gateway.hasDeviceCredential(), isFalse);
      when(() => auth.isDeviceSupported()).thenThrow(StateError('platform'));
      expect(await gateway.hasDeviceCredential(), isFalse);
    });
  });
}
