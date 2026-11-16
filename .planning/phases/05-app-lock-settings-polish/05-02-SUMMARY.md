---
phase: 05-app-lock-settings-polish
plan: 02
subsystem: auth
tags: [app-lock, pin, attempt-ladder, lifecycle, pure-dart, equatable, tdd]

requires:
  - phase: 04-notifications-backup
    provides: "Domain value-class conventions (final class extends Equatable, pure Dart, no Flutter/injectable imports)"
provides:
  - "LockAttempts value object with the D-07 ladder: 4 counted warnings, 30 s cooldown on exactly the 5th failure, 1/5/15 min escalation, 15 min cap, reset via LockAttempts.none"
  - "cooldownRemaining clamped to the active ladder step, so a clock moved back cannot extend a cooldown"
  - "LockPolicy constants: timeoutOptionsSeconds [0, 30, 60, 300, 900], defaultTimeoutSeconds 60, excursionCapSeconds 300, effectiveTimeoutSeconds"
  - "Top-level shouldLockOnResume: elapsed >= limit locks, hiddenAt null never locks, negative elapsed fails closed, excursion trips use max(timeout, 300 s)"
affects: [05-03, 05-06, 05-08, 05-09, 05-10, app-lock, settings]

actuals:
  tokens: 2899
  tasks: 2
  commits: 4
plan_head_before: ab228bc2283ab26fc4b3c90a4fd0e22cb99ec847
plan_head_after: c0cdfbafd5b88b039df2e05cbff29a91d9462172

tech-stack:
  added: []
  patterns:
    - "Security rules as pure functions over an injected wall-clock now, every boundary pinned by a unit test"
    - "Clamp untrusted-clock durations to the step that produced them (anti clock-rollback)"

key-files:
  created:
    - lib/domain/lock/lock_attempts.dart
    - lib/domain/lock/lock_policy.dart
    - test/domain/lock/lock_attempts_test.dart
    - test/domain/lock/lock_policy_test.dart
  modified: []

key-decisions:
  - "shouldLockOnResume uses >= for both the normal and the excursion limit (research text wrote > for the excursion case); elapsed == limit locks, pinned by tests at 300 s and 900 s"
  - "cooldownRemaining returns zero when lockouts == 0 even if cooldownUntil is set, so a malformed persisted state cannot block PIN entry without a lockout behind it"
  - "LockPolicy.effectiveTimeoutSeconds maps null and any unlisted value (45, -1) to the 60 s default"

patterns-established:
  - "Lock domain lives in lib/domain/lock/ (pure Dart; consumed by SecurePinStore/PinVerifier in 05-03 and AppLockCubit in 05-08)"

requirements-completed: [DATA-05]

coverage:
  - id: D1
    description: "D-07 attempt ladder: 4 warnings, 30 s on exactly the 5th failure, 1/5/15 min escalation with 15 min cap, reset to none, no backwards-clock extension"
    requirement: DATA-05
    verification:
      - kind: unit
        ref: "flutter test --no-pub test/domain/lock/lock_attempts_test.dart (8 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Resume-lock rule (D-01/D-02/D-03): elapsed >= timeout locks, inactive-only never locks, negative elapsed locks, excursion cap max(timeout, 300 s); timeout options and default 60"
    requirement: DATA-05
    verification:
      - kind: unit
        ref: "flutter test --no-pub test/domain/lock/lock_policy_test.dart (8 tests)"
        status: pass
    human_judgment: false

duration: 3min
completed: 2026-11-16
status: complete
---

# Phase 5 Plan 02: Lock Attempt Ladder and Resume-Lock Rule Summary

**The D-07 attempt ladder is now a pure `LockAttempts` value object. Its cooldowns are clamped against a clock moved back. A pure `shouldLockOnResume` rule handles elapsed == timeout, inactive-only trips, negative elapsed time and the 300 s excursion cap, and a test fixes each of those boundaries.**

## Performance

- **Duration:** about 3 min
- **Started:** 2026-11-16T18:30:32Z
- **Completed:** 2026-11-16T18:33:07Z
- **Tasks:** 2
- **Files created:** 4

## Accomplishments
- `LockAttempts` (82 lines): `registerFailure(now)` counts failures 1 to 4 as warnings (`remainingBeforeCooldown` 4, 3, 2, 1). Exactly the 5th failure starts a 30 s cooldown. After that, each failure escalates the cooldown to 60 s, then 300 s, then 900 s, and it stays at 900 s. A cooldown ends exactly at `cooldownUntil`. `cooldownRemaining` is clamped to the ladder step for the current `lockouts`.
- `LockPolicy` + `shouldLockOnResume` (47 lines): the options are 0/30/60/300/900 and the default is 60. Unknown stored values fall back to 60. The resume rule takes a wall-clock `now`. The doc comment says Stopwatch must not be used and that cold start always locks.
- 16 unit tests across the two files. `flutter analyze` is clean on both paths. `dart run tool/check_architecture.dart` passes.

## Task Commits

1. **Task 1: Tracer, D-07 attempt ladder**: RED `091b1e0` (test), GREEN `4c26f6d` (feat)
2. **Task 2: Resume-lock rule and timeout options**: RED `a21c29f` (test), GREEN `c0cdfba` (feat)

No REFACTOR commits were needed. Both RED runs failed by compilation, because the library under test did not exist yet ("Some tests failed").

Tracer feedback gate: interactive run, `end-of-phase` mode, automated-only `<verify>`. Re-ran `flutter test --no-pub test/domain/lock/lock_attempts_test.dart && flutter analyze lib/domain/lock test/domain/lock` (8/8 green, no issues) before expanding.

## Files Created/Modified
- `lib/domain/lock/lock_attempts.dart`: `LockAttempts` and the D-07 ladder
- `lib/domain/lock/lock_policy.dart`: `LockPolicy` constants and top-level `shouldLockOnResume`
- `test/domain/lock/lock_attempts_test.dart`: 8 ladder tests (fixed base `DateTime.utc(2026, 1, 1, 12)`)
- `test/domain/lock/lock_policy_test.dart`: 8 resume-rule and timeout-option tests

## Decisions Made
- **`>=` for the excursion limit.** RESEARCH writes `>` for the excursion case. The plan asked for a single `>=` comparison, so elapsed == max(timeout, 300 s) locks. Tests fix this at 299/300 s (timeout 0) and 899/900 s (timeout 900).
- **`cooldownRemaining` needs `lockouts > 0`.** If a persisted state has `cooldownUntil` set and `lockouts == 0`, it does not cool down. The clamp step comes from `lockouts`, so there is no step to clamp to. That state cannot come out of `registerFailure`.
- **Lint suppression in one test.** The test that checks value equality between `none` and `const LockAttempts()` carries `// ignore: use_named_constants`, because the default constructor is what that test checks.

## Deviations from Plan

None. The plan executed as written.

## Issues Encountered
- Commits land on `main`. The protected-branch query flags `main`, but the coordinator confirmed this project commits directly to `main` (`git.branching_strategy: "none"`), as 05-01 did.
- **REQUIREMENTS.md not ticked.** `requirements mark-complete DATA-05` was not run. DATA-05 is spread across plans 05-02 to 05-14, so ticking it now would be premature. This matches 05-01, which also left DATA-05 open. It is listed in `requirements-completed` because this plan contributes to it.

## Known Stubs
None.

## User Setup Required
None.

## Next Phase Readiness
- 05-03 (`SecurePinStore`/`PinVerifier`) can persist and drive `LockAttempts` verbatim. 05-08 (`AppLockCubit.onResumed`) can call `shouldLockOnResume` and `LockPolicy.effectiveTimeoutSeconds`.

---
*Phase: 05-app-lock-settings-polish*
*Completed: 2026-11-16*

## Self-Check: PASSED
