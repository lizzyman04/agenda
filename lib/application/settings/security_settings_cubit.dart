import 'dart:async';

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/app_lock_state.dart';
import 'package:agenda/application/settings/security_settings_state.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/core/utils/guarded.dart';
import 'package:agenda/domain/lock/device_auth_gateway.dart';
import 'package:agenda/domain/lock/lock_policy.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the Settings Security section (SC-3, DATA-05, DATA-06, D-02,
/// D-08).
///
/// [SecuritySettingsState.pinEnabled] only ever mirrors [AppLockCubit],
/// which `PinLifecycle` updates after the flag is written, so the switch
/// never shows a lock that is not there (T-05-40). Setters persist first,
/// then emit. A preference that cannot be read falls back to its default.
@injectable
class SecuritySettingsCubit extends Cubit<SecuritySettingsState> {
  SecuritySettingsCubit(this._prefs, this._appLock, this._gateway)
    : super(
        SecuritySettingsState(
          pinEnabled: _appLock.state.pinEnabled,
          biometricEnabled: _readBiometric(_prefs),
          timeoutSeconds: _readTimeout(_prefs),
        ),
      );

  final SharedPreferences _prefs;
  final AppLockCubit _appLock;
  final DeviceAuthGateway _gateway;

  StreamSubscription<AppLockState>? _lockSub;

  static bool _readBiometric(SharedPreferences prefs) {
    try {
      return prefs.getBool(StorageKeys.biometricUnlockEnabled) ?? true;
    } on Object {
      return true;
    }
  }

  static int _readTimeout(SharedPreferences prefs) {
    int? stored;
    try {
      stored = prefs.getInt(StorageKeys.lockTimeoutSeconds);
    } on Object {
      stored = null;
    }
    return LockPolicy.effectiveTimeoutSeconds(stored);
  }

  /// Follows the lock's pinEnabled and loads biometric availability.
  Future<void> start() async {
    await _lockSub?.cancel();
    _lockSub = _appLock.stream.listen((lock) {
      if (isClosed || lock.pinEnabled == state.pinEnabled) return;
      // Disabling the PIN removes the biometric preference: re-read it.
      emit(
        state.copyWith(
          pinEnabled: lock.pinEnabled,
          biometricEnabled: _readBiometric(_prefs),
        ),
      );
    });
    await refreshAvailability();
  }

  /// Re-checks the device's biometrics; called on start and on resume.
  Future<void> refreshAvailability() async {
    final availability = await guarded(
      _gateway.biometricAvailability,
      BiometricAvailability.noHardware,
    );
    if (isClosed) return;
    emit(state.copyWith(availability: availability));
  }

  /// Whether the device has a screen lock; a failed check counts as none.
  Future<bool> hasDeviceCredential() =>
      guarded(_gateway.hasDeviceCredential, false);

  /// Persists the biometric unlock preference, then shows it. A failed
  /// write changes nothing on screen.
  Future<void> setBiometricEnabled({required bool enabled}) async {
    final saved = await guarded(
      () => _prefs.setBool(StorageKeys.biometricUnlockEnabled, enabled),
      false,
    );
    if (!saved || isClosed) return;
    emit(state.copyWith(biometricEnabled: enabled));
  }

  /// Persists one of the five timeout options; any other value is ignored.
  Future<void> setTimeoutSeconds(int seconds) async {
    if (!LockPolicy.timeoutOptionsSeconds.contains(seconds)) return;
    final saved = await guarded(
      () => _prefs.setInt(StorageKeys.lockTimeoutSeconds, seconds),
      false,
    );
    if (!saved || isClosed) return;
    emit(state.copyWith(timeoutSeconds: seconds));
  }

  @override
  Future<void> close() async {
    await _lockSub?.cancel();
    return super.close();
  }
}
