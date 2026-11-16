import 'package:agenda/application/lock/app_lock_state.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/domain/lock/excursion_guard.dart';
import 'package:agenda/domain/lock/lock_policy.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns whether the app is locked (DATA-05, SC-1, D-01..D-04).
///
/// The initial state is computed synchronously in the constructor from the
/// pre-resolved [SharedPreferences], so the very first frame after a cold
/// start already knows whether to show the lock screen (RESEARCH Pattern 2).
/// A stored value that cannot be read as a bool locks the app: the lock
/// fails closed.
///
/// Lifecycle (RESEARCH Pattern 3): `inactive` paints the privacy overlay
/// while frames still run, `hidden` records when the app left, and
/// `resumed` decides the lock with the wall clock. Only a trip through
/// `hidden` can lock; a trip that began during an app-initiated excursion
/// ([ExcursionGuard]) locks only past the excursion cap (D-03).
///
/// One instance app-wide: the lifecycle policy and the settings screen reach
/// the same cubit that `app.dart` provides.
@lazySingleton
class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit(
    this._prefs,
    this._guard, {
    @ignoreParam DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(_initialState(_prefs));

  final SharedPreferences _prefs;
  final ExcursionGuard _guard;
  final DateTime Function() _clock;

  /// When the app last reached `hidden`; null when it has not left.
  DateTime? _hiddenAt;

  /// Whether the current trip began during an app-initiated excursion.
  bool _hiddenDuringExcursion = false;

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

  /// `AppLifecycleState.inactive`: covers the app with the privacy overlay
  /// while frames are still produced (D-04). Never locks.
  void onInactive() {
    if (!state.pinEnabled || state.obscured) return;
    emit(state.copyWith(obscured: true));
  }

  /// `AppLifecycleState.hidden`: the app went to the background. The first
  /// `hidden` of a trip wins; `hidden -> paused -> hidden` keeps it.
  void onHidden() {
    if (_hiddenAt != null) return;
    final now = _clock();
    _hiddenAt = now;
    _hiddenDuringExcursion = _guard.isActive(now);
  }

  /// `AppLifecycleState.resumed`: removes the overlay and, in the SAME
  /// state change, locks when the background trip reached the timeout, so
  /// no frame of app content paints between them (D-01, D-02).
  void onResumed() {
    final now = _clock();
    final lock =
        state.pinEnabled &&
        shouldLockOnResume(
          hiddenAt: _hiddenAt,
          now: now,
          timeoutSeconds: LockPolicy.effectiveTimeoutSeconds(_storedTimeout()),
          hiddenDuringExcursion: _hiddenDuringExcursion,
        );
    _hiddenAt = null;
    _hiddenDuringExcursion = false;
    final next = state.copyWith(obscured: false, locked: state.locked || lock);
    if (next != state) emit(next);
  }

  /// The stored timeout, read at each resume so a Settings change applies
  /// to the next trip. An unreadable value counts as unset.
  int? _storedTimeout() {
    try {
      return _prefs.getInt(StorageKeys.lockTimeoutSeconds);
    } on Object {
      return null;
    }
  }
}
