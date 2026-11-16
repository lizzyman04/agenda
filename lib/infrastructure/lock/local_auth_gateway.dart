import 'package:agenda/domain/lock/device_auth_gateway.dart';
import 'package:agenda/domain/lock/excursion_guard.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

/// [DeviceAuthGateway] over `local_auth` 3.0.1 (RESEARCH Pattern 8).
///
/// The only class that touches `local_auth`. Every prompt runs inside the
/// [ExcursionGuard], so returning from the OS sheet never relocks the app
/// (D-03). Only a `true` answer maps to [DeviceAuthResult.success]; every
/// exception maps to a non-success value (T-05-33). Neither the prompt text
/// nor any exception detail is logged.
@LazySingleton(as: DeviceAuthGateway)
class LocalAuthGateway implements DeviceAuthGateway {
  LocalAuthGateway(this._auth, this._guard);

  final LocalAuthentication _auth;
  final ExcursionGuard _guard;

  @override
  Future<BiometricAvailability> biometricAvailability() async {
    try {
      if (!await _auth.canCheckBiometrics) {
        return BiometricAvailability.noHardware;
      }
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isEmpty
          ? BiometricAvailability.notEnrolled
          : BiometricAvailability.enrolled;
    } on Object {
      return BiometricAvailability.noHardware;
    }
  }

  @override
  Future<bool> hasDeviceCredential() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  @override
  Future<DeviceAuthResult> authenticate(
    DeviceAuthPrompt prompt, {
    required bool biometricOnly,
  }) async {
    try {
      // sensitiveTransaction false for the biometric unlock skips Android's
      // extra face-unlock confirm tap (RESEARCH A5, revisit in UAT).
      // persistAcrossBackgrounding keeps its default, false: leaving the app
      // ends the prompt instead of resuming it (RESEARCH Pattern 8). The
      // localized Android sheet text is RESEARCH Pitfall 8.
      final ok = await _guard.run(
        () => _auth.authenticate(
          localizedReason: prompt.reason,
          biometricOnly: biometricOnly,
          sensitiveTransaction: !biometricOnly,
          authMessages: [
            AndroidAuthMessages(
              signInTitle: prompt.title,
              signInHint: prompt.hint,
              cancelButton: prompt.cancelLabel,
            ),
          ],
        ),
      );
      return ok ? DeviceAuthResult.success : DeviceAuthResult.cancelled;
    } on LocalAuthException catch (e) {
      return mapLocalAuthCode(e.code);
    } on Object {
      return DeviceAuthResult.cancelled;
    }
  }
}

/// The non-success outcome for a `local_auth` error [code]. Codes not
/// listed (user or system cancel, timeout, fallback tap, errors) are a
/// silent fallback to the keypad.
DeviceAuthResult mapLocalAuthCode(
  LocalAuthExceptionCode code,
) => switch (code) {
  LocalAuthExceptionCode.noBiometricsEnrolled ||
  LocalAuthExceptionCode.noBiometricHardware => DeviceAuthResult.unavailable,
  LocalAuthExceptionCode.noCredentialsSet =>
    DeviceAuthResult.noDeviceCredential,
  LocalAuthExceptionCode.temporaryLockout ||
  LocalAuthExceptionCode.biometricLockout => DeviceAuthResult.lockedOut,
  _ => DeviceAuthResult.cancelled,
};
