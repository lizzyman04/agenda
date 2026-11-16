import 'package:agenda/application/lock/app_lock_state.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns whether the app is locked (DATA-05, SC-1).
///
/// The initial state is computed synchronously in the constructor from the
/// pre-resolved [SharedPreferences], so the very first frame after a cold
/// start already knows whether to show the lock screen (RESEARCH Pattern 2).
/// A stored value that cannot be read as a bool locks the app: the lock
/// fails closed.
///
/// One instance app-wide: the lifecycle policy and the settings screen reach
/// the same cubit that `app.dart` provides.
@lazySingleton
class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit(SharedPreferences prefs) : super(_initialState(prefs));

  static AppLockState _initialState(SharedPreferences prefs) {
    bool? configured;
    try {
      configured = prefs.getBool(StorageKeys.pinConfigured);
    } on Object {
      // A non-bool value under the key: fail closed.
      return const AppLockState(pinEnabled: true, locked: true);
    }
    final enabled = configured ?? false;
    return AppLockState(pinEnabled: enabled, locked: enabled);
  }

  /// Removes the lock. Only a verified PIN (or a later verified biometric)
  /// may call this.
  void unlock() {
    if (!state.locked) return;
    emit(state.copyWith(locked: false));
  }

  /// Records that the PIN was switched on or off in Settings. Never locks:
  /// the person changing the setting has just proven they know the PIN.
  void pinEnabledChanged({required bool enabled}) {
    emit(AppLockState(pinEnabled: enabled, locked: false));
  }
}
