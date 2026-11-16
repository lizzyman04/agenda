---
phase: 05-app-lock-settings-polish
plan: 09
subsystem: auth
tags: [flutter, bloc, app-lock, pin, cooldown, accessibility, animation]

requires:
  - phase: 05-app-lock-settings-polish
    provides: "05-02 LockAttempts ladder (cooldownRemaining, isCoolingDown); 05-03 PinVerifier outcomes and loadAttempts; 05-06 LockScreenCubit, PinKeypad (enabled), PinDots, the 40 dp status slot"
provides:
  - "LockMessage sealed family: WrongPinMessage(remaining), CooldownMessage(remaining), CheckFailedMessage"
  - "LockEntryPhase.coolingDown; LockScreenState.message and LockScreenState.errorTick"
  - "LockScreenCubit cooldown ticker (Timer.periodic 1 s) and start() that resumes a persisted cooldown or shows CheckFailedMessage on an unreadable store"
  - "LockStatusLine (fixed 40 dp, live region) and formatCooldown (m:ss, seconds rounded up)"
  - "PinDots(errorTick:) wrong-entry shake with reduced-motion fallback"
  - "test/support/fonts/Roboto-Regular.ttf fixture for real text-metric checks"
affects: [05-10 pin setup, 05-11 biometrics, 05-12 forgot PIN, lock screen UAT]

actuals:
  tokens: 13086
  tasks: 2
  commits: 2
plan_head_before: 989450b9de41a27f30f7c274702796e3d09caf83
plan_head_after: 8585b7c2f7fab41e79edf654eeba2dda2414f429

tech-stack:
  added: []
  patterns:
    - "Status messages as a sealed Equatable family carried in cubit state; widgets switch over them for text and color"
    - "errorTick counter in state drives one-shot UI feedback (shake) without event streams"
    - "Countdown recomputed from persisted state on every tick, never decremented in memory"
    - "Text-fit tests load a real font with FontLoader; the FlutterTest font is a 1 em square per glyph"

key-files:
  created:
    - lib/presentation/lock/keypad/lock_status_line.dart
    - test/application/lock/lock_screen_cooldown_test.dart
    - test/support/fonts/Roboto-Regular.ttf
    - test/support/fonts/README.md
  modified:
    - lib/application/lock/lock_screen_state.dart
    - lib/application/lock/lock_screen_cubit.dart
    - lib/presentation/lock/keypad/pin_dots.dart
    - lib/presentation/lock/keypad/pin_keypad.dart
    - lib/presentation/lock/screens/lock_screen.dart
    - lib/application/lock/README.md
    - lib/presentation/lock/keypad/README.md
    - lib/presentation/lock/screens/README.md
    - test/application/lock/lock_screen_cubit_test.dart
    - test/presentation/lock/lock_screen_test.dart

key-decisions:
  - "The countdown is recomputed from LockAttempts.cooldownRemaining(clock()) on each 1 s tick, and start() enters coolingDown from the persisted attempts before accepting input, so an app kill cannot reset or shorten a cooldown (T-05-26)"
  - "A failed or throwing loadAttempts shows CheckFailedMessage in ready, so the keypad stays usable; verify still fails closed on its own"
  - "PinCheckFailed and the 5th wrong PIN (PinCoolingDown) bump errorTick like PinRejected, so every rejected entry shakes"
  - "PinDots uses AnimationBehavior.preserve so the error dots last 300 ms even when the platform shortens animations; MediaQuery.disableAnimations removes only the movement"
  - "The PT-BR two-line fit check loads Roboto 2.137 (Apache 2.0) from test/support/fonts, because the FlutterTest font draws every glyph 1 em wide and can never fit 35 characters into 2 lines at 264 dp"

patterns-established:
  - "LockMessage switch: error messages in cs.error, cooldown in cs.onSurfaceVariant"
  - "Cubit timers: cancel in close() and on start(); tests drive them with testWidgets + tester.pump and a FakeClock advanced in lockstep"

requirements-completed: [DATA-05]

coverage:
  - id: D1
    description: "Wrong PIN n (1-4) shows lockWrongPin(5 - n) in cs.error in the 40 dp live-region status line; the dots shake ±8 dp x3 over 300 ms in cs.error with a medium haptic, then clear; typing clears the message"
    requirement: DATA-05
    verification:
      - kind: unit
        ref: "test/application/lock/lock_screen_cubit_test.dart#PinRejected(3) shows WrongPinMessage(3) and bumps errorTick"
        status: pass
      - kind: unit
        ref: "test/application/lock/lock_screen_cubit_test.dart#typing a digit clears the message but keeps errorTick"
        status: pass
      - kind: automated_ui
        ref: "test/presentation/lock/lock_screen_test.dart#wrong PIN: remaining attempts in cs.error and a dot shake"
        status: pass
    human_judgment: false
  - id: D2
    description: "Reduced motion: no shake, the four error dots show for 300 ms"
    requirement: DATA-05
    verification:
      - kind: automated_ui
        ref: "test/presentation/lock/lock_screen_test.dart#reduced motion: no shake, error dots for 300 ms"
        status: pass
    human_judgment: false
  - id: D3
    description: "5th wrong PIN disables digit keys and backspace and counts down lockCooldown(m:ss) every second in cs.onSurfaceVariant until ready; the next wrong PIN escalates per the ladder"
    requirement: DATA-05
    verification:
      - kind: unit
        ref: "test/application/lock/lock_screen_cooldown_test.dart#5th wrong PIN: 30 s countdown, input ignored, then ready"
        status: pass
      - kind: automated_ui
        ref: "test/presentation/lock/lock_screen_test.dart#cooldown: keys disabled, countdown in onSurfaceVariant"
        status: pass
      - kind: unit
        ref: "test/presentation/lock/lock_screen_test.dart#formatCooldown renders m:ss with seconds rounded up"
        status: pass
    human_judgment: false
  - id: D4
    description: "Re-opening during a cooldown shows the remaining countdown on the first state after start (app kill cannot reset the wait)"
    requirement: DATA-05
    verification:
      - kind: unit
        ref: "test/application/lock/lock_screen_cooldown_test.dart#re-opening during a cooldown: the first state is the countdown"
        status: pass
      - kind: unit
        ref: "test/application/lock/lock_screen_cooldown_test.dart#re-opening during a cooldown keeps counting down"
        status: pass
    human_judgment: false
  - id: D5
    description: "Unreadable attempt state or PIN record shows lockErrorGeneric in cs.error, stays locked and keeps the keypad usable"
    requirement: DATA-05
    verification:
      - kind: unit
        ref: "test/application/lock/lock_screen_cooldown_test.dart#unreadable attempt state: CheckFailedMessage, retry allowed"
        status: pass
      - kind: unit
        ref: "test/application/lock/lock_screen_cubit_test.dart#PinCheckFailed shows CheckFailedMessage"
        status: pass
    human_judgment: false
  - id: D6
    description: "Longest PT-BR status string fits 2 lines at 264 dp at 1.0 text scale"
    requirement: DATA-05
    verification:
      - kind: automated_ui
        ref: "test/presentation/lock/lock_screen_test.dart#longest PT-BR status fits 2 lines at 264 dp"
        status: pass
    human_judgment: false
  - id: D7
    description: "TalkBack/VoiceOver actually announce wrong-PIN and cooldown changes from the live-region status line, and the shake and haptic feel right on a device"
    requirement: DATA-05
    verification: []
    human_judgment: true
    rationale: "Tests assert Semantics(liveRegion: true) and the haptic call, but announcement behavior and feel depend on the platform screen reader and hardware"

duration: 21min
completed: 2026-11-16
status: complete
---

# Phase 5 Plan 09: Wrong-PIN Feedback and Cooldown Countdown Summary

**The lock screen now explains D-07. A wrong PIN shows "Restam N tentativas" in cs.error and shakes the dots (300 ms, or error dots only under reduced motion). The 5th wrong PIN disables the keypad and shows a live m:ss countdown, recomputed every second from the persisted attempts, so killing the app does not reset it. If storage cannot be read, the screen shows lockErrorGeneric, stays locked, and lets the user try again.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-11-16T20:47:37Z
- **Completed:** 2026-11-16T21:08:17Z
- **Tasks:** 2
- **Files modified:** 14 (13 text files + 1 font fixture)

## Accomplishments
- `LockMessage` model (`WrongPinMessage`, `CooldownMessage`, `CheckFailedMessage`), a `coolingDown` phase and `message`/`errorTick` on `LockScreenState`. State still never holds the digits.
- `LockScreenCubit` maps each verify outcome to a message. A `Timer.periodic(1 s)` runs the cooldown and recomputes the remaining time from persisted attempts on each tick. `start()` resumes a running cooldown before accepting input and shows `CheckFailedMessage` when the load fails. `close()` cancels the ticker. The file is 147 lines, under the 150 cap.
- `LockStatusLine` is a fixed 40 dp `Semantics(liveRegion: true)` line, max 2 lines. Errors use `cs.error` and the cooldown uses `cs.onSurfaceVariant`. `formatCooldown` shows `m:ss` and rounds seconds up.
- `PinDots(errorTick:)` shakes ±8 dp over 3 cycles in 300 ms (`easeInOut`), with all dots in `cs.error` and `HapticFeedback.mediumImpact`. Under reduced motion the dots only turn `cs.error`.
- `LockScreen` puts the status line in the 40 dp slot and enables the keypad only in `ready`. The `leading` key slot (biometrics, 05-11) is never disabled.

## Task Commits

1. **Task 1: Tracer — wrong PIN shows remaining attempts and the dots shake** - `d7cfe2a` (feat)
2. **Task 2: Cooldown — disabled keys, live m:ss countdown, survives app kill; storage error retryable** - `8585b7c` (feat)

Tracer gate: interactive run, `human_verify_mode` end-of-phase, `<verify>` automated-only. Re-ran the tracer verify (lock tests green, analyze 64 issues, exit 0) and then went on to Task 2.

## Files Created/Modified
- `lib/application/lock/lock_screen_state.dart` - LockMessage family, coolingDown phase, message + errorTick
- `lib/application/lock/lock_screen_cubit.dart` - outcome → message mapping, cooldown ticker, persisted-cooldown start, storage-error retry
- `lib/presentation/lock/keypad/lock_status_line.dart` - LockStatusLine + formatCooldown (new)
- `lib/presentation/lock/keypad/pin_dots.dart` - StatefulWidget with shake and error dots
- `lib/presentation/lock/keypad/pin_keypad.dart` - doc: `enabled` never touches `leading`
- `lib/presentation/lock/screens/lock_screen.dart` - status line, errorTick, `enabled: phase == ready`
- `lib/application/lock/README.md`, `lib/presentation/lock/keypad/README.md`, `lib/presentation/lock/screens/README.md` - message model, cooldown rule, line counts
- `test/application/lock/lock_screen_cubit_test.dart` - message/errorTick cases; existing outcome tests updated to the new state
- `test/application/lock/lock_screen_cooldown_test.dart` - countdown, escalation, app-kill resume, load Err/throw, expired cooldown (new)
- `test/presentation/lock/lock_screen_test.dart` - wrong-PIN text/color/shake, reduced motion, cooldown keypad + color, formatCooldown, 264 dp two-line fit
- `test/support/fonts/Roboto-Regular.ttf`, `test/support/fonts/README.md` - test-only real font for text-metric checks (new)

## Decisions Made
- The countdown is never decremented in memory. Each tick reads `cooldownRemaining(clock())` from the persisted `LockAttempts`, so it always matches the stored state, even after a restart.
- `PinCheckFailed` and the cooldown-starting wrong PIN also bump `errorTick`, so every rejected entry gets the same shake and haptic.
- Followed the plan's `enabled: phase == ready`. The keys also show disabled colors for the short loading and verifying phases, when the cubit already ignores input.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Real font fixture for the 264 dp two-line check**
- **Found during:** Task 1
- **Issue:** The default `FlutterTest` font draws every glyph as a full 1 em square. At 14 sp, 264 dp holds about 18 characters per line, so "PIN incorreto. Restam 4 tentativas." (35 chars) always took 3 lines and `didExceedMaxLines` was true. The test could not check the real claim.
- **Fix:** Added `test/support/fonts/Roboto-Regular.ttf`, Roboto 2.137 (Apache 2.0; the license is in the font's name table). It is copied from the local pub cache, test-only and not bundled into the app. A README records where it came from. The test loads it with `FontLoader('Roboto')`, which is the family Material `Typography` already requests on Android, and runs last in its file.
- **Files modified:** test/support/fonts/Roboto-Regular.ttf, test/support/fonts/README.md, test/presentation/lock/lock_screen_test.dart
- **Verification:** Failed under FlutterTest metrics and passes with Roboto loaded.
- **Committed in:** d7cfe2a

**2. [Rule 3 - Blocking] The app-kill resume test is split into a plain test and a widget test**
- **Found during:** Task 2
- **Issue:** In `testWidgets` (fake async), awaiting `cubit.close()` hung after an external `cubit.stream.listen` subscription had been used. The broadcast controller's done future never completed under FakeAsync. This only affects the test harness: production closes the cubit without awaiting it, on a real event loop.
- **Fix:** A plain `test()` checks that the first emitted state after `start()` is `coolingDown` with `CooldownMessage(2 min)`, using a stream listener and real async. A `testWidgets` without a listener checks the per-second countdown and that closing cancels the ticker.
- **Files modified:** test/application/lock/lock_screen_cooldown_test.dart
- **Verification:** All 6 cooldown tests pass. Full suite: 1081 passing.
- **Committed in:** 8585b7c

---

**Total deviations:** 2 auto-fixed (2 blocking, both test-harness only)
**Impact on plan:** Production code matches the plan. Both deviations change only how two claims are tested.

## Issues Encountered
- `lock_screen_cubit.dart` was 154 lines after the first pass. I merged the emit helpers into a single `_show(phase, tick, [message])`, which brought it to 147 lines with no behavior change.
- The analyzer reported 67 issues after Task 1's test additions: 3 new infos in `lock_screen_test.dart`, over the 65 limit. After fixing them it is back at the 64 baseline.

## Verification
- `flutter test --no-pub test/application/lock test/presentation/lock`: all passed
- `flutter test --no-pub` (full suite): 1081 passed, exit 0
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, 64 issues (limit 65)
- `dart run tool/check_architecture.dart`: PASS
- Acceptance greps: `liveRegion` in lock_status_line.dart (1), `WrongPinMessage` in lock_screen_state.dart (2), `Timer.periodic` in lock_screen_cubit.dart (1)

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- 05-10 (PIN setup) can reuse `LockStatusLine`, `PinDots(errorTick:)` and the `LockMessage` pattern for `pinMismatch`.
- 05-11 can drop the biometric key into `PinKeypad.leading`. It stays enabled during a cooldown, as the UI-SPEC requires.
- 05-12 adds "Esqueci meu PIN", which must also stay enabled during a cooldown.
- On-device check still needed: screen-reader announcements and the feel of the shake and haptic (coverage D7).

---
*Phase: 05-app-lock-settings-polish*
*Completed: 2026-11-16*

## Self-Check: PASSED
- FOUND: lib/presentation/lock/keypad/lock_status_line.dart, test/application/lock/lock_screen_cooldown_test.dart, test/support/fonts/Roboto-Regular.ttf, test/support/fonts/README.md
- FOUND commits: d7cfe2a, 8585b7c (ancestors of HEAD)
