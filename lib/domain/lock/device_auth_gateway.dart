/// What biometric unlock the device can offer (DATA-06, RESEARCH Pattern 8).
enum BiometricAvailability {
  /// No biometric hardware, or the check failed.
  noHardware,

  /// Hardware is present but no fingerprint or face is enrolled.
  notEnrolled,

  /// At least one biometric is enrolled.
  enrolled,
}

/// The outcome of one OS authentication prompt.
///
/// Only [success] proves the user's identity; every other value keeps the
/// lock (T-05-33).
enum DeviceAuthResult {
  /// The OS confirmed the user.
  success,

  /// Cancelled, failed, timed out, fell back to the PIN, or any unexpected
  /// error. The caller falls back silently: the OS sheet already explained.
  cancelled,

  /// No biometric is enrolled or there is no hardware (any more).
  unavailable,

  /// The device has no screen lock to fall back to.
  noDeviceCredential,

  /// The OS locked biometrics out after too many failed tries.
  lockedOut,
}

/// The localized text of an OS authentication prompt. Fixed strings only;
/// no user data (T-05-35).
final class DeviceAuthPrompt {
  const DeviceAuthPrompt({
    required this.reason,
    required this.title,
    required this.hint,
    required this.cancelLabel,
  });

  /// Why the app asks (iOS and the Android subtitle).
  final String reason;

  /// Android sheet title.
  final String title;

  /// Android sheet hint.
  final String hint;

  /// Android negative button, which returns to the keypad.
  final String cancelLabel;
}

/// The OS authentication seam (fingerprint, face, device credential).
///
/// Implementations live in `lib/infrastructure/lock/` and run every prompt
/// inside the `ExcursionGuard`, so the prompt's own lifecycle trip never
/// relocks the app (D-03). No method throws.
abstract interface class DeviceAuthGateway {
  /// What biometric unlock the device can offer right now.
  Future<BiometricAvailability> biometricAvailability();

  /// False when the device has no screen lock (or the check fails).
  Future<bool> hasDeviceCredential();

  /// Shows the OS prompt. [biometricOnly] false also accepts the device
  /// PIN, pattern or password.
  Future<DeviceAuthResult> authenticate(
    DeviceAuthPrompt prompt, {
    required bool biometricOnly,
  });
}
