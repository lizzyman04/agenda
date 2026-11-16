---
phase: 05-app-lock-settings-polish
plan: 01
subsystem: infra
tags: [local_auth, local_auth_android, flutter_secure_storage, crypto, android-manifest, appcompat, info-plist, l10n, arb]

requires:
  - phase: 04-notifications-backup
    provides: "manifest/pubspec source-text contract pattern, ARB conventions, ICU plural 'one' interpolates the count"
provides:
  - "Exact pins crypto 3.0.7, flutter_secure_storage 10.0.0, local_auth 3.0.1, local_auth_android 2.0.8"
  - "USE_BIOMETRIC permission and AppCompat LaunchTheme/NormalTheme (light and night)"
  - "NSFaceIDUsageDescription (English) in ios/Runner/Info.plist"
  - "Every Phase 5 ARB key (65 new) plus the D-12 privacyStatement value, generated getters"
  - "Confirmed API names table for plans 05-03, 05-10, 05-11"
  - "First release build of the project: app-release.apk builds"
affects: [05-03, 05-04, 05-10, 05-11, 05-14, app-lock, settings, privacy-statement]

actuals:
  tokens: 21287
  tasks: 2
  commits: 2
plan_head_before: 94a83b7cf5132a11c0cbcae9481f99cd093ef1fd
plan_head_after: cb0dad8956feea66e4cb072489b0b9fb6fe1aada

tech-stack:
  added: [crypto 3.0.7 (promoted to direct), flutter_secure_storage 10.0.0, local_auth 3.0.1, local_auth_android 2.0.8]
  patterns:
    - "Phase 5 platform contract test: source-text pins + compile-only API smoke against real plugin symbols"
    - "ARB keys appended by script to all three files so app_pt.arb stays byte-identical to app_pt_BR.arb apart from @@locale"

key-files:
  created:
    - test/infrastructure/lock/lock_platform_contract_test.dart
    - test/l10n/phase5_strings_test.dart
  modified:
    - pubspec.yaml
    - android/app/src/main/AndroidManifest.xml
    - android/app/src/main/res/values/styles.xml
    - android/app/src/main/res/values-night/styles.xml
    - ios/Runner/Info.plist
    - lib/config/l10n/app_pt_BR.arb
    - lib/config/l10n/app_pt.arb
    - lib/config/l10n/app_en.arb
    - lib/generated/l10n/app_localizations.dart
    - lib/generated/l10n/app_localizations_en.dart
    - lib/generated/l10n/app_localizations_pt.dart

key-decisions:
  - "values-night LaunchTheme/NormalTheme use Theme.AppCompat.NoActionBar (dark launch window kept); values/ use Theme.AppCompat.Light.NoActionBar"
  - "lockWrongPin 'one' branch interpolates {remaining} (Phase 4 convention) instead of the UI-SPEC literal 1; rendered text is identical"
  - "Smoke test constructs AndroidOptions() explicitly with a lint ignore, because resetOnError defaults to true in 10.0.0 (Pitfall 5) and later plans must see that"

patterns-established:
  - "API smoke tests compare a plugin method tear-off against an explicit function type with isA<...>() to pin named parameters without calling the platform channel"

requirements-completed: [DATA-05, DATA-06, UX-01, UX-03]

coverage:
  - id: D1
    description: "Phase 5 packages pinned exactly; no network package; flutter_screen_lock commented"
    requirement: DATA-05
    verification:
      - kind: unit
        ref: "test/infrastructure/lock/lock_platform_contract_test.dart#platform contract"
        status: pass
      - kind: other
        ref: "flutter pub get"
        status: pass
    human_judgment: false
  - id: D2
    description: "Android biometric setup (USE_BIOMETRIC, AppCompat themes light+night), FlutterFragmentActivity kept, Face ID usage string"
    requirement: DATA-06
    verification:
      - kind: unit
        ref: "test/infrastructure/lock/lock_platform_contract_test.dart#platform contract"
        status: pass
      - kind: other
        ref: "flutter build apk --release"
        status: pass
    human_judgment: false
  - id: D3
    description: "Real local_auth / local_auth_android / flutter_secure_storage / crypto APIs compile and behave on the VM"
    requirement: DATA-06
    verification:
      - kind: unit
        ref: "test/infrastructure/lock/lock_platform_contract_test.dart#API smoke"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every Phase 5 string in all three ARB files with plurals, placeholders, D-12 headline, D-13 bullets, endonyms, 'aparelho' rule"
    requirement: UX-03
    verification:
      - kind: unit
        ref: "test/l10n/phase5_strings_test.dart"
        status: pass
      - kind: unit
        ref: "test/l10n/l10n_test.dart#ARB parity"
        status: pass
    human_judgment: false
  - id: D5
    description: "PT-BR and EN copy reads naturally to a native speaker"
    requirement: UX-01
    verification: []
    human_judgment: true
    rationale: "Tone and fluency of the copy cannot be asserted by a test; strings are copied verbatim from the UI-SPEC"

duration: 153min
completed: 2026-11-16
status: complete
---

# Phase 5 Plan 01: Dependencies, Platform Setup and Strings Summary

**local_auth 3.0.1, local_auth_android 2.0.8, flutter_secure_storage 10.0.0 and crypto 3.0.7 pinned and compiling, Android BiometricPrompt made safe with USE_BIOMETRIC and AppCompat themes, Face ID usage string added, all 65 Phase 5 ARB keys generated, and the project's first release APK built.**

## Performance

- **Duration:** 153 min wall clock. This includes a ~23 min Gradle release build and a session interruption from a transient network error (ENOTFOUND) before the commits.
- **Started:** 2026-11-16T15:54:29Z
- **Completed:** 2026-11-16T18:27:56Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments
- Four exact pins resolve on Flutter 3.41.4 (`flutter pub get` exit 0). Resolved alongside them: `flutter_secure_storage_darwin` 0.2.0, `local_auth_darwin` 2.0.5, `local_auth_platform_interface` 1.1.0. `flutter_screen_lock` stays on one commented line marked NOT USED.
- `USE_BIOMETRIC` declared. `LaunchTheme` and `NormalTheme` now inherit `Theme.AppCompat.Light.NoActionBar` (values/) and `Theme.AppCompat.NoActionBar` (values-night/). Every `item` element is unchanged.
- `NSFaceIDUsageDescription` = "AGENDA uses Face ID to unlock the app instead of the PIN." (English only, user decision 4).
- **First release build:** `flutter build apk --release` exited 0 and produced `build/app/outputs/flutter-apk/app-release.apk` (64.4 MB). The Gradle `assembleRelease` step took 1368.6 s and logged no warnings or errors. AppCompat resolved through `androidx.biometric`, as RESEARCH Pitfall 9 predicted.
- 65 new ARB keys in all three files. `app_pt.arb` is byte-identical to `app_pt_BR.arb` except `@@locale`. `privacyStatement` now reads "Seus dados nunca saem deste aparelho" / "Your data never leaves this device".

## Confirmed API names

All names below were read from the pub cache source and compiled in `lock_platform_contract_test.dart`. They match the research text, so no correction was needed.

| API | Confirmed shape |
|-----|-----------------|
| `LocalAuthentication.authenticate` | `Future<bool> authenticate({required String localizedReason, Iterable<AuthMessages> authMessages = const [IOSAuthMessages(), AndroidAuthMessages(), WindowsAuthMessages()], bool biometricOnly = false, bool sensitiveTransaction = true, bool persistAcrossBackgrounding = false})` |
| Other `LocalAuthentication` members | `stopAuthentication()`, `Future<bool> get canCheckBiometrics`, `isDeviceSupported()`, `getAvailableBiometrics()` |
| `package:local_auth/local_auth.dart` exports | only `LocalAuthentication`, `BiometricType`, `LocalAuthException`, `LocalAuthExceptionCode` |
| `LocalAuthException` | `const LocalAuthException({required LocalAuthExceptionCode code, String? description, Object? details})` |
| `LocalAuthExceptionCode` values | `authInProgress, uiUnavailable, userCanceled, timeout, systemCanceled, noCredentialsSet, noBiometricsEnrolled, noBiometricHardware, biometricHardwareTemporarilyUnavailable, temporaryLockout, biometricLockout, userRequestedFallback, deviceError, unknownError` |
| `AndroidAuthMessages` (`package:local_auth_android/local_auth_android.dart`) | `const AndroidAuthMessages({String? signInHint, String? cancelButton, String? signInTitle})`; is an `AuthMessages`. That library also re-exports `AuthMessages`, `AuthenticationOptions`, `BiometricType` |
| `FlutterSecureStorage` | `const FlutterSecureStorage({aOptions, iOptions, ...})`; `write({required key, required value})`, `read({required key})`, `delete({required key})`, `deleteAll()`, `static setMockInitialValues(Map<String, String>)` |
| `AndroidOptions` | `const AndroidOptions({...})`, `resetOnError` defaults to **true**; `AndroidOptions.defaultOptions` is the same object (lint `use_named_constants` prefers it) |
| `IOSOptions` | `const IOSOptions({accountName, groupId, accessibility, synchronizable, label, description, ...})` |
| `KeychainAccessibility` values | `passcode, unlocked, unlocked_this_device, first_unlock, first_unlock_this_device` |
| `Hmac` / `sha256` (`package:crypto/crypto.dart`) | `Hmac(sha256, List<int> key).convert(List<int>) -> Digest` (32 bytes). HMAC-SHA256("k","m") = `b60090e3…e771ec`, matches Python `hmac` |

## Task Commits

1. **Task 1: Tracer: dependencies, Android biometric setup, API smoke** - `5e07a1f` (feat)
2. **Task 2: Every Phase 5 string in all three ARB files** - `cb0dad8` (feat)

Tracer feedback gate: interactive run, `end-of-phase` mode, automated-only `<verify>`. Re-ran `flutter pub get && flutter test --no-pub test/infrastructure/lock/lock_platform_contract_test.dart` (11/11 green) before expanding.

## Files Created/Modified
- `pubspec.yaml` - four Phase 5 pins in alphabetical position; Phase 5 comment block rewritten
- `android/app/src/main/AndroidManifest.xml` - `USE_BIOMETRIC`
- `android/app/src/main/res/values/styles.xml`, `values-night/styles.xml` - AppCompat parents
- `ios/Runner/Info.plist` - `NSFaceIDUsageDescription`
- `lib/config/l10n/app_pt_BR.arb`, `app_pt.arb`, `app_en.arb` - 65 keys + privacyStatement value
- `lib/generated/l10n/*` - regenerated getters
- `test/infrastructure/lock/lock_platform_contract_test.dart` - platform contract + API smoke (11 tests)
- `test/l10n/phase5_strings_test.dart` - Phase 5 string checks in both locales

## Decisions Made
- Night styles use `Theme.AppCompat.NoActionBar` so the launch window stays dark in OS dark mode.
- `lockWrongPin`'s `one` branch interpolates `{remaining}` (Phase 4 convention). The output is still "Resta 1 tentativa" / "1 attempt left", and the test pins the exact text at 1, 2 and 4.
- The smoke test keeps `AndroidOptions()` explicit, with an `// ignore:` comment, so later plans see the `resetOnError = true` default.

## Deviations from Plan

None. The plan executed as written. Two fixes were made to my own new test code before commit and are not plan deviations: a `Locale`-keyed const map that did not compile, and five lint infos on the contract test. Analyze stays at 64 issues.

## Issues Encountered
- The session died on a transient network error (ENOTFOUND) after Task 1's edits and the release build, before any commit. The coordinator resumed it, the on-disk work was checked again, and both tasks were then committed.
- Commits land on `main`. The executor's protected-branch guard flagged `main`. The coordinator confirmed that this project commits directly to `main` (`git.branching_strategy: "none"`, and every prior phase is on `main`).
- `.planning/milestone.lock` was not touched by this executor. It is present on disk, and it does not show in `git status` because git ignores it.

## Known Stubs
None.

## User Setup Required
None. The iOS PT-BR `InfoPlist.strings` stays deferred to a Mac session (user decision 4).

## Next Phase Readiness
- Plans 05-02 onward can import `local_auth`, `local_auth_android`, `flutter_secure_storage` and `crypto` and use every Phase 5 l10n getter. No later plan needs to edit pubspec, the manifest, the styles, Info.plist or the ARB files.
- The release build works, so 05-04 and 05-14 can re-run it as a regression check.

---
*Phase: 05-app-lock-settings-polish*
*Completed: 2026-11-16*

## Self-Check: PASSED
