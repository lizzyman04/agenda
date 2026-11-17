---
phase: 05-app-lock-settings-polish
reviewed: 2026-11-17T02:49:01Z
depth: standard
files_reviewed: 71
files_reviewed_list:
  - android/app/src/main/AndroidManifest.xml
  - android/app/src/main/kotlin/com/omeu/space/agenda/MainActivity.kt
  - android/app/src/main/res/values-night/styles.xml
  - android/app/src/main/res/values/styles.xml
  - ios/Runner/AppDelegate.swift
  - ios/Runner/Info.plist
  - ios/Runner/SceneDelegate.swift
  - lib/app.dart
  - lib/application/lock/app_lock_cubit.dart
  - lib/application/lock/app_lock_state.dart
  - lib/application/lock/cooldown_ticker.dart
  - lib/application/lock/lock_device_auth.dart
  - lib/application/lock/lock_screen_cubit.dart
  - lib/application/lock/lock_screen_state.dart
  - lib/application/lock/pin_verifier.dart
  - lib/application/lock/setup/pin_lifecycle.dart
  - lib/application/lock/setup/pin_setup_cubit.dart
  - lib/application/lock/setup/pin_setup_state.dart
  - lib/application/settings/security_settings_cubit.dart
  - lib/application/settings/security_settings_state.dart
  - lib/config/di/infrastructure_module.dart
  - lib/config/startup/app_lock_startup.dart
  - lib/core/constants/secure_storage_keys.dart
  - lib/core/constants/storage_keys.dart
  - lib/core/utils/guarded.dart
  - lib/domain/lock/device_auth_gateway.dart
  - lib/domain/lock/excursion_guard.dart
  - lib/domain/lock/lock_attempts.dart
  - lib/domain/lock/lock_policy.dart
  - lib/domain/lock/pin_hasher.dart
  - lib/domain/lock/pin_record.dart
  - lib/domain/lock/pin_store.dart
  - lib/domain/lock/secure_window_gateway.dart
  - lib/infrastructure/backup/file_picker_backup_file_gateway.dart
  - lib/infrastructure/lock/excursion_guard_impl.dart
  - lib/infrastructure/lock/local_auth_gateway.dart
  - lib/infrastructure/lock/pbkdf2_pin_hasher.dart
  - lib/infrastructure/lock/secure_pin_store.dart
  - lib/infrastructure/lock/secure_window_channel.dart
  - lib/infrastructure/notifications/gateway/notification_permission_service_impl.dart
  - lib/main.dart
  - lib/presentation/finance/widgets/finance_empty_state.dart
  - lib/presentation/lock/keypad/biometric_key.dart
  - lib/presentation/lock/keypad/keypad_key.dart
  - lib/presentation/lock/keypad/lock_status_line.dart
  - lib/presentation/lock/keypad/pin_dots.dart
  - lib/presentation/lock/keypad/pin_keypad.dart
  - lib/presentation/lock/screens/forgot_pin_button.dart
  - lib/presentation/lock/screens/forgot_pin_dialog.dart
  - lib/presentation/lock/screens/lock_screen.dart
  - lib/presentation/lock/screens/pin_setup_screen.dart
  - lib/presentation/lock/widgets/lock_gate.dart
  - lib/presentation/lock/widgets/privacy_overlay.dart
  - lib/presentation/onboarding/screens/privacy_statement_screen.dart
  - lib/presentation/onboarding/widgets/onboarding_gate.dart
  - lib/presentation/onboarding/widgets/privacy_bullet.dart
  - lib/presentation/onboarding/widgets/privacy_language_switch.dart
  - lib/presentation/settings/screens/settings_screen.dart
  - lib/presentation/settings/security/biometric_tile.dart
  - lib/presentation/settings/security/no_device_lock_dialog.dart
  - lib/presentation/settings/security/pin_disable_dialog.dart
  - lib/presentation/settings/security/security_section.dart
  - lib/presentation/settings/security/timeout_dialog.dart
  - lib/presentation/settings/widgets/language_dialog.dart
  - lib/presentation/settings/widgets/settings_gear_button.dart
  - lib/presentation/settings/widgets/settings_section_header.dart
  - lib/presentation/shared/widgets/app_empty_state.dart
  - lib/presentation/tasks/screens/gtd_filter_screen.dart
  - lib/presentation/tasks/screens/task_list_screen.dart
  - lib/presentation/tasks/widgets/task_list_view.dart
findings:
  critical: 1
  warning: 5
  info: 2
  total: 8
  necessity: 0
status: issues_found
---

# Phase 5: Code Review Report

**Reviewed:** 2026-11-17T02:49:01Z
**Depth:** standard
**Files Reviewed:** 71
**Status:** issues_found

## Summary

I reviewed the Phase 5 app-lock stack end to end: the lifecycle cubit, lock policy, excursion guard, PIN verifier and store, PBKDF2 hasher, setup and forgot-PIN flows, LockGate layering, the Settings security section, and the Android and iOS native shields. The core primitives hold up. The PIN record is versioned and parsed defensively. Attempts are persisted before a result is returned. Every storage or plugin error resolves to a locked state. `AppLockCubit` decides the lock synchronously on the first frame.

The defects are in how the lock layer and the app tree share state over time:

- **The forgot-PIN reset screen keeps its device-credential proof indefinitely.** The lock timeout cannot clear it, so a stale proof survives background trips (CR-01).
- **The lock screen and the app share one `ScaffoldMessenger`.** App SnackBars, including working Undo actions, appear on the lock screen (WR-02).
- **The lock screen is not rebuilt when the app locks again during the unlock fade.** It can come back with a keypad that never re-enables (WR-03).

I also checked the cited `local_auth_android` 2.0.8 source (`AuthenticationHelper.java:64-70`) for WR-01 and the Flutter `ScaffoldMessengerState._updateScaffolds` and `_register` code for WR-02.

Necessity check: no findings. Guards on SharedPreferences and secure-storage values cross a trust boundary, and single-implementation interfaces are DI and test seams.

## Critical Issues

### CR-01: Forgot-PIN reset screen survives background trips, so the timeout never re-checks the device credential

**File:** `lib/presentation/lock/screens/forgot_pin_button.dart:64-70`, `lib/presentation/lock/widgets/lock_gate.dart:93-106`, `lib/application/lock/app_lock_cubit.dart:100`
**Issue:** After `DeviceAuthResult.success`, `PinSetupScreen(mode: reset)` is pushed onto the lock layer's own Navigator. From there, anyone can set a new PIN and unlock the app (`pin_setup_screen.dart:55`) without proving anything more. The app is already `locked`, so a later background trip changes nothing:

- `onResumed` computes `locked: state.locked || lock`, which is still `true`, so `_LockLayer.didUpdateWidget` sees no transition.
- The lock Navigator, with the reset page on top, is kept as is.

Scenario: the owner taps "Esqueci meu PIN", passes the device credential, then switches away (a call, another app) and leaves the device unlocked or hands it over. Hours later, opening AGENDA lands directly on "create new PIN". The holder sets any PIN and gets full access to tasks and finances. The resume timeout (D-02) is the control that should prevent this, but it never resets a post-authentication screen inside the lock layer. This path fails open.

**Fix:** Give each lock episode a fresh lock layer whenever a resume decides to lock, even if the app is already locked. Make sure the device-credential trip itself does not count: it runs inside the `ExcursionGuard`, so it is exempt for up to 300 s. For example:
```dart
// app_lock_state.dart: add `final int epoch;` (in props), default 0.
// app_lock_cubit.dart onResumed():
final next = state.copyWith(
  obscured: false,
  locked: state.locked || lock,
  epoch: lock ? state.epoch + 1 : state.epoch,
);
// lock_gate.dart: _LockLayer(locked: state.locked, epoch: state.epoch)
// and in _LockLayerState.build:
child: _LockNavigator(key: ValueKey(widget.epoch)),
```
Re-keying the Navigator drops the reset route and builds a new `LockScreen` and `LockScreenCubit`, which also fixes WR-03. Add a widget test: forgot-PIN success, a hidden trip longer than the timeout, resume, then expect `LockScreen` with no `PinSetupScreen`.

## Warnings

### WR-01: Forgot-PIN accepts any biometric, including Class-2 "weak" face unlock, even when the user turned biometric unlock off

**File:** `lib/application/lock/lock_device_auth.dart:49-53,58-63`, `lib/infrastructure/lock/local_auth_gateway.dart:56-60`
**Issue:** `confirmForgotPin` calls `authenticate(biometricOnly: false)`. In the resolved `local_auth_android` 2.0.8, that sets `BIOMETRIC_WEAK | BIOMETRIC_STRONG | DEVICE_CREDENTIAL` (`AuthenticationHelper.java:64-70`). A fingerprint or face match is therefore enough to reset the PIN and unlock, and so is a spoofable 2D face unlock on many Android devices. This happens even when `biometricUnlockEnabled == false`, the setting a user picks so that a biometric alone can never open the app. D-06 allows biometrics for forgot-PIN, but it did not consider the opt-out. Today the opt-out only hides the keypad key, and the same biometric still gets in through "Esqueci meu PIN". Code comments such as `forgot_pin_button.dart:20-21` ("the device credential is not guessable") also understate what is accepted.
**Fix:** When the biometric preference is off, require the device credential only. Android 11+ supports `setAllowedAuthenticators(DEVICE_CREDENTIAL)`, which needs a small native call or a `local_auth` option if one is available. On iOS, use `LAPolicy.deviceOwnerAuthentication` with Face ID disabled through a native channel. If that is out of scope, read the preference in `LockDeviceAuth.confirmForgotPin` and record the accepted risk in the threat register and the D-06 note. At minimum, fix the misleading comments.

### WR-02: App SnackBars, including working "Undo" actions, render on top of the lock screen

**File:** `lib/presentation/lock/widgets/lock_gate.dart:133-148`, `lib/presentation/lock/screens/lock_screen.dart:87`
**Issue:** `MaterialApp` puts its `ScaffoldMessenger` above `builder`, so the lock layer's `Scaffold` (LockScreen and the reset `PinSetupScreen`) registers with the same messenger as the app's scaffolds. Flutter shows every SnackBar on all root scaffolds (`ScaffoldMessengerState._updateScaffolds`), and a scaffold that registers while a SnackBar is active shows it at once (`_register`).

Scenario: a user deletes a task or transaction, which shows a SnackBar with an Undo action (`task_list_screen.dart:116`, `transaction_list_screen.dart:63`). They switch away and come back with "Immediately", or the app locks within the 4 s SnackBar lifetime. The lock screen then shows the SnackBar, and tapping Undo runs `restoreItem` / `restoreTransaction` on the hidden app while it is locked. With TalkBack or VoiceOver on (`accessibleNavigation`), SnackBars with actions do not auto-dismiss, so it stays on the lock screen indefinitely. Any future SnackBar that carries user data (for example a task title) would also leak through the lock.
**Fix:** Give the lock layer its own messenger and clear the app's SnackBars when locking:
```dart
// _LockNavigator.build
return ScaffoldMessenger(
  child: HeroControllerScope.none(child: Navigator(...)),
);
// _LockLayerState.didUpdateWidget, on locked && !oldWidget.locked:
ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
```
Then make the reset-mode `pinChangedSnack` (`pin_setup_screen.dart:53-58`) use the outer messenger, for example one passed in or found from the LockGate context, so it still appears over the app after unlock.

### WR-03: Locking again during the unlock fade leaves the lock screen stuck in `verifying` (keypad and biometric key both dead)

**File:** `lib/application/lock/lock_screen_cubit.dart:121-123,88`, `lib/presentation/lock/widgets/lock_gate.dart:95-103,116`
**Issue:** On `PinVerified`, `_submit` calls `_appLock.unlock()` without emitting, so the cubit stays in `LockEntryPhase.verifying` with `digitCount: 4`. The lock layer stays mounted until the 150 ms fade reaches `dismissed`. That fade runs on vsync, so it freezes when the app goes `hidden`. This can happen when the user taps the 4th digit and backgrounds the app during the PBKDF2 and storage work plus the fade. If the trip passes the timeout, `didUpdateWidget` sets `_fade.value = 1` on the same `LockScreen` and cubit:

- `addDigit` returns because the phase is not `ready`.
- `requestBiometric` returns because the phase is `verifying` (line 88).
- `_autoPrompted` is already true.
- `start()` is only called from `initState`.

The user can only kill the app or go through forgot-PIN. This fails closed, but it locks the user out.
**Fix:** Rebuild the lock layer per lock episode (the CR-01 epoch key does this). Or, when `_LockLayer` goes from unlocked to locked, call `start()` again on the cubit and reset `_autoPrompted`. As defense in depth, emit `_show(LockEntryPhase.ready, state.errorTick)` after `_appLock.unlock()` in the `PinVerified` branch.

### WR-04: Closing PIN setup during `saving` or `verifying` pops `false`, but the enable or disable still completes

**File:** `lib/presentation/lock/screens/pin_setup_screen.dart:81-85,93-97`, `lib/application/lock/setup/pin_setup_cubit.dart:98-100,118-130`
**Issue:** The screen's contract (lines 17-18) says that closing or backing out "before the save … changes nothing". The AppBar close button and system back are still active during `PinSetupPhase.saving` and `verifying`. When pressed, they pop `false` while `_lifecycle.enable(pin)` or `_lifecycle.disable()` keeps running unawaited and then commits. In verify mode, the user tapped cancel but the lock is turned off anyway. In create mode, the lock is turned on, but `_runSetup` sees `done != true` and shows no confirmation. `_finish` then returns early because the cubit is closed, so the user is never told what happened.
**Fix:** Block leaving while work is in flight. Read the phase from the cubit in `onPopInvokedWithResult` and the close button:
```dart
final busy = _cubit.state.phase == PinSetupPhase.saving ||
    _cubit.state.phase == PinSetupPhase.verifying;
if (!didPop && !_reset && !busy) Navigator.of(context).pop(false);
// AppBar close: onPressed: busy ? null : () => Navigator.of(context).pop(false)
```
Wrap these in a `BlocBuilder` so the button state updates.

### WR-05: A non-bool `pin_configured` locks the app but leaves the native shield off

**File:** `lib/config/startup/app_lock_startup.dart:28-38` vs `lib/application/lock/app_lock_cubit.dart:46-51`
**Issue:** `AppLockCubit._initialState` treats a non-bool `pin_configured` as "PIN on, locked" (fail closed). In `startAppLock`, the same `prefs.getBool` throws a `TypeError`, the outer `catch` swallows it, and `setSecure(enabled: true)` never runs. The app then starts locked with FLAG_SECURE off on Android and the App Switcher cover off on iOS, so the two halves of D-04 disagree. Screenshots, screen recording and the Recents thumbnail are not blanked for that session. The fresh-install wipe also never runs and retries on every launch.
**Fix:** Read the flag the same way in both places, for example with a shared helper that returns `true` on a type error, and keep the shield call outside the try block that covers the wipe:
```dart
bool pinConfigured;
try { pinConfigured = prefs.getBool(StorageKeys.pinConfigured) ?? false; }
on Object { pinConfigured = true; } // match AppLockCubit: fail closed
```

## Info

### IN-01: The PIN switch can push two setup screens; a second "create" overwrites the PIN without asking for the current one

**File:** `lib/presentation/settings/security/security_section.dart:42-43,82-93`
**Issue:** `_turnOn` awaits `hasDeviceCredential()`, a platform call, before pushing, and nothing stops a second tap in that window. A double tap stacks two `PinSetupScreen(mode: create)` routes. After the first one enables the PIN, the second remains and calls `PinLifecycle.enable` again, replacing the PIN with no current-PIN check. Change mode is designed to require that check (T-05-41). `PinLifecycle.enable` does not refuse when a PIN is already configured. The same user is at the device, so the impact is low.
**Fix:** Add an in-flight flag in `SecuritySection` (make it stateful) or in the cubit. Also make `PinLifecycle.enable` return `false` when `_appLock.state.pinEnabled` is already true.

### IN-02: Language switch drops the `setLocale` future

**File:** `lib/presentation/onboarding/widgets/privacy_language_switch.dart:35-36`
**Issue:** `onSelectionChanged` discards the `Future` from `LocaleCubit.setLocale`. `setLocale` awaits `_prefs.setString` without a guard (`locale_cubit.dart:47`), so a write fault becomes an unhandled async error on the first-launch screen. `language_dialog.dart:43` makes the same call but wraps it in `unawaited`, which states the intent but also does not handle the error.
**Fix:** Use `unawaited(...)` for consistency, and guard the write in `LocaleCubit.setLocale` with a try/catch that still emits or keeps the previous state.

---

_Reviewed: 2026-11-17T02:49:01Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
