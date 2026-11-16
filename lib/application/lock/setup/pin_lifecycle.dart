import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/core/utils/guarded.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:agenda/domain/lock/pin_hasher.dart';
import 'package:agenda/domain/lock/pin_record.dart';
import 'package:agenda/domain/lock/pin_store.dart';
import 'package:agenda/domain/lock/secure_window_gateway.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Creates, changes, disables and resets the app-lock PIN (DATA-05, D-06).
///
/// The write order makes a half-enabled lock impossible (RESEARCH
/// Pattern 10): [enable] writes `pin_configured = true` LAST and rolls back
/// when that write fails; [disable] writes `pin_configured = false` FIRST.
/// Every new record starts with [LockAttempts.none], so a new PIN never
/// inherits a cooldown (T-05-39). No method throws; false means nothing
/// the caller must act on changed.
@lazySingleton
class PinLifecycle {
  PinLifecycle(
    this._store,
    this._hasher,
    this._prefs,
    this._window,
    this._appLock,
  );

  final PinStore _store;
  final PinHasher _hasher;
  final SharedPreferences _prefs;
  final SecureWindowGateway _window;
  final AppLockCubit _appLock;

  /// Turns the lock on with [pin]: record and attempts, window shield, then
  /// the flag. A failed flag write clears the store and the shield.
  Future<bool> enable(String pin) async {
    if (!await _save(pin)) return false;
    await _window.setSecure(enabled: true);
    if (!await _setConfigured(true)) {
      await guarded(_store.clear, const Success<void>(null));
      await _window.setSecure(enabled: false);
      return false;
    }
    _appLock.pinEnabledChanged(enabled: true);
    return true;
  }

  /// Replaces the PIN of an enabled lock and clears the attempt counter.
  Future<bool> change(String pin) => _save(pin);

  /// Forgot-PIN reset (D-06): like [change]; the caller unlocks.
  Future<bool> reset(String pin) => _save(pin);

  /// Turns the lock off: the flag first (a failure changes nothing), then
  /// the shield, the stored record and the biometric preference, so a
  /// future PIN starts from the D-08 default.
  Future<bool> disable() async {
    if (!await _setConfigured(false)) return false;
    await _window.setSecure(enabled: false);
    // An Err is tolerated: the flag is already off and the next enable
    // overwrites the record.
    await guarded(_store.clear, const Success<void>(null));
    await guarded(
      () => _prefs.remove(StorageKeys.biometricUnlockEnabled),
      false,
    );
    _appLock.pinEnabledChanged(enabled: false);
    return true;
  }

  Future<bool> _save(String pin) async {
    final record = await guarded<PinRecord?>(() => _hasher.create(pin), null);
    if (record == null) return false;
    final written = await guarded<Result<void>?>(
      () => _store.writeRecord(record),
      null,
    );
    if (written is! Success) return false;
    final reset = await guarded<Result<void>?>(
      () => _store.writeAttempts(LockAttempts.none),
      null,
    );
    return reset is Success;
  }

  Future<bool> _setConfigured(bool value) =>
      guarded(() => _prefs.setBool(StorageKeys.pinConfigured, value), false);
}
