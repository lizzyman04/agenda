import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/core/utils/guarded.dart';
import 'package:agenda/domain/lock/device_auth_gateway.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Biometric unlock (DATA-06, D-08) and the forgot-PIN device credential
/// check (D-06) for the lock screen.
///
/// Biometrics are an alternative to the PIN, never a replacement: the
/// keypad stays available whatever this answers. Nothing here unlocks.
@injectable
class LockDeviceAuth {
  LockDeviceAuth(this._gateway, this._prefs);

  final DeviceAuthGateway _gateway;
  final SharedPreferences _prefs;

  /// Whether the lock screen offers biometrics: the preference is on (an
  /// absent or unreadable value means the D-08 default, on) and the device
  /// has an enrolled biometric.
  Future<bool> biometricOffered() async {
    bool? stored;
    try {
      stored = _prefs.getBool(StorageKeys.biometricUnlockEnabled);
    } on Object {
      stored = null;
    }
    if (!(stored ?? true)) return false;
    return await _gateway.biometricAvailability() ==
        BiometricAvailability.enrolled;
  }

  /// Shows the biometric-only OS prompt. Never throws: an error is
  /// [DeviceAuthResult.cancelled], so it can never unlock (T-05-33).
  Future<DeviceAuthResult> unlockWithBiometrics(DeviceAuthPrompt prompt) =>
      guarded(
        () => _gateway.authenticate(prompt, biometricOnly: true),
        DeviceAuthResult.cancelled,
      );

  /// Whether the device has a screen lock (PIN, pattern or password). A
  /// failed check counts as none.
  Future<bool> hasDeviceCredential() =>
      guarded(_gateway.hasDeviceCredential, false);

  /// The OS prompt that also accepts the device PIN, pattern or password.
  /// Never throws: an error is [DeviceAuthResult.cancelled].
  Future<DeviceAuthResult> confirmDeviceCredential(DeviceAuthPrompt prompt) =>
      guarded(
        () => _gateway.authenticate(prompt, biometricOnly: false),
        DeviceAuthResult.cancelled,
      );

  /// Forgot PIN (D-06): [DeviceAuthResult.noDeviceCredential] when the
  /// device has no screen lock (no prompt is shown), otherwise the
  /// [confirmDeviceCredential] result. Only `success` proves identity.
  Future<DeviceAuthResult> confirmForgotPin(DeviceAuthPrompt prompt) async {
    if (!await hasDeviceCredential()) {
      return DeviceAuthResult.noDeviceCredential;
    }
    return confirmDeviceCredential(prompt);
  }
}
