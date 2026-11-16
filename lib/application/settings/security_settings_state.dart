import 'package:agenda/domain/lock/device_auth_gateway.dart';
import 'package:agenda/domain/lock/lock_policy.dart';
import 'package:equatable/equatable.dart';

/// What the Settings Security section shows (SC-3, D-02, D-08).
final class SecuritySettingsState extends Equatable {
  const SecuritySettingsState({
    this.pinEnabled = false,
    this.availability,
    this.biometricEnabled = true,
    this.timeoutSeconds = LockPolicy.defaultTimeoutSeconds,
  });

  /// Mirrors `AppLockCubit.state.pinEnabled`; the switch never flips on its
  /// own.
  final bool pinEnabled;

  /// The device's biometric support; null until the first check resolves.
  final BiometricAvailability? availability;

  /// The biometric unlock preference (D-08 default: on).
  final bool biometricEnabled;

  /// One of `LockPolicy.timeoutOptionsSeconds`.
  final int timeoutSeconds;

  SecuritySettingsState copyWith({
    bool? pinEnabled,
    BiometricAvailability? availability,
    bool? biometricEnabled,
    int? timeoutSeconds,
  }) => SecuritySettingsState(
    pinEnabled: pinEnabled ?? this.pinEnabled,
    availability: availability ?? this.availability,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
  );

  @override
  List<Object?> get props => [
    pinEnabled,
    availability,
    biometricEnabled,
    timeoutSeconds,
  ];
}
