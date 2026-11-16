---
phase: 05-app-lock-settings-polish
plan: 12
subsystem: auth
tags: [app-lock, pin, bloc, local_auth, secure-storage, injectable, forgot-pin]
status: complete

requires:
  - phase: 05-03
    provides: PinHasher, PinStore (SecurePinStore), PinVerifier with the persisted D-07 ladder
  - phase: 05-06
    provides: AppLockCubit.unlock / pinEnabledChanged, PinKeypad, PinDots
  - phase: 05-09
    provides: LockMessage, LockStatusLine, the lock-screen cooldown
  - phase: 05-10
    provides: SecureWindowGateway.setSecure
  - phase: 05-11
    provides: DeviceAuthGateway, LockDeviceAuth, LockCountdown, guarded()
provides:
  - PinLifecycle (enable / change / disable / reset with the safe write order)
  - PinSetupMode / PinSetupStep / PinSetupPhase / PinSetupState / PinSetupCubit
  - CooldownTicker (renamed from LockCountdown) shared by both keypad cubits
  - MismatchMessage rendered as pinMismatch in LockStatusLine
  - PinSetupScreen(mode) that pops true on success, false on cancel; reset mode unlocks
  - LockDeviceAuth.hasDeviceCredential / confirmDeviceCredential / confirmForgotPin
  - LockScreenCubit.confirmForgotPin
  - ForgotPinButton + lockAuthPrompt on the lock screen; showForgotPinUnavailableDialog
  - MockPinLifecycle test fake
affects: [05-13, 05-14, settings-security]

estimate:
  tokens: 72000
  tasks: 3
actuals:
  tokens: 17091
  tasks: 3
  commits: 3
plan_head_before: 88f4bda88e3e2f9bb240bff4fa2f493e96bfbdcc
plan_head_after: ee52c72c7b0c36a92f71e62b3f602f92a4aa9047

tech-stack:
  added: []
  patterns:
    - "Write-order invariant: the non-secret flag is written LAST on enable (rolled back on failure) and FIRST on disable"
    - "Setup flows keep digits and the first PIN entry in private cubit fields; state carries counts only"
    - "The lock screen injects the reset destination into ForgotPinButton, so the push stays on the lock layer's Navigator"

key-files:
  created:
    - lib/application/lock/setup/pin_lifecycle.dart
    - lib/application/lock/setup/pin_setup_state.dart
    - lib/application/lock/setup/pin_setup_cubit.dart
    - lib/application/lock/setup/README.md
    - lib/application/lock/cooldown_ticker.dart
    - lib/presentation/lock/screens/pin_setup_screen.dart
    - lib/presentation/lock/screens/forgot_pin_button.dart
    - lib/presentation/lock/screens/forgot_pin_dialog.dart
    - test/application/lock/pin_lifecycle_test.dart
    - test/application/lock/pin_setup_cubit_test.dart
    - test/presentation/lock/pin_setup_screen_test.dart
    - test/presentation/lock/forgot_pin_test.dart
  modified:
    - lib/application/lock/lock_screen_state.dart
    - lib/application/lock/lock_screen_cubit.dart
    - lib/application/lock/lock_device_auth.dart
    - lib/application/lock/README.md
    - lib/presentation/lock/keypad/lock_status_line.dart
    - lib/presentation/lock/screens/lock_screen.dart
    - lib/presentation/lock/screens/README.md
    - lib/presentation/lock/README.md
    - lib/config/di/injection.config.dart
    - test/config/di/lock_di_test.dart
    - test/support/lock_fakes.dart
  deleted:
    - lib/application/lock/lock_countdown.dart (renamed to cooldown_ticker.dart)

key-decisions:
  - "PinSetupPhase gained a coolingDown value (the contract listed entering/verifying/saving/done) so the keypad disables during a D-07 cooldown exactly like the lock screen"
  - "LockCountdown from 05-11 was renamed to CooldownTicker with onTick/onDone callbacks instead of adding a second ticker"
  - "The forgot-PIN branching (no screen lock -> noDeviceCredential, else the device-credential prompt) lives in LockDeviceAuth.confirmForgotPin; LockScreenCubit.confirmForgotPin delegates to it, keeping the cubit at the 150-line cap"
  - "The forgot-PIN button and its flow live in forgot_pin_button.dart; LockScreen passes PinSetupScreen(mode: PinSetupMode.reset) as resetPage, so the lock screen stays at 150 lines"
  - "System back on PinSetupScreen pops false (cancel) instead of null; reset mode ignores back"

patterns-established:
  - "PinSetupState.initial(mode) / ask(step) / busy(phase) / cooling(left, tick) helpers keep the cubit's emits one line each"

requirements-completed: [DATA-05, DATA-06]

duration: 18min
completed: 2026-11-16
---

# Phase 5 Plan 12: PIN Lifecycle, Setup Screen and Forgot PIN Summary

**You can now create, change, turn off and reset the PIN. Creating takes a 4-digit PIN plus a confirmation, and the lock's on/off flag is written last so a failure can never leave the lock half on. "Esqueci meu PIN" checks the device screen lock, then lets you set a new PIN without losing any data. On a device with no screen lock it explains the recovery and keeps the app locked.**

## Performance

- **Duration:** about 18 min
- **Started:** 2026-11-16T22:17:45Z
- **Completed:** 2026-11-16T22:36:10Z
- **Tasks:** 3
- **Files modified:** 23 (one of them a rename)

## Accomplishments

- `PinLifecycle` writes in a safe order:
  - **Enable:** saves the PIN record and clears attempts, turns on window privacy, then writes `pin_configured = true` last. If that last write fails, it clears the store and turns window privacy back off.
  - **Disable:** writes the flag off first, then turns off window privacy, clears the PIN store and removes `biometric_unlock_enabled`.
  - **Change and reset:** write the new record and clear the attempt counter.
- `PinSetupCubit` handles all four modes: create, change, verify-to-disable and reset. A confirmation that doesn't match shows `MismatchMessage`, shakes the dots and goes back to the create step. The current-PIN step uses the same `PinVerifier` and saved attempt counter as the lock screen, cooldown included.
- `PinSetupScreen(mode)`:
  - **Layout:** the step title cross-fades over 150 ms. There is no biometric key and no forgot button.
  - **AppBar:** the title depends on the mode, and a close button pops `false`.
  - **Reset mode:** no AppBar and back does nothing. When done it unlocks the app and shows a floating `pinChangedSnack`.
- Forgot PIN on the lock screen:
  - **Device check:** uses the device credential (`biometricOnly: false`, reason `lockForgotReason`).
  - **Success:** opens reset mode on the lock layer's own Navigator.
  - **No screen lock:** shows the `lockForgotUnavailable*` dialog with one `lockGotIt` button, and the app stays locked.
  - **Cancel or error:** silently returns to the keypad.
  - **Cooldown:** the button stays enabled during a cooldown.

## Task Commits

1. **Task 1 (tracer): create a PIN with confirmation; the next cold start is locked** - `ccebc3e` (feat)
2. **Task 2: change, verify-to-disable and reset modes with the shared counter and cooldown** - `50b3fbf` (feat)
3. **Task 3: "Esqueci meu PIN" via the device credential, the unavailable dialog, fail-closed recovery** - `ee52c72` (feat)

**Tracer gate:** after Task 1 I re-ran its automated `<verify>` (build_runner, the lock test folders, analyze, the architecture guard) and it passed, so I continued to Task 2.

## Files Created/Modified

- `lib/application/lock/setup/` (new nest): `pin_lifecycle.dart`, `pin_setup_state.dart`, `pin_setup_cubit.dart`, `README.md`.
- `lib/application/lock/cooldown_ticker.dart`: `CooldownTicker`, renamed from `lock_countdown.dart`.
- `lib/application/lock/lock_screen_cubit.dart`: uses `CooldownTicker`; adds `confirmForgotPin`.
- `lib/application/lock/lock_device_auth.dart`: adds `hasDeviceCredential`, `confirmDeviceCredential` and `confirmForgotPin`.
- `lib/application/lock/lock_screen_state.dart`: adds `MismatchMessage`.
- `lib/presentation/lock/keypad/lock_status_line.dart`: shows `MismatchMessage` as `pinMismatch` in `cs.error`.
- `lib/presentation/lock/screens/pin_setup_screen.dart`, `forgot_pin_button.dart`, `forgot_pin_dialog.dart`: new.
- `lib/presentation/lock/screens/lock_screen.dart`: 24 gap plus `ForgotPinButton`; builds its prompt with `lockAuthPrompt`.
- `lib/config/di/injection.config.dart`: regenerated (`PinLifecycle` lazySingleton, `PinSetupCubit` factory).
- READMEs updated: `application/lock`, `application/lock/setup`, `presentation/lock`, `presentation/lock/screens`.
- Tests: `pin_lifecycle_test`, `pin_setup_cubit_test`, `pin_setup_screen_test`, `forgot_pin_test`, plus additions to `lock_di_test` and `lock_fakes` (`MockPinLifecycle`).

## Decisions Made

See `key-decisions` in the frontmatter. In short:
- **New cooldown phase:** `PinSetupPhase` gained a `coolingDown` value.
- **One ticker:** `LockCountdown` became the shared `CooldownTicker`.
- **Forgot-PIN logic:** the branching lives in `LockDeviceAuth.confirmForgotPin`.
- **Reset destination:** the lock screen passes the reset-mode `PinSetupScreen` into `ForgotPinButton`.
- **System back = cancel:** system back on the setup screen counts as a cancel and returns `false`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Renamed the 05-11 `LockCountdown` instead of extracting a new ticker**
- **Found during:** Task 2
- **Issue:** The plan says to extract a `Timer.periodic` from `LockScreenCubit`, but 05-11 had already moved it into `lock_countdown.dart` (`LockCountdown`).
- **Fix:** Renamed it with `git mv` to `cooldown_ticker.dart` / `CooldownTicker`, using the `start(attempts, {onTick, onDone})` signature from the plan. `LockScreenCubit` now uses it with no behaviour change, and `lock_screen_cooldown_test.dart` passes unchanged.
- **Files modified:** `lib/application/lock/cooldown_ticker.dart`, `lib/application/lock/lock_screen_cubit.dart`
- **Commit:** 50b3fbf

**2. [Rule 3 - Blocking] Stayed under the 150-line limit set by `tool/check_architecture.dart`**
- **Found during:** Tasks 2 and 3
- **Issue:** `pin_setup_cubit.dart`, `lock_screen_cubit.dart` and `lock_screen.dart` would have gone over 150 lines.
- **Fix:**
  - Moved state-building helpers (`initial`, `ask`, `busy`, `cooling`) into `PinSetupState`.
  - Put the forgot-PIN decision in `LockDeviceAuth.confirmForgotPin`; the cubit just delegates.
  - Moved the forgot-PIN button and flow into a new `forgot_pin_button.dart`, which also shares a `lockAuthPrompt` helper with the biometric prompt.
  - Made small comment cuts in `LockScreenCubit`.
- **Result:** `lock_screen.dart` still contains `PinSetupMode.reset` (via `resetPage`), so the plan's key link and acceptance grep still hold.
- **Files modified:** `lib/application/lock/setup/pin_setup_state.dart`, `lib/application/lock/lock_device_auth.dart`, `lib/application/lock/lock_screen_cubit.dart`, `lib/presentation/lock/screens/forgot_pin_button.dart`, `lib/presentation/lock/screens/lock_screen.dart`
- **Commits:** 50b3fbf, ee52c72

**3. [Rule 2 - Missing functionality] Added `PinSetupPhase.coolingDown`**
- **Found during:** Task 2
- **Issue:** The contract's phases (`entering`, `verifying`, `saving`, `done`) had no way to mark "input ignored during a cooldown".
- **Fix:** Added `coolingDown`. The keypad is enabled only while `entering`.
- **Commit:** 50b3fbf

**4. [Rule 1 - Bug] Undid an accidental `dart format test` run**
- **Found during:** Task 2
- **Issue:** Running `dart format` over the whole `test/` folder reformatted 43 unrelated test files.
- **Fix:** Restored each of those files with `git checkout -- <file>` before committing, so only plan files were committed.
- **Commit:** none (no unrelated changes were committed)

**Total deviations:** 4 auto-fixed. **Impact:** these are structural changes to fit the architecture guard and the code that already existed. Behaviour matches the plan.

## Known Stubs

None.

## Threat Model Coverage

- **T-05-36 (forgot PIN without proving identity):** reset mode opens only after `DeviceAuthResult.success`. With no screen lock, the dialog shows and the app stays locked. Pinned by `forgot_pin_test`.
- **T-05-37 (change or turn off without the current PIN):** change and verify modes start with the current-PIN step through `PinVerifier`. Pinned by `pin_setup_cubit_test`.
- **T-05-38 (half-enabled lock):** the order of the flag, store and window-privacy writes is checked in `pin_lifecycle_test`, including rollback.
- **T-05-39 (new PIN inherits a stale cooldown):** enable, change and reset write `LockAttempts.none`. Pinned by the reset test.

## Issues Encountered

None blocking. `build_runner` took about 34 s.

## Verification

- `dart run build_runner build --delete-conflicting-outputs`: exit 0
- `flutter test --no-pub` (full suite): 1191 tests, all passed
- `flutter analyze --no-fatal-infos --fatal-warnings`: 64 issues (at most 65 allowed), none in files touched by this plan
- `dart run tool/check_architecture.dart`: PASS

**Still needs a real device:** on Android with a PIN set, tap "Esqueci meu PIN", pass the device PIN/pattern, then set a new PIN. Expected: returning from the system credential screen does not relock the app, the new PIN works, and all data is kept.

## Next Phase Readiness

05-13 can now connect the Settings entry points: the PIN switch opens `PinSetupScreen(mode: create)` or `PinSetupScreen(mode: verify)`, and "Alterar PIN" opens `PinSetupScreen(mode: change)`. Each returns `bool`, and the caller shows its own SnackBar. The UI-SPEC dialog shown before create on a device with no screen lock (`pinNoDeviceLock*`) is not built yet and belongs with those Settings entry points.

## Self-Check: PASSED

- All 12 created files: FOUND
- Commits ccebc3e, 50b3fbf, ee52c72: FOUND in HEAD history
- Acceptance greps: `PinLifecycle` appears in `injection.config.dart`, `PinSetupMode.reset` in `lock_screen.dart`, `lockForgotUnavailableTitle` in `forgot_pin_dialog.dart`
