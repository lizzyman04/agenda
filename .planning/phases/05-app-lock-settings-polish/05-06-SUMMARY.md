---
phase: 05-app-lock-settings-polish
plan: 06
subsystem: auth
tags: [flutter, app-lock, pin, bloc, cubit, accessibility, data-05, sc-1]
status: complete

requires:
  - phase: 05-app-lock-settings-polish
    provides: "05-03 PinVerifier (PinVerified / PinRejected / PinCoolingDown / PinCheckFailed), Pbkdf2PinHasher, SecurePinStore, lock_fakes.dart"
  - phase: 05-app-lock-settings-polish
    provides: "05-01 ARB keys (lockEnterPinTitle, lockDeleteDigit, lockDigitsEntered) and StorageKeys.pinConfigured"
  - phase: 05-app-lock-settings-polish
    provides: "05-04 OnboardingGate as MaterialApp.home; widget_test seeds privacy_statement_shown"
provides:
  - "AppLockState(pinEnabled, locked, obscured) + copyWith"
  - "AppLockCubit (@lazySingleton): synchronous frame-1 seed from pin_configured (non-bool fails closed), unlock(), pinEnabledChanged(enabled:)"
  - "LockEntryPhase + LockScreenState(phase, digitCount); LockScreenCubit (@injectable): start, addDigit (auto-submit on 4th), removeDigit, clearDigits; unlock only on PinVerified"
  - "LockGate in MaterialApp.builder: Offstage+TickerMode app, own lock Navigator (HeroControllerScope.none), 150 ms unlock fade, lockFadeKey"
  - "LockScreen (owns its cubit), PinKeypad, DigitKey, KeypadIconKey, keypadKeySize, PinDots"
  - "app.dart: BlocProvider<AppLockCubit>.value above MaterialApp and builder: LockGate"
  - "Test support: MockPinVerifier, MockAppLockCubit, lockTestApp(), LockTestHome, settleRealAsync(), seedPinRecord()"
affects: [05-08 privacy overlay layer, 05-09 status line and cooldown, 05-11 biometric key, 05-12 forgot-PIN and lifecycle relock, 05-13 settings PIN switch]

actuals:
  tokens: 14052
  tasks: 3
  commits: 3
plan_head_before: 0fee6e1d01a69c67cb9d3effd2f8e3ebd2b6d698
plan_head_after: c49256378917d20d18222506b840ba291e26efb6

tech-stack:
  added: []
  patterns:
    - "Lock layer = MaterialApp.builder Stack: app (Offstage + TickerMode) below, own Navigator above; later overlays stack above the lock"
    - "Second Navigator under MaterialApp must be wrapped in HeroControllerScope.none"
    - "Lock appears instantly, disappears with a fade driven by an AnimationController (not AnimatedSwitcher) so relocking never fades in"
    - "Keypad state carries the digit count only; digits live in a private cubit field"
    - "Icon-only keys: Semantics(container) outside the Tooltip so the tooltip names the node"

key-files:
  created:
    - lib/application/lock/app_lock_state.dart
    - lib/application/lock/app_lock_cubit.dart
    - lib/application/lock/lock_screen_state.dart
    - lib/application/lock/lock_screen_cubit.dart
    - lib/presentation/lock/widgets/lock_gate.dart
    - lib/presentation/lock/screens/lock_screen.dart
    - lib/presentation/lock/keypad/pin_keypad.dart
    - lib/presentation/lock/keypad/keypad_key.dart
    - lib/presentation/lock/keypad/pin_dots.dart
    - lib/presentation/lock/README.md
    - lib/presentation/lock/widgets/README.md
    - lib/presentation/lock/screens/README.md
    - lib/presentation/lock/keypad/README.md
    - test/application/lock/app_lock_cubit_test.dart
    - test/application/lock/lock_screen_cubit_test.dart
    - test/presentation/lock/lock_gate_cold_start_test.dart
    - test/presentation/lock/lock_screen_test.dart
    - test/presentation/lock/lock_gate_cover_test.dart
  modified:
    - lib/app.dart
    - lib/config/di/injection.config.dart
    - lib/application/lock/README.md
    - test/support/lock_fakes.dart
    - test/widget_test.dart
    - test/config/di/lock_di_test.dart

key-decisions:
  - "The lock Navigator is wrapped in HeroControllerScope.none: MaterialApp's HeroController cannot be shared by two Navigators (assertion found by the tracer)"
  - "Unlock fade uses an AnimationController in a stateful lock layer instead of AnimatedSwitcher, so locking is always instant and only unlocking fades"
  - "LockScreenCubit treats a verifier exception like PinCheckFailed (stay locked); a loadAttempts failure still moves to ready because verify fails closed on its own"
  - "Android back while locked is accepted (Pitfall 12): it pops a hidden app route logically; the route's exit transition stays frozen behind the lock (TickerMode off) and completes after unlock"

patterns-established:
  - "lockTestApp(appLock:, disableAnimations:) in test/support/lock_fakes.dart is the harness for every lock widget test"
  - "Real-isolate PIN checks in widget tests: tap, then settleRealAsync(tester, () => !appLock.state.locked)"

requirements-completed: [DATA-05]

coverage:
  - id: D1
    description: "Cold start with pin_configured=true shows LockScreen on the first pump with no NavigationBar or home content; no PIN shows home on the first pump"
    requirement: DATA-05
    verification:
      - kind: automated_ui
        ref: "test/presentation/lock/lock_gate_cold_start_test.dart#PIN configured: frame 1 is the lock screen; 1234 unlocks"
        status: pass
      - kind: automated_ui
        ref: "test/presentation/lock/lock_gate_cold_start_test.dart#no PIN configured: HOME on the first pump, never a lock"
        status: pass
      - kind: automated_ui
        ref: "test/widget_test.dart#the first frame is the lock screen, not the shell"
        status: pass
      - kind: unit
        ref: "test/application/lock/app_lock_cubit_test.dart"
        status: pass
    human_judgment: false
  - id: D2
    description: "Correct PIN (real PBKDF2 record) unlocks; wrong PIN, check failure, cooldown or verifier exception keep the lock and clear the dots"
    requirement: DATA-05
    verification:
      - kind: automated_ui
        ref: "test/presentation/lock/lock_gate_cold_start_test.dart#a wrong PIN keeps the lock"
        status: pass
      - kind: unit
        ref: "test/application/lock/lock_screen_cubit_test.dart"
        status: pass
    human_judgment: false
  - id: D3
    description: "Keypad states: empty rings + disabled backspace at 0, filled dots 1-3, backspace removes, long-press clears, input ignored while loading/verifying"
    verification:
      - kind: automated_ui
        ref: "test/presentation/lock/lock_screen_test.dart"
        status: pass
    human_judgment: false
  - id: D4
    description: "Accessibility: digit keys are labelled buttons, dots expose lockDigitsEntered(count), backspace named by its tooltip; tooltip renders (lock Overlay)"
    verification:
      - kind: automated_ui
        ref: "test/presentation/lock/lock_screen_test.dart#digit keys are labelled buttons; dots expose the count"
        status: pass
      - kind: automated_ui
        ref: "test/presentation/lock/lock_screen_test.dart#backspace tooltip renders on long-press (lock Overlay)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Cover guarantees: no HOME semantics while locked, back keeps the lock, 150 ms fade, instant under disableAnimations"
    verification:
      - kind: automated_ui
        ref: "test/presentation/lock/lock_gate_cover_test.dart"
        status: pass
    human_judgment: false
  - id: D6
    description: "On a real device, the first rendered frame after a process kill is the lock screen (no flash of content) and the lock screen scrolls at 200% system text on a small screen"
    verification:
      - kind: automated_ui
        ref: "test/presentation/lock/lock_screen_test.dart#320x568 at 200% text scale scrolls without overflow"
        status: pass
    human_judgment: true
    rationale: "Backstop truths: host tests prove frame-1 widget order and overflow, but the native splash-to-first-frame handoff and real font scaling need an on-device check"

duration: 30min
completed: 2026-11-16
---

# Phase 5 Plan 06: Cold-Start Lock Gate and PIN Keypad Summary

**MaterialApp.builder lock layer with its own Navigator, a synchronously seeded AppLockCubit that locks frame 1 when a PIN is configured, and a 72 dp accessible PIN keypad whose 4th digit verifies against the real PBKDF2 record; only PinVerified unlocks.**

## Performance

- **Duration:** 30 min
- **Started:** 2026-11-16T19:22:59Z
- **Completed:** 2026-11-16T19:53:48Z
- **Tasks:** 3
- **Files modified:** 24

## Accomplishments

- SC-1 on the host: with `pin_configured = true` the first pump shows `LockScreen` and no `NavigationBar` (isolated harness and full `AgendaApp`); typing 1-2-3-4 against a real PBKDF2 record unlocks; no PIN means no lock.
- Fail-closed unlock: `LockScreenCubit` calls `AppLockCubit.unlock()` only on `PinVerified`; rejected, cooling-down, check-failed and thrown verifications clear the dots and keep the lock. A non-bool `pin_configured` value locks.
- Keypad per UI-SPEC: 72 dp digit keys with `Semantics(button, label)`, M3 disabled colors for the 05-09 cooldown, a backspace key that is disabled at 0 digits and clears on long-press, and a dots row that exposes `lockDigitsEntered(count)`.
- Cover guarantees: the app is `Offstage` with tickers off while locked (no paint, hits or semantics), the lock survives system back, unlock fades over 150 ms (instant under reduced motion), and the app is onstage in the unlock frame.

## Task Commits

1. **Task 1: Tracer, cold start with a PIN shows the lock screen and the correct PIN unlocks** - `0f50ef5` (feat)
2. **Task 2: Keypad states and accessibility** - `a046d95` (feat)
3. **Task 3: Cover guarantees, unlock fade, READMEs, full-app cold-start test** - `c492563` (feat)

**Plan metadata:** recorded in the docs commit that adds this SUMMARY.

## Files Created/Modified

- `lib/application/lock/app_lock_state.dart` - `AppLockState(pinEnabled, locked, obscured)`
- `lib/application/lock/app_lock_cubit.dart` - frame-1 seed, `unlock`, `pinEnabledChanged`
- `lib/application/lock/lock_screen_state.dart` - `LockEntryPhase`, count-only `LockScreenState`
- `lib/application/lock/lock_screen_cubit.dart` - digit entry, auto-submit, outcome handling
- `lib/presentation/lock/widgets/lock_gate.dart` - builder Stack, lock Navigator, unlock fade
- `lib/presentation/lock/screens/lock_screen.dart` - UI-SPEC lock column, owns its cubit
- `lib/presentation/lock/keypad/{pin_keypad,keypad_key,pin_dots}.dart` - shared keypad widgets
- `lib/presentation/lock/{,widgets,screens,keypad}/README.md` - slice docs with layer-order rule
- `lib/app.dart` - `BlocProvider<AppLockCubit>.value` and `builder: LockGate`
- `lib/config/di/injection.config.dart` - regenerated (AppLockCubit lazySingleton, LockScreenCubit factory)
- `lib/application/lock/README.md` - lists the four new files
- `test/support/lock_fakes.dart` - mocks plus `lockTestApp`, `LockTestHome`, `settleRealAsync`, `seedPinRecord`
- `test/application/lock/*`, `test/presentation/lock/*`, `test/widget_test.dart`, `test/config/di/lock_di_test.dart` - tests

## Decisions Made

- `HeroControllerScope.none` around the lock Navigator. The tracer hit "A HeroController can not be shared by multiple Navigators" on the first run.
- The fade is an `AnimationController` in a stateful lock layer, not an `AnimatedSwitcher`. Locking stays instant (it never fades in over hidden content), and the lock subtree keeps the same structure while fading, so `LockScreen` is not rebuilt. While fading it ignores pointers and is excluded from semantics.
- Locking also unfocuses the primary focus (RESEARCH Pattern 1), so a soft keyboard from a hidden field closes.
- Back while locked is accepted and documented in the `LockGate` doc (Pitfall 12). The test pins that the hidden route is popped logically (`canPop()` false), the lock stays, and the frozen exit transition finishes after unlock.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Second Navigator shared MaterialApp's HeroController**
- **Found during:** Task 1 (tracer)
- **Issue:** The lock layer's `Navigator` picked up MaterialApp's `HeroController`, which asserts when two Navigators share it.
- **Fix:** Wrapped the lock Navigator in `HeroControllerScope.none`.
- **Files modified:** lib/presentation/lock/widgets/lock_gate.dart
- **Verification:** lock_gate_cold_start_test passes, with no framework exception
- **Committed in:** 0f50ef5

**2. [Rule 2 - Missing critical] Verifier exception handled as fail-closed**
- **Found during:** Task 1
- **Issue:** The plan named outcomes only. A thrown `verify` would have left the keypad stuck in `verifying` with an unhandled async error.
- **Fix:** A `try` around `verify` maps any throw to `PinCheckFailed` (stay locked, clear to ready). `loadAttempts` is guarded the same way.
- **Files modified:** lib/application/lock/lock_screen_cubit.dart
- **Verification:** lock_screen_cubit_test "a verifier exception keeps the lock (fail closed)"
- **Committed in:** 0f50ef5

**3. [Rule 3 - Blocking] Tooltip semantics did not name the icon key**
- **Found during:** Task 2
- **Issue:** With the `Semantics(container)` inside the `Tooltip`, the tooltip text was attached to an ancestor node, so the backspace node had no name.
- **Fix:** Moved the container `Semantics` outside the `Tooltip`.
- **Files modified:** lib/presentation/lock/keypad/keypad_key.dart
- **Verification:** lock_screen_test semantics case (`isSemantics(tooltip: lockDeleteDigit, isButton, isEnabled)`)
- **Committed in:** a046d95

**4. [Rule 3 - Blocking] Reverted an out-of-scope format change**
- **Found during:** Task 3
- **Issue:** Running `dart format test/support` reformatted the unrelated `test/support/isar_test_harness_test.dart`.
- **Fix:** Restored that file with `git checkout --` before committing. It was never committed.
- **Files modified:** none (restored)
- **Committed in:** n/a

---

**Total deviations:** 4 auto-fixed (1 bug, 1 missing critical, 2 blocking)
**Impact on plan:** All fixes were needed for correctness or for the plan's own acceptance tests. There was no scope creep. The full-app test seeds `pin_configured` through `getIt<SharedPreferences>().setBool` after the shared `setUp` instead of re-seeding the mock map. The effect is the same, because `AppLockCubit` is lazy.

## Issues Encountered

- A stream emitted from the mocked `AppLockCubit` (`whenListen`) took more than one `pump` to reach `BlocBuilder`, so the hidden-route test settles with `pumpAndSettle` after each emission. A real cubit is unaffected.
- Analyzer count stayed within budget: 64 issues (limit 65), and none of them are in the files this plan added.

## Known Stubs

- `lib/presentation/lock/screens/lock_screen.dart`: the 40 dp status line is an empty fixed-height slot by design. Plan 05-09 fills it with wrong-PIN, cooldown and error messages. The forgot-PIN button (05-12) and the biometric key (05-11) are also left to their own plans. None of these blocks this plan's goal.

## Threat Flags

None. The plan's register covers every surface added: T-05-16 (frame-1 seed and Offstage), T-05-17 (no HOME semantics test), T-05-18 (back accepted and tested), T-05-19 (builder layer with its own Navigator) and T-05-20 (unlock only on PinVerified).

## User Setup Required

None. No external service configuration is required.

## Next Phase Readiness

- 05-08 can add the privacy overlay as a third `Stack` layer above `_LockLayer` and drive `AppLockState.obscured`.
- 05-09 reads `PinVerifier.loadAttempts()` results and outcomes in `LockScreenCubit` to fill the status line and drive `PinKeypad(enabled: false)`.
- 05-11 and 05-12 add `PinKeypad.leading` (biometric key), the forgot-PIN button and a relock entry point on `AppLockCubit`.
- Backstop for on-device UAT: no content flash on a cold start with a PIN, and scrolling at 200% system text.

---
*Phase: 05-app-lock-settings-polish*
*Completed: 2026-11-16*

## Self-Check: PASSED

All 16 created files exist; task commits 0f50ef5, a046d95, c492563 are ancestors of HEAD. Plan verification: build_runner exit 0; `flutter test --no-pub` 1035 passed; analyze 64 issues (exit 0); architecture guard PASS.
