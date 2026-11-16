---
phase: 05-app-lock-settings-polish
plan: 11
subsystem: auth
tags: [local_auth, biometrics, app-lock, bloc, excursion-guard, injectable]

requires:
  - phase: 05-01
    provides: local_auth 3.0.1 + local_auth_android pins, confirmed API names, biometric ARB keys
  - phase: 05-03
    provides: StorageKeys.biometricUnlockEnabled, PinVerifier.resetAttempts
  - phase: 05-06
    provides: PinKeypad.leading slot, KeypadIconKey
  - phase: 05-08
    provides: ExcursionGuard.run (ExcursionGuardImpl)
  - phase: 05-09
    provides: LockScreenCubit cooldown, LockScreenState
provides:
  - DeviceAuthGateway contract (BiometricAvailability, DeviceAuthResult, DeviceAuthPrompt)
  - LocalAuthGateway over local_auth 3.0.1, every prompt inside ExcursionGuard.run
  - InfrastructureModule.localAuthentication singleton
  - LockDeviceAuth (biometricOffered, unlockWithBiometrics)
  - LockScreenCubit.requestBiometric / autoPromptBiometric, LockScreenState.biometricOffered
  - BiometricKey and the D-08 auto-prompt in LockScreen
  - LockCountdown (cooldown ticker) and core/utils guarded()
  - Test fakes MockDeviceAuthGateway, MockLocalAuthentication, MockLockDeviceAuth, fakeAuthPrompt, pinOnlyDeviceAuth()
affects: [05-12, 05-13, 05-14, settings-security, forgot-pin]

actuals:
  tokens: 12216
  tasks: 2
  commits: 2
plan_head_before: 218f3fed4c4c8ab5939cf7577b994ecab43535bd
plan_head_after: 9d3affb4f7ea37382179cdd439fc987c3ad6b605

tech-stack:
  added: []
  patterns:
    - "Plugin seam: domain DeviceAuthGateway + infrastructure LocalAuthGateway, the only class touching local_auth"
    - "guarded(action, fallback) for fail-closed callers: any sync or async throw becomes a known safe value"
    - "Lifecycle-gated one-shot: post-frame callback acts only when lifecycleState == resumed, else an AppLifecycleListener waits for the next resumed"

key-files:
  created:
    - lib/domain/lock/device_auth_gateway.dart
    - lib/infrastructure/lock/local_auth_gateway.dart
    - lib/application/lock/lock_device_auth.dart
    - lib/application/lock/lock_countdown.dart
    - lib/core/utils/guarded.dart
    - lib/presentation/lock/keypad/biometric_key.dart
    - test/infrastructure/lock/local_auth_gateway_test.dart
    - test/application/lock/app_lock_biometric_test.dart
    - test/presentation/lock/lock_screen_biometric_test.dart
  modified:
    - lib/application/lock/lock_screen_cubit.dart
    - lib/application/lock/lock_screen_state.dart
    - lib/presentation/lock/screens/lock_screen.dart
    - lib/config/di/infrastructure_module.dart
    - lib/config/di/injection.config.dart
    - lib/application/lock/README.md
    - lib/presentation/lock/keypad/README.md
    - lib/presentation/lock/screens/README.md
    - test/support/lock_fakes.dart
    - test/config/di/lock_di_test.dart
    - test/application/lock/lock_screen_cubit_test.dart
    - test/application/lock/lock_screen_cooldown_test.dart
    - test/presentation/lock/lock_screen_test.dart
    - test/presentation/lock/lock_gate_cover_test.dart
    - test/presentation/lock/lock_gate_lifecycle_test.dart

key-decisions:
  - "sensitiveTransaction is false for the biometric unlock (skips Android's face-unlock confirm tap, RESEARCH A5); true for device-credential prompts. Reversible; revisit in UAT"
  - "persistAcrossBackgrounding is left at its default false rather than passed explicitly (very_good_analysis avoid_redundant_argument_values); the test pins the value"
  - "Every LocalAuthExceptionCode not listed in the plan (authInProgress, uiUnavailable, deviceError, unknownError, biometricHardwareTemporarilyUnavailable) maps to cancelled: a silent fallback to the keypad"
  - "Biometric success resets the D-07 counter best-effort: a failing resetAttempts still unlocks, because identity is already proven"
  - "To keep LockScreenCubit at 150 lines, the cooldown ticker moved to LockCountdown and the PIN rejection message to rejectionMessage() in lock_screen_state.dart; try/catch blocks became core/utils guarded()"

patterns-established:
  - "Lock-screen cubit tests built before 05-11 use pinOnlyDeviceAuth() as the third constructor argument"
  - "Widget tests that depend on the auto-prompt must set AppLifecycleState.resumed first: the test binding starts with no lifecycle state"

requirements-completed: [DATA-06]

coverage:
  - id: D1
    description: "LocalAuthGateway maps true/false and every LocalAuthExceptionCode to DeviceAuthResult (only true is success), maps availability, and runs each prompt inside the excursion guard with localized Android messages"
    requirement: DATA-06
    verification:
      - kind: unit
        ref: "test/infrastructure/lock/local_auth_gateway_test.dart"
        status: pass
    human_judgment: false
  - id: D2
    description: "LockDeviceAuth offers biometrics when (preference ?? true) and enrolled; LockScreenCubit unlocks only on success (after resetAttempts), hides the key on unavailable, ignores cancel/lockout, auto-prompts once, works in cooldown"
    requirement: DATA-06
    verification:
      - kind: unit
        ref: "test/application/lock/app_lock_biometric_test.dart"
        status: pass
    human_judgment: false
  - id: D3
    description: "DeviceAuthGateway resolves as a single LocalAuthGateway; LocalAuthentication is a singleton"
    verification:
      - kind: unit
        ref: "test/config/di/lock_di_test.dart"
        status: pass
    human_judgment: false
  - id: D4
    description: "Lock screen biometric key (fingerprint/face icon, tooltip, empty slot when not offered, enabled in cooldown) and the lifecycle-gated auto-prompt"
    requirement: DATA-06
    verification:
      - kind: automated_ui
        ref: "test/presentation/lock/lock_screen_biometric_test.dart"
        status: pass
    human_judgment: false
  - id: D5
    description: "On a real Android device the fingerprint prompt opens by itself with Portuguese title and 'Usar PIN'; the sensor unlocks; cancelling shows the keypad"
    requirement: DATA-06
    verification: []
    human_judgment: true
    rationale: "BiometricPrompt needs real biometric hardware; host tests mock local_auth (Task 2 human-check, harvested at end of phase)"

duration: 20min
completed: 2026-11-16
status: complete
---

# Phase 5 Plan 11: Biometric Unlock on the Lock Screen Summary

**The lock screen opens the OS biometric prompt by itself once per lock episode (only while the app is resumed), and a fingerprint or face unlocks the app and resets the attempt counter. This goes through a LocalAuthGateway over local_auth 3.0.1 that runs inside the excursion guard, and a platform-icon BiometricKey on the keypad.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-11-16T21:48:59Z
- **Completed:** 2026-11-16T22:09:28Z
- **Tasks:** 2
- **Files modified:** 24 (9 created, 15 modified)

## Accomplishments
- `DeviceAuthGateway` domain contract and `LocalAuthGateway`. Every `authenticate` runs inside `ExcursionGuard.run` and uses localized `AndroidAuthMessages`. Only a `true` answer is `success`. Every `LocalAuthException` code maps to `cancelled`, `unavailable`, `noDeviceCredential` or `lockedOut`, and any other throw maps to `cancelled` (T-05-33).
- `LockDeviceAuth`: biometrics are offered when `biometricUnlockEnabled ?? true` holds (a throw counts as absent) and the device has enrolled biometrics. `unlockWithBiometrics` never throws.
- `LockScreenCubit` takes `LockDeviceAuth`.
  - `requestBiometric`: success awaits `resetAttempts()` and then calls `unlock()`. `unavailable` hides the key. Any other result changes nothing. It works during a cooldown and is ignored while a PIN is being verified.
  - `autoPromptBiometric`: runs at most once per cubit.
- `LockScreen`: after `start()` and a post-frame callback, it prompts only when `lifecycleState == resumed`. Otherwise an `AppLifecycleListener` waits for the next `resumed` (Pitfall 10).
- `BiometricKey` (fingerprint on Android, face on iOS, size 32, `cs.primary`, tooltip `lockBiometricToggle`) goes in `PinKeypad.leading` only when biometrics are offered. Otherwise the slot is an empty 72 dp box.

## Task Commits

1. **Task 1: Tracer: the lock screen opens the biometric prompt by itself and a successful check unlocks** - `9d077c6` (feat)
2. **Task 2: The biometric key on the keypad, cancel falls back to the keypad, platform icon** - `9d3affb` (feat)

Tracer feedback gate: interactive run, `end-of-phase` mode, Task 1 `<verify>` is automated-only. I re-ran `build_runner build && flutter test --no-pub test/infrastructure/lock test/application/lock test/config/di && flutter analyze` (all green, 64 issues) before expanding.

## Files Created/Modified
- `lib/domain/lock/device_auth_gateway.dart`: `BiometricAvailability`, `DeviceAuthResult`, `DeviceAuthPrompt`, `DeviceAuthGateway`
- `lib/infrastructure/lock/local_auth_gateway.dart`: `LocalAuthGateway` and `mapLocalAuthCode`
- `lib/config/di/infrastructure_module.dart`: `@lazySingleton LocalAuthentication`
- `lib/application/lock/lock_device_auth.dart`: offer check and biometric-only unlock
- `lib/application/lock/lock_screen_cubit.dart`: biometric paths; 150 lines
- `lib/application/lock/lock_screen_state.dart`: `biometricOffered`, `LockScreenState.entry`, `rejectionMessage`
- `lib/application/lock/lock_countdown.dart`: the D-07 cooldown ticker, extracted from the cubit
- `lib/core/utils/guarded.dart`: `guarded(action, fallback)`, turns a throw into a fallback value
- `lib/presentation/lock/keypad/biometric_key.dart`: `BiometricKey`
- `lib/presentation/lock/screens/lock_screen.dart`: prompt from l10n, lifecycle-gated auto-prompt, leading key
- Three READMEs: new files and the rule "biometrics are an alternative path; the keypad is always available"
- Tests: gateway mapping table (all 14 codes, plus a check that the table covers the enum), guard active in-flight, availability, cubit biometric paths, DI graph, widget tests for key and auto-prompt

## Decisions Made
See `key-decisions` in the frontmatter. In short:
- `sensitiveTransaction: false` for the unlock prompt (A5).
- The default `persistAcrossBackgrounding: false` is pinned by the test rather than passed explicitly.
- Unlisted error codes cause a silent fallback to the keypad.
- Resetting the attempt counter after a biometric success is best-effort.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Existing tests constructed LockScreenCubit with two positional arguments**
- **Found during:** Task 1
- **Issue:** The new third constructor parameter (`LockDeviceAuth`) broke five existing test files.
- **Fix:** Added a `pinOnlyDeviceAuth()` helper to `lock_fakes.dart`, a mock that never offers biometrics, and passed it at each call site. Behaviour is unchanged.
- **Files modified:** test/application/lock/lock_screen_cubit_test.dart, lock_screen_cooldown_test.dart, test/presentation/lock/lock_screen_test.dart, lock_gate_cover_test.dart, lock_gate_lifecycle_test.dart
- **Committed in:** 9d077c6

**2. [Rule 3 - Blocking] The 150-line cap needed two extra files**
- **Found during:** Task 1
- **Issue:** The plan's suggested split (moving the outcome-to-state mapping into `lock_screen_state.dart`) still left the cubit at about 168 lines.
- **Fix:** Did the suggested move (`rejectionMessage`, `LockScreenState.entry`). Also extracted the cooldown ticker into `lib/application/lock/lock_countdown.dart`, and the repeated try/catch fallbacks into `lib/core/utils/guarded.dart`. Neither file is in the plan's `files_modified`. Cooldown behaviour is unchanged: the existing cooldown tests pass unmodified apart from the constructor.
- **Files modified:** lib/application/lock/lock_countdown.dart, lib/core/utils/guarded.dart
- **Committed in:** 9d077c6

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Structure only, with no scope change. Every new file is under the cap and the architecture guard passes.

## Issues Encountered
- The Flutter test binding starts with no `lifecycleState`, so the auto-prompt (which requires `resumed`) did not fire in widget tests until the tests marked the app resumed. This is the intended production behaviour. The tests set `resumed` explicitly, and the "starts inactive" case covers the waiting path.

## Verification
- `dart run build_runner build --delete-conflicting-outputs`: exit 0
- `flutter test --no-pub` (full suite): 1154 passed
- `flutter analyze --no-fatal-infos --fatal-warnings`: 64 issues (baseline 64, cap 65); none in touched files
- `dart run tool/check_architecture.dart`: PASS
- Acceptance greps: `_guard.run` 1, `AndroidAuthMessages` 1, `LocalAuthGateway` in injection.config 1, `Icons.face` in biometric_key 2, cubit 150 lines

## User Setup Required
None. No external service configuration is required.

## Next Phase Readiness
- 05-12 (forgot PIN, settings) can use `DeviceAuthGateway.authenticate(prompt, biometricOnly: false)` and `hasDeviceCredential()`. `noDeviceCredential` signals the forgot-unavailable dialog.
- Device UAT (end of phase): the fingerprint prompt on the Infinix test device, its Portuguese sheet text, cancelling back to the keypad, and whether A5 (`sensitiveTransaction: false`) needs revisiting for face unlock.

---
*Phase: 05-app-lock-settings-polish*
*Completed: 2026-11-16*

## Self-Check: PASSED

All 9 created files exist; commits 9d077c6 and 9d3affb are ancestors of HEAD.
