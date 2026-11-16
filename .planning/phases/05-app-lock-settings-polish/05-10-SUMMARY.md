---
phase: 05-app-lock-settings-polish
plan: 10
subsystem: auth
tags: [flutter, platform-channel, android, ios, flag-secure, app-switcher, privacy, app-lock]
status: complete

requires:
  - phase: 05-app-lock-settings-polish
    provides: "05-03 startAppLock (fresh-install wipe); 05-08 resume lock and ExcursionGuard; 05-01 lock_platform_contract_test source-contract group"
provides:
  - "SecureWindowGateway (domain, never throws) and SecureWindowChannel over MethodChannel 'agenda/app_privacy', method 'setSecure', single bool argument"
  - "Kotlin setSecure handler: `as? Boolean` validation, window.addFlags/clearFlags(FLAG_SECURE), result.error(\"bad_args\") otherwise"
  - "Swift PrivacyShield.enabled + SceneDelegate opaque cover in sceneWillResignActive and sceneDidEnterBackground, removed in sceneDidBecomeActive"
  - "AppDelegate appPrivacyChannel: `as? Bool` validation, FlutterError bad_args"
  - "startAppLock applies setSecure(enabled: true) on every process start when pin_configured"
  - "MockSecureWindowGateway in test/support/lock_fakes.dart"
affects: [05-12 PinLifecycle toggles the gateway on PIN enable/disable, 05-14 device UAT]

actuals:
  tokens: 5476
  tasks: 2
  commits: 2
plan_head_before: f4b82545d78b65e05adce05ab27dd7fefdd6f6d9
plan_head_after: 93b187b357a8f268d183cbd661c9ba9b08820a12

tech-stack:
  added: []
  patterns:
    - "One concern per method channel: agenda/app_privacy is separate from agenda/system_settings"
    - "Native handlers validate the argument type with a safe cast and reply with an error, never interpreting other input"
    - "Boot-time steps each swallow their own faults so one failure cannot skip the next (wipe vs shield)"
    - "Cross-language names pinned by Dart channel tests plus Kotlin/Swift source contracts"

key-files:
  created:
    - lib/domain/lock/secure_window_gateway.dart
    - lib/infrastructure/lock/secure_window_channel.dart
    - test/infrastructure/lock/secure_window_channel_test.dart
  modified:
    - android/app/src/main/kotlin/com/omeu/space/agenda/MainActivity.kt
    - ios/Runner/SceneDelegate.swift
    - ios/Runner/AppDelegate.swift
    - lib/config/startup/app_lock_startup.dart
    - lib/config/di/injection.config.dart
    - lib/main.dart
    - test/config/startup/app_lock_startup_test.dart
    - test/config/di/lock_di_test.dart
    - test/infrastructure/lock/lock_platform_contract_test.dart
    - test/support/lock_fakes.dart

key-decisions:
  - "startAppLock wipe moved into its own guarded helper so the marker early-return and wipe/marker faults never skip the shield when a PIN is configured"
  - "SecureWindowGateway keeps a one-method interface with `// ignore: one_member_abstracts` (same as KindPlanner) so the analyzer count stays at the 64 baseline"
  - "SceneDelegate overrides call super first, per RESEARCH A6; if a Mac build rejects `override`, drop override/super as the compiler directs"

requirements-completed: [DATA-06, DATA-05]

duration: ~45min
completed: 2026-11-16
---

# Phase 5 Plan 10: Native Privacy Shield (FLAG_SECURE + iOS App Switcher Cover) Summary

**Android FLAG_SECURE and an iOS App Switcher cover toggled over one validated `agenda/app_privacy` channel, applied from `startAppLock` before `runApp` whenever a PIN is configured.**

## Performance

- **Duration:** ~45 min (about 20 min of that was the debug APK build)
- **Completed:** 2026-11-16
- **Tasks:** 2 (1 tracer, 1 auto)
- **Files modified:** 13

## Accomplishments

- Dart `SecureWindowChannel.setSecure(enabled:)` reaches `MainActivity`, which adds or clears `WindowManager.LayoutParams.FLAG_SECURE`. Non-Android/iOS platforms, null replies and `PlatformException` all resolve to false.
- Every process start with `pin_configured` true turns the shield on before `runApp`. With no PIN configured the gateway is never called (D-04).
- On iOS, `PrivacyShield.enabled` arms an opaque `.systemBackground` cover. The cover goes up in both `sceneWillResignActive` and `sceneDidEnterBackground` (it is idempotent) and comes down in `sceneDidBecomeActive`, so the App Switcher snapshot does not depend on Flutter painting in time.
- Both native ends reject non-bool arguments (`as? Boolean` / `as? Bool` leading to `bad_args`) (T-05-30).
- `flutter build apk --debug` succeeded (`Built build/app/outputs/flutter-apk/app-debug.apk`), so the Kotlin compiles.

## Task Commits

1. **Task 1 (tracer): setSecure reaches Android FLAG_SECURE, applied at boot** - `920b8e1` (feat)
2. **Task 2: iOS App Switcher cover and the iOS channel end** - `93b187b` (feat)

## Files Created/Modified

- `lib/domain/lock/secure_window_gateway.dart`: the `SecureWindowGateway` interface. It never throws.
- `lib/infrastructure/lock/secure_window_channel.dart`: `appPrivacyChannelName`, `setSecureMethod`, and `@LazySingleton(as: SecureWindowGateway) SecureWindowChannel`.
- `android/.../MainActivity.kt`: a second MethodChannel `agenda/app_privacy` with the `setSecure` handler.
- `ios/Runner/SceneDelegate.swift`: `PrivacyShield` and the cover overrides.
- `ios/Runner/AppDelegate.swift`: `appPrivacyChannel` handler that sets `PrivacyShield.enabled`.
- `lib/config/startup/app_lock_startup.dart`: shield applied at boot when a PIN is configured. The wipe now lives in a guarded helper.
- `lib/config/di/injection.config.dart`: regenerated (SecureWindowGateway -> SecureWindowChannel).
- `lib/main.dart`: doc comment for step 5 now mentions the shield.
- Tests: the new channel test (7 cases plus a name contract), 6 new startup shield tests, a DI resolve test, a Kotlin contract group (4 tests), a Swift contract group (4 tests), and `MockSecureWindowGateway`.

## Decisions Made

- I restructured `startAppLock`. The original returned early when the marker was set, which would have skipped the shield on every launch after the first. The wipe is now `_wipeOnFreshInstall` with its own try. The shield call follows in the outer try, so a marker-write fault still lets the shield apply. A test covers this with a faulting `SharedPreferences`.
- The interface stays one-method and carries `// ignore: one_member_abstracts`, following the existing `KindPlanner` precedent. The analyzer count stays at 64 (cap 65).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Boot shield would be skipped after the first launch**
- **Found during:** Task 1
- **Issue:** The plan says to apply the shield "after the wipe logic". But the existing `startAppLock` `return`s as soon as `secureStorageInitialized` is set, so a literal append would never run on any launch after the first.
- **Fix:** I extracted the wipe into `_wipeOnFreshInstall` (guarded), read `pin_configured` once, and apply the shield afterwards whatever the marker state.
- **Files modified:** lib/config/startup/app_lock_startup.dart
- **Commit:** 920b8e1

**2. [Rule 3 - Blocking] Analyzer info from the new one-method interface**
- **Found during:** Task 1
- **Issue:** `one_member_abstracts` brought the count to 65, right at the cap.
- **Fix:** Added the same `// ignore:` used on `KindPlanner`, which brings the count back to 64.
- **Commit:** 920b8e1

**3. [Doc] lib/main.dart step-5 comment updated** (not in files_modified; comment only).

**Total deviations:** 3 auto-fixed. **Impact:** none on scope. Fix 1 is required for the "every process start" truth.

## Issues Encountered

- The first `flutter build apk --debug` ran inside my own 580 s `timeout` wrapper and was killed (exit 124) during a cold Gradle/Kotlin compile. A rerun without the wrapper succeeded in 439 s.

## Human-needed UAT (Mac / device)

- **iOS App Switcher cover (human_needed, Mac):** build the Runner target. With a PIN enabled (after 05-12), open the App Switcher. The card should show a blank cover, and returning should remove it. This also confirms RESEARCH A6: `FlutterSceneDelegate` scene callbacks are overridable with `super`. If they are not, drop `override`/`super` as the compiler directs.
- **iOS Face ID (human_needed, Mac/device):** biometric unlock on a Face ID device, which needs `NSFaceIDUsageDescription` (05-01).
- **Android FLAG_SECURE (device, 05-14):** with a PIN on, a screenshot and the Recents thumbnail of AGENDA are blank on the Infinix X6831 (RESEARCH A9).

## Verification

- `dart run build_runner build --delete-conflicting-outputs` passed.
- `flutter test --no-pub` passed (1104 tests).
- `flutter analyze --no-fatal-infos --fatal-warnings` reports 64 issues (cap 65).
- `dart run tool/check_architecture.dart` passed.
- `flutter build apk --debug` passed.

## Next Phase Readiness

- 05-12 PinLifecycle can call `getIt<SecureWindowGateway>().setSecure(enabled: ...)` on PIN enable/disable. `MockSecureWindowGateway` is ready for its tests.

## Self-Check: PASSED

- FOUND: lib/domain/lock/secure_window_gateway.dart, lib/infrastructure/lock/secure_window_channel.dart, test/infrastructure/lock/secure_window_channel_test.dart
- FOUND: 920b8e1, 93b187b
