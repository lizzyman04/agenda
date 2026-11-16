---
phase: 05-app-lock-settings-polish
plan: 13
subsystem: ui
tags: [flutter, bloc, settings, app-lock, local_auth, shared_preferences]

requires:
  - phase: 05-06
    provides: AppLockCubit (lazySingleton) with pinEnabled and stream
  - phase: 05-07
    provides: SettingsScreen list, SettingsSectionHeader, RadioGroup dialog pattern
  - phase: 05-11
    provides: DeviceAuthGateway.biometricAvailability / hasDeviceCredential
  - phase: 05-12
    provides: PinSetupScreen(mode) popping bool; PinLifecycle enable/disable
provides:
  - SecuritySettingsCubit/State (application/settings nest)
  - Settings Security section - PIN switch, Change PIN, biometrics toggle, lock timeout
  - showPinDisableDialog, showNoDeviceLockDialog, showLockTimeoutDialog, lockTimeoutLabel
  - SettingsScreen as a stateful owner of the Security cubit with resume refresh
affects: [05-14, verify-work phase 05, UAT SC-3]

actuals:
  tokens: 17200
  tasks: 2
  commits: 2
plan_head_before: fff9122d5770ce486d4a6bf4be475836f63efb33
plan_head_after: 906fed7c42f9248487068b3c8c035ad3cae1488f

tech-stack:
  added: []
  patterns:
    - "Switch value mirrors the source-of-truth cubit (AppLockCubit) via stream subscription; no optimistic flips"
    - "Screen-owned cubit plus WidgetsBindingObserver resume refresh (mirrors NotificationSettingsScreen)"
    - "AlertDialog(scrollable: true) when title+actions alone can overflow at 200% text"

key-files:
  created:
    - lib/application/settings/security_settings_state.dart
    - lib/application/settings/security_settings_cubit.dart
    - lib/application/settings/README.md
    - lib/presentation/settings/security/security_section.dart
    - lib/presentation/settings/security/pin_disable_dialog.dart
    - lib/presentation/settings/security/biometric_tile.dart
    - lib/presentation/settings/security/timeout_dialog.dart
    - lib/presentation/settings/security/no_device_lock_dialog.dart
    - lib/presentation/settings/security/README.md
    - test/application/settings/security_settings_cubit_test.dart
    - test/presentation/settings/security_section_test.dart
  modified:
    - lib/presentation/settings/screens/settings_screen.dart
    - lib/presentation/settings/screens/README.md
    - lib/presentation/settings/README.md
    - lib/config/di/injection.config.dart
    - test/presentation/settings/settings_screen_test.dart
    - test/config/di/lock_di_test.dart

key-decisions:
  - "SecuritySettingsCubit.setBiometricEnabled takes a named bool ({required bool enabled}) instead of the positional bool in the plan interface, because very_good_analysis flags positional booleans and the analyzer budget was at 64 of 65"
  - "Setters emit only after a successful prefs write (guarded); a failed write leaves the screen unchanged"
  - "The cubit re-reads biometric_unlock_enabled whenever AppLockCubit flips pinEnabled, because PinLifecycle.disable removes that key"
  - "A not-enrolled biometrics tile shows OFF (value = enrolled && biometricEnabled) so a disabled switch never looks active"
  - "The timeout dialog uses AlertDialog(scrollable: true) rather than an inner SingleChildScrollView: at 200% text on 320x568 the title and actions alone overflowed by 104 px"

patterns-established:
  - "Settings sections that own preferences put their cubit in lib/application/settings/ and their widgets in lib/presentation/settings/<section>/"
  - "Widget tests drive PinSetupScreen results by registering a MockCubit<PinSetupState> factory in getIt and popping the route with the desired bool"

requirements-completed: [DATA-05, DATA-06, UX-01]

coverage:
  - id: D1
    description: "PIN switch turns the lock on through PIN setup (create) and off through confirm dialog + verify; the switch only reflects AppLockCubit and shows floating SnackBars on success"
    requirement: DATA-05
    verification:
      - kind: automated_ui
        ref: "test/presentation/settings/security_section_test.dart#turning the lock on (create) / turning the lock off (confirm + verify)"
        status: pass
      - kind: unit
        ref: "test/application/settings/security_settings_cubit_test.dart#start loads availability and mirrors a later pinEnabledChanged"
        status: pass
    human_judgment: false
  - id: D2
    description: "Dependent rows shown only while PIN is on (1 row off, 4 enrolled, 4 disabled not-enrolled, 3 no hardware, biometrics absent until resolved); Alterar PIN opens change mode with pinChangedSnack"
    requirement: DATA-06
    verification:
      - kind: automated_ui
        ref: "test/presentation/settings/security_section_test.dart#rows by state (UI Considerations)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Bloquear apos dialog with five options in order, persisting lock_timeout_seconds; scrolls at 200% text"
    verification:
      - kind: automated_ui
        ref: "test/presentation/settings/security_section_test.dart#lock timeout (D-02)"
        status: pass
    human_judgment: false
  - id: D4
    description: "No-device-lock backup warning before PIN creation; Cancel keeps OFF, Continue opens create"
    verification:
      - kind: automated_ui
        ref: "test/presentation/settings/security_section_test.dart#no device screen lock"
        status: pass
    human_judgment: false
  - id: D5
    description: "Settings order General, Security, Notifications, Data, About; resume refreshes biometric availability; language dialog reachable at 200% text; turn-off body wraps in both locales"
    requirement: UX-01
    verification:
      - kind: automated_ui
        ref: "test/presentation/settings/settings_screen_test.dart#Sections (D-10)"
        status: pass
      - kind: automated_ui
        ref: "test/presentation/settings/security_section_test.dart#long text"
        status: pass
    human_judgment: false
  - id: D6
    description: "Real-device biometrics: enrolling a fingerprint in device settings and returning to Settings enables the biometrics switch"
    verification: []
    human_judgment: true
    rationale: "Requires a physical device with local_auth; tests use a mocked DeviceAuthGateway"

duration: 18min
completed: 2026-11-16
status: complete
---

# Phase 5 Plan 13: Settings Security Section Summary

**From Settings > Security the user can now manage the app lock. The PIN switch reflects only AppLockCubit: turning it on goes through PIN setup (create), and turning it off goes through a confirm dialog and then the current PIN (verify). Once the PIN is on, Change PIN, a biometrics toggle that reports device support accurately and refreshes on resume, and a five-option lock timeout appear. Devices without a screen lock get a backup warning before PIN creation.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-11-16T22:42:34Z
- **Completed:** 2026-11-16T23:01:26Z
- **Tasks:** 2
- **Files modified:** 17

## Accomplishments
- `SecuritySettingsCubit`/`State`: seeded from `AppLockCubit` and prefs. Prefs that throw fall back to defaults (PIN off, 1 min, biometrics on). The cubit mirrors `pinEnabled` from the lock stream. Each setter writes first and emits only after a successful write.
- `SecuritySection`: the PIN switch never flips optimistically (T-05-40), and turning the lock off needs the confirm dialog plus verify (T-05-41). The section is placed between General and Notifications (D-10).
- Rows that appear only while the PIN is on: Change PIN, `BiometricTile` (hidden, disabled or a switch, depending on what the device supports) and Lock after with its five-option `RadioGroup` dialog.
- On a device with no screen lock, a "Guarde um backup" warning appears before PIN creation. `SettingsScreen` re-checks biometric availability when the app resumes.

## Task Commits

1. **Task 1: Tracer — Settings PIN switch on via create, off via confirm + verify** - `8d9e979` (feat)
2. **Task 2: Change PIN, biometrics toggle, lock timeout, no-device-lock warning, resume refresh** - `906fed7` (feat)

The tracer feedback gate passed between the two tasks (end-of-phase mode, automated verify re-run: build_runner, tests and analyzer at 64 issues all OK).

## Files Created/Modified
- `lib/application/settings/security_settings_{state,cubit}.dart` - Security section state and cubit
- `lib/presentation/settings/security/security_section.dart` - section rows and flows
- `lib/presentation/settings/security/{pin_disable,no_device_lock,timeout}_dialog.dart` - dialogs
- `lib/presentation/settings/security/biometric_tile.dart` - availability-aware biometrics row
- `lib/presentation/settings/screens/settings_screen.dart` - stateful, owns the cubit, resume refresh (145 lines)
- `lib/config/di/injection.config.dart` - regenerated (`SecuritySettingsCubit` factory)
- READMEs: `application/settings`, `presentation/settings`, `settings/screens`, `settings/security`
- Tests: cubit (10), section (20), settings screen (+2, header order updated), DI (+1)

## Decisions Made
See `key-decisions` in the frontmatter. The two that matter most: the cubit emits only after a successful write, and it re-reads the biometric preference whenever `pinEnabled` flips, because `PinLifecycle.disable` removes that key.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Timeout dialog overflowed at 200% text**
- **Found during:** Task 2 (200% text-scale test)
- **Issue:** With the plan's `SingleChildScrollView` content, the title and actions alone overflowed by 104 px on 320x568, so the last option was unreachable.
- **Fix:** `AlertDialog(scrollable: true)` with the `RadioGroup` as direct content, so the whole dialog scrolls.
- **Files modified:** lib/presentation/settings/security/timeout_dialog.dart
- **Commit:** 906fed7

**2. [Rule 3 - Blocking] Named bool for setBiometricEnabled**
- **Found during:** Task 1
- **Issue:** The positional `bool` in the plan interface triggers `avoid_positional_boolean_parameters` (very_good_analysis), which would have pushed the analyzer to 65, the cap.
- **Fix:** `setBiometricEnabled({required bool enabled})`, matching `NotificationSettingsCubit`.
- **Commit:** 8d9e979

**3. [Rule 3 - Blocking] settings_screen_test registers a SecuritySettingsCubit in getIt (Task 1)**
- **Issue:** The 05-07 screen test pumps `SettingsScreen` without DI, and the screen now resolves its cubit from getIt.
- **Fix:** The test registers a real `SecuritySettingsCubit` (real `AppLockCubit` and a mocked gateway) and resets getIt in tearDown. Committed in Task 1 so the tracer verify stayed green.
- **Commit:** 8d9e979

**Total deviations:** 3 auto-fixed (1 bug, 2 blocking). **Impact:** no scope change. The public surface differs from the interface block only in the named biometric setter.

## Issues Encountered
None.

## Known Stubs
None.

## Verification
- `dart run build_runner build --delete-conflicting-outputs`: exit 0
- `flutter test --no-pub`: 1224 tests, all passed
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, 64 issues (baseline 64, cap 65)
- `dart run tool/check_architecture.dart`: PASS
- All acceptance-criteria greps pass (`SecuritySettingsCubit` in injection.config, `PinSetupMode.verify`, `lockTimeout15m`, `lockBiometricNotEnrolled`, `pinNoDeviceLockTitle`, READMEs present)

## Next Phase Readiness
Ready for 05-14. Checking biometrics on a real device (D6) is left for UAT.

## Self-Check: PASSED
- All 11 created files found on disk; commits 8d9e979 and 906fed7 are ancestors of HEAD.
