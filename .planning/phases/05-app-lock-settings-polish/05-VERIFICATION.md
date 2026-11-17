---
phase: 05-app-lock-settings-polish
verified: 2026-11-17T05:10:00Z
status: gaps_found
score: 139/145 must-haves verified (4 roadmap SCs + 141 plan truths)
covered_files:
  - ".planning/phases/05-app-lock-settings-polish/05-01-PLAN.md"
  - ".planning/phases/05-app-lock-settings-polish/05-01-SUMMARY.md"
  - ".planning/phases/05-app-lock-settings-polish/05-02-PLAN.md"
  - ".planning/phases/05-app-lock-settings-polish/05-02-SUMMARY.md"
  - ".planning/phases/05-app-lock-settings-polish/05-03-PLAN.md"
  - ".planning/phases/05-app-lock-settings-polish/05-03-SUMMARY.md"
  - ".planning/phases/05-app-lock-settings-polish/05-04-PLAN.md"
  - ".planning/phases/05-app-lock-settings-polish/05-04-SUMMARY.md"
  - ".planning/phases/05-app-lock-settings-polish/05-05-PLAN.md"
  - ".planning/phases/05-app-lock-settings-polish/05-05-SUMMARY.md"
  - ".planning/phases/05-app-lock-settings-polish/05-06-PLAN.md"
  - ".planning/phases/05-app-lock-settings-polish/05-06-SUMMARY.md"
  - ".planning/phases/05-app-lock-settings-polish/05-07-PLAN.md"
  - ".planning/phases/05-app-lock-settings-polish/05-07-SUMMARY.md"
  - ".planning/phases/05-app-lock-settings-polish/05-08-PLAN.md"
  - ".planning/phases/05-app-lock-settings-polish/05-08-SUMMARY.md"
  - ".planning/phases/05-app-lock-settings-polish/05-09-PLAN.md"
  - ".planning/phases/05-app-lock-settings-polish/05-09-SUMMARY.md"
  - ".planning/phases/05-app-lock-settings-polish/05-10-PLAN.md"
  - ".planning/phases/05-app-lock-settings-polish/05-10-SUMMARY.md"
  - ".planning/phases/05-app-lock-settings-polish/05-11-PLAN.md"
  - ".planning/phases/05-app-lock-settings-polish/05-11-SUMMARY.md"
  - ".planning/phases/05-app-lock-settings-polish/05-12-PLAN.md"
  - ".planning/phases/05-app-lock-settings-polish/05-12-SUMMARY.md"
  - ".planning/phases/05-app-lock-settings-polish/05-13-PLAN.md"
  - ".planning/phases/05-app-lock-settings-polish/05-13-SUMMARY.md"
  - ".planning/phases/05-app-lock-settings-polish/05-14-PLAN.md"
  - ".planning/phases/05-app-lock-settings-polish/05-14-SUMMARY.md"
  - "android/app/src/main/AndroidManifest.xml"
  - "android/app/src/main/kotlin/com/omeu/space/agenda/MainActivity.kt"
  - "android/app/src/main/res/values-night/styles.xml"
  - "android/app/src/main/res/values/styles.xml"
  - "ios/Runner/AppDelegate.swift"
  - "ios/Runner/Info.plist"
  - "ios/Runner/SceneDelegate.swift"
  - "lib/app.dart"
  - "lib/application/lock/app_lock_cubit.dart"
  - "lib/application/lock/app_lock_state.dart"
  - "lib/application/lock/cooldown_ticker.dart"
  - "lib/application/lock/lock_device_auth.dart"
  - "lib/application/lock/lock_screen_cubit.dart"
  - "lib/application/lock/lock_screen_state.dart"
  - "lib/application/lock/pin_verifier.dart"
  - "lib/application/lock/setup/pin_lifecycle.dart"
  - "lib/application/lock/setup/pin_setup_cubit.dart"
  - "lib/application/lock/setup/pin_setup_state.dart"
  - "lib/application/settings/security_settings_cubit.dart"
  - "lib/application/settings/security_settings_state.dart"
  - "lib/config/di/infrastructure_module.dart"
  - "lib/config/l10n/app_en.arb"
  - "lib/config/l10n/app_pt_BR.arb"
  - "lib/config/startup/app_lock_startup.dart"
  - "lib/core/constants/secure_storage_keys.dart"
  - "lib/core/constants/storage_keys.dart"
  - "lib/core/utils/guarded.dart"
  - "lib/domain/lock/device_auth_gateway.dart"
  - "lib/domain/lock/excursion_guard.dart"
  - "lib/domain/lock/lock_attempts.dart"
  - "lib/domain/lock/lock_policy.dart"
  - "lib/domain/lock/pin_hasher.dart"
  - "lib/domain/lock/pin_record.dart"
  - "lib/domain/lock/pin_store.dart"
  - "lib/domain/lock/secure_window_gateway.dart"
  - "lib/infrastructure/backup/file_picker_backup_file_gateway.dart"
  - "lib/infrastructure/lock/excursion_guard_impl.dart"
  - "lib/infrastructure/lock/local_auth_gateway.dart"
  - "lib/infrastructure/lock/pbkdf2_pin_hasher.dart"
  - "lib/infrastructure/lock/secure_pin_store.dart"
  - "lib/infrastructure/lock/secure_window_channel.dart"
  - "lib/infrastructure/notifications/gateway/notification_permission_service_impl.dart"
  - "lib/main.dart"
  - "lib/presentation/finance/widgets/finance_empty_state.dart"
  - "lib/presentation/lock/keypad/biometric_key.dart"
  - "lib/presentation/lock/keypad/keypad_key.dart"
  - "lib/presentation/lock/keypad/lock_status_line.dart"
  - "lib/presentation/lock/keypad/pin_dots.dart"
  - "lib/presentation/lock/keypad/pin_keypad.dart"
  - "lib/presentation/lock/screens/forgot_pin_button.dart"
  - "lib/presentation/lock/screens/forgot_pin_dialog.dart"
  - "lib/presentation/lock/screens/lock_screen.dart"
  - "lib/presentation/lock/screens/pin_setup_screen.dart"
  - "lib/presentation/lock/widgets/lock_gate.dart"
  - "lib/presentation/lock/widgets/privacy_overlay.dart"
  - "lib/presentation/onboarding/screens/privacy_statement_screen.dart"
  - "lib/presentation/onboarding/widgets/onboarding_gate.dart"
  - "lib/presentation/onboarding/widgets/privacy_bullet.dart"
  - "lib/presentation/onboarding/widgets/privacy_language_switch.dart"
  - "lib/presentation/settings/screens/settings_screen.dart"
  - "lib/presentation/settings/security/biometric_tile.dart"
  - "lib/presentation/settings/security/no_device_lock_dialog.dart"
  - "lib/presentation/settings/security/pin_disable_dialog.dart"
  - "lib/presentation/settings/security/security_section.dart"
  - "lib/presentation/settings/security/timeout_dialog.dart"
  - "lib/presentation/settings/widgets/language_dialog.dart"
  - "lib/presentation/settings/widgets/settings_gear_button.dart"
  - "lib/presentation/settings/widgets/settings_section_header.dart"
  - "lib/presentation/shared/widgets/app_empty_state.dart"
  - "lib/presentation/tasks/screens/gtd_filter_screen.dart"
  - "lib/presentation/tasks/screens/task_list_screen.dart"
  - "lib/presentation/tasks/widgets/task_list_view.dart"
  - "pubspec.yaml"
  - "test/widget_test.dart"
covered_digest: "v4:sha256:d46d6fc690160f00a5970408728a8eeb754d0567d5647b5642d8e68f7b2a43a7"
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "With a PIN enabled, returning from the background after at least the configured timeout shows the lock screen (05-08 truth 1; goal: 'protect the app with a PIN'; prohibition 05-06 'MUST NOT fail open')"
    status: failed
    reason: "CR-01 confirmed in code and corroborated by device UAT item 9 note. After forgot-PIN device-credential success, PinSetupScreen(mode: reset) is pushed on the lock layer's own Navigator. The app is already locked, so AppLockCubit.onResumed computes locked: state.locked || lock == true (no transition); _LockLayer.didUpdateWidget only reacts to locked false->true; _LockNavigator is const and keeps the reset route. Any later resume past the timeout lands on 'create new PIN', and saving it unlocks the app with full access. The UAT note ('Reopening the app returns to the same reset screen ... fail-safe') records exactly this fail-open path. No test covers forgot-PIN success -> hidden trip > timeout -> resume."
    artifacts:
      - path: "lib/application/lock/app_lock_cubit.dart"
        issue: "onResumed (line ~95-100) cannot signal a new lock episode when already locked"
      - path: "lib/presentation/lock/widgets/lock_gate.dart"
        issue: "_LockLayer/_LockNavigator are never rebuilt per lock episode; post-auth reset route survives background trips"
      - path: "lib/presentation/lock/screens/forgot_pin_button.dart"
        issue: "pushes reset page holding a device-credential proof with no expiry"
    missing:
      - "Lock-episode counter (epoch) in AppLockState, bumped in onResumed whenever shouldLockOnResume is true, even if already locked"
      - "Key _LockNavigator by epoch (ValueKey(epoch)) so a relock drops the reset route and builds a fresh LockScreen/LockScreenCubit"
      - "Ensure the device-credential prompt trip itself stays exempt (runs inside ExcursionGuard)"
      - "Widget test: forgot-PIN success, hidden trip > timeout, resume -> LockScreen present, PinSetupScreen absent"
  - truth: "The pin keypad remains usable at all times: biometrics are an alternative to the PIN, never a replacement (05-11 truth 10)"
    status: partial
    reason: "WR-03 confirmed: on PinVerified, LockScreenCubit._submit calls _appLock.unlock() without leaving LockEntryPhase.verifying. If the app relocks during the 150 ms unlock fade (fade frozen while hidden), the same LockScreen/cubit is reused: addDigit and requestBiometric both bail on 'verifying', start() only runs from initState. Keypad and biometric key are dead until the process is killed. Fails closed, but locks the user out. Same root cause as CR-01 (no per-episode rebuild)."
    artifacts:
      - path: "lib/application/lock/lock_screen_cubit.dart"
        issue: "PinVerified branch leaves phase = verifying"
      - path: "lib/presentation/lock/widgets/lock_gate.dart"
        issue: "relock reuses the existing LockScreen instead of a fresh one"
    missing:
      - "Fixed by the CR-01 epoch re-key; additionally emit ready after unlock() as defense in depth"
  - truth: "The lock layer covers every route; app content behind it is not hit-testable (05-06 truth 8)"
    status: partial
    reason: "WR-02 confirmed: the lock layer's Scaffold shares MaterialApp's root ScaffoldMessenger, so an app SnackBar (task/transaction delete with Undo) renders on the lock screen and its Undo action runs restoreItem/restoreTransaction on the hidden, locked app. Current SnackBar text is generic (no user data), so this is an action-through-the-lock, not a content leak."
    artifacts:
      - path: "lib/presentation/lock/widgets/lock_gate.dart"
        issue: "_LockNavigator not wrapped in its own ScaffoldMessenger; app SnackBars not cleared on lock"
    missing:
      - "Wrap the lock Navigator in its own ScaffoldMessenger and clearSnackBars() on the app messenger when locking"
      - "Route reset-mode pinChangedSnack to the outer messenger"
  - truth: "Cancelling PIN setup at any step before the final save leaves the stored PIN and pin_configured unchanged and returns false (05-12 truth 6)"
    status: partial
    reason: "WR-04 confirmed: PopScope and the AppBar close button stay active during PinSetupPhase.verifying/saving; they pop false while _lifecycle.enable/disable keeps running and commits. In verify mode the user cancels and the lock is turned off anyway; in create mode the lock turns on with no confirmation shown."
    artifacts:
      - path: "lib/presentation/lock/screens/pin_setup_screen.dart"
        issue: "close/back not blocked while work is in flight (lines ~81-97)"
    missing:
      - "Disable close and ignore back while phase is verifying or saving"
human_verification:
  - test: "iOS: build the Runner target on a Mac (SceneDelegate overrides, AppDelegate channel handler)"
    expected: "Runner compiles and launches"
    why_human: "No Mac on this host (user decision 4)"
  - test: "iOS: with a PIN on, unlock with Face ID"
    expected: "NSFaceIDUsageDescription prompt on first use, then Face ID unlocks without typing the PIN"
    why_human: "Requires iOS hardware"
  - test: "iOS: with a PIN on, open the App Switcher"
    expected: "AGENDA card shows the opaque cover, no app content (SC-2)"
    why_human: "Snapshot behaviour only observable on device"
  - test: "Decide WR-01: forgot-PIN accepts BIOMETRIC_WEAK|STRONG|DEVICE_CREDENTIAL even when the user turned biometric unlock off"
    expected: "Either restrict forgot-PIN to device credential when biometrics are opted out, or record the accepted risk against D-06"
    why_human: "Product/security decision; D-06 allowed biometrics but did not consider the opt-out"
---

# Phase 5: App Lock + Settings + Polish Verification Report

**Phase Goal:** Users can optionally protect the app with a PIN and biometrics; a settings screen unifies language, notification, and lock preferences; and the first-launch experience communicates the app's privacy commitment
**Verified:** 2026-11-17T05:10:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (roadmap Success Criteria + goal-critical plan truths)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC-1 | Optional PIN; every cold start with a PIN shows the lock screen before content, even after process kill | ✓ VERIFIED | `AppLockCubit._initialState` seeds `locked` synchronously from prefs (non-bool fails closed); `LockGate` in `MaterialApp.builder` puts app `Offstage`; `lock_gate_cold_start_test`, `widget_test` PIN cold-start smoke pass; device UAT item 4 (force-stop, UI tree had only lock nodes) |
| SC-2 | Biometric unlock without typing PIN; privacy overlay in iOS App Switcher | ? PARTIAL / human | Android: `LocalAuthGateway` + `LockDeviceAuth` + `BiometricKey`, `lock_screen_biometric_test` passes, UAT item 4 fingerprint unlock PASS, FLAG_SECURE UAT item 5 PASS. iOS: `SceneDelegate.swift` cover in willResignActive/didEnterBackground/didBecomeActive present; not compiled or run (no Mac) |
| SC-3 | Settings toggles language, per-type notifications, quiet hours, manages PIN | ✓ VERIFIED | `settings_screen.dart` sections General (LanguageTile), Security (SecuritySection), Notifications (pushes `NotificationSettingsScreen` with quiet hours), Data, About; `SettingsGearButton` in Tasks AppBar; UAT items 2, 3, 6, 11 |
| SC-4 | One-screen privacy statement on first launch only | ✓ VERIFIED | `OnboardingGate` sync flag read, write-then-transition; ARB `privacyStatement` = "Your data never leaves this device" / "Seus dados nunca saem deste aparelho"; `privacy_statement_test` (incl. setBool false/throws, 200% overflow); UAT item 1 |
| G-1 | PIN protection holds across warm resumes (05-08 T1: past-timeout resume shows the lock screen) | ✗ FAILED | CR-01: forgot-PIN reset route survives background trips; resume while already locked is not a new episode, so the post-auth "create new PIN" screen reappears for anyone. Corroborated by UAT item 9 note |
| G-2 | Keypad usable at all times (05-11 T10) | ✗ PARTIAL | WR-03: relock during unlock fade leaves cubit in `verifying`, keypad and biometric key dead |
| G-3 | Lock layer covers every route, app not interactive behind it (05-06 T8) | ✗ PARTIAL | WR-02: shared root ScaffoldMessenger; Undo SnackBar action reachable on lock screen |
| G-4 | Cancel before final save changes nothing (05-12 T6) | ✗ PARTIAL | WR-04: cancel during verifying/saving pops false but enable/disable still commits |

The remaining 135 plan truths (05-01..05-14, incl. backstop truths with explicit tests: 200% overflow tests for privacy statement and lock screen, setBool failure tests, prefs-throw defaults test, PT-BR plural strings test, Android FLAG_SECURE device observation) are VERIFIED via artifacts/links (all 14 plans: artifacts 45/45, key links 38/38 via gsd-tools) and passing tests.

**Score:** 139/145 (4 failed/partial, 2 human: SC-2 iOS half and 05-10 iOS backstop T8)

### Required Artifacts

All 45 declared artifacts across 14 plans exist and pass substantive checks (`verify.artifacts` all_passed for every plan). No stubs; no TBD/FIXME/XXX/TODO in the 70 phase-modified source files.

### Key Link Verification

38/38 key links verified (`verify.key-links`): LockGate in `app.dart` builder, OnboardingGate as home, AppLockCubit <- prefs `pinConfigured`, LockScreenCubit -> PinVerifier.verify, PinVerifier writeAttempts before return, startAppLock in `main.dart`, SecureWindowChannel <-> MainActivity FLAG_SECURE, ExcursionGuard `_guard.run` around file picker / permissions / local_auth, PinLifecycle -> setSecure/pinEnabledChanged, SecuritySettingsCubit -> appLock.stream.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase 5 lock/onboarding/settings/startup suites + full-app smoke | `flutter test test/widget_test.dart test/presentation/{lock,onboarding,settings} test/application/{lock,settings} test/domain/lock test/config/startup` | 222 passed | ✓ PASS |
| Forgot-PIN success then relock past timeout | (no test exists) | code trace + UAT note show reset screen persists | ✗ FAIL (CR-01) |
| No network dependency | grep pubspec for http/dio/firebase/sentry/connectivity | none | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED (no `scripts/*/tests/probe-*.sh` declared or present for this phase).

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DATA-05 | 01,02,03,06,08,09,10,12,13,14 | Optional PIN locks app on cold start | ✓ SATISFIED (cold start) / gap on warm-resume path | SC-1 verified; CR-01 undermines resume relock |
| DATA-06 | 01,08,10,11,12,13,14 | Biometric unlock when PIN enabled | ✓ SATISFIED Android / ? iOS human | UAT 4; Face ID unverified |
| UX-01 | 01,07,13,14 | EN/PT-BR toggled in Settings | ✓ SATISFIED | LanguageTile -> setLocale; UAT 2 |
| UX-03 | 01,04,14 | First-launch privacy statement | ✓ SATISFIED | OnboardingGate; UAT 1 |

UX-04 (05-05 empty states) is claimed by a plan but mapped to an earlier phase; implementation present (`AppEmptyState`, `TaskListEmptyState`). No orphaned Phase 5 requirements.

### Prohibitions (judgment tier, non-authoritative LLM verdict)

| Plan | Prohibition | Verdict |
|------|-------------|---------|
| 05-01 | No off-device dependency | Holds (pubspec grep clean) |
| 05-03 | PIN/hash/salt never in SharedPreferences/logs | Holds (no prefs/print in store, verifier, hasher) |
| 05-04 | No encryption over-claim | Holds (only `backupPrivacyNote` says backups are NOT encrypted) |
| 05-06 | MUST NOT fail open | **Violated in spirit by CR-01** — flagged, human review recommended |

### Anti-Patterns / Review Findings

| Finding | File | Severity | Impact |
|---------|------|----------|--------|
| CR-01 | lock_gate.dart, app_lock_cubit.dart, forgot_pin_button.dart | 🛑 Blocker | Stale device-credential proof bypasses resume timeout; anyone can set a new PIN |
| WR-03 | lock_screen_cubit.dart | ⚠️ Warning (gap, partial) | Lock screen can freeze; fail closed lockout |
| WR-02 | lock_gate.dart | ⚠️ Warning (gap, partial) | Undo actions run through the lock |
| WR-04 | pin_setup_screen.dart | ⚠️ Warning (gap, partial) | Cancel does not cancel |
| WR-01 | lock_device_auth.dart | ⚠️ Warning (human decision) | Weak biometric resets PIN despite opt-out |
| WR-05 | app_lock_startup.dart | ⚠️ Warning | Corrupt non-bool `pin_configured` locks but skips native shield; requires corrupted prefs |
| IN-01, IN-02 | security_section.dart, privacy_language_switch.dart | ℹ️ Info | Double-tap create; dropped future |

### Human Verification Required

1. **iOS Runner compile** — build on a Mac; expect clean compile.
2. **Face ID unlock** — expect NSFaceIDUsageDescription prompt then unlock without PIN.
3. **iOS App Switcher cover** — expect opaque cover with PIN on.
4. **WR-01 decision** — restrict forgot-PIN to device credential when biometrics are opted out, or record accepted risk under D-06.

### Gaps Summary

The phase delivers cold-start lock, biometric unlock (Android), a unified Settings screen, and the first-launch privacy statement; tests, analyzer, release build and Android UAT are genuinely green. The goal is not achieved for the lock's core guarantee, though: CR-01 is a fail-open path in which the forgot-PIN reset screen, reached after one device-credential check, persists across any number of background trips and hands whoever opens the app next a "set new PIN" screen that unlocks everything. The Android UAT observed this ("reopening returns to the same reset screen") and misclassified it as fail-safe. CR-01 and WR-03 share one root cause — the lock layer is never rebuilt per lock episode — and one fix (epoch-keyed lock Navigator). WR-02 and WR-04 are smaller, independent partial gaps. No later milestone phase covers these (Phase 6 is already complete and unrelated), so nothing is deferred.

---

_Verified: 2026-11-17T05:10:00Z_
_Verifier: Claude (gsd-verifier)_
