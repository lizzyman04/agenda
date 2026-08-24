---
phase: 03-finance-core
plan: 13
subsystem: testing
tags: [isar_community, flutter_test, ci, test-infrastructure]

# Dependency graph
requires:
  - phase: 03-finance-core
    provides: TransactionModel + TransactionModelSchema (existing @Collection), IsarService's Isar.open() shape to mirror
provides:
  - IsarTestHarness — a reusable helper that opens a real isar_community instance against an isolated temp directory in flutter test and tears it down cleanly
  - A documented, mitigated CI strategy for the isar_community concurrent-download race
affects: [03-14]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Real-Isar test harness pattern: IsarTestHarness.open(schemas) / .close(), one shared helper under test/support/ instead of per-test-file setup"
    - "CI pre-warm pattern: trigger a shared on-demand native-binary download via a dedicated flutter test step (never dart run) strictly before the main parallel Test step, so Platform.script-derived paths agree"

key-files:
  created:
    - test/support/isar_test_harness.dart
    - test/support/isar_test_harness_test.dart
    - test/support/_warm_isar_core_test.dart
  modified:
    - .github/workflows/ci.yml
    - .gitignore

key-decisions:
  - "Isar Core binary acquisition: download-on-demand via Isar.initializeIsarCore(download: true), not a vendored binary — documented rationale and no-network residual risk live in isar_test_harness.dart's doc comment"
  - "Concurrent-download race mitigated by a dedicated flutter test pre-warm step (test/support/_warm_isar_core_test.dart, run with -j 1) strictly before the main Test step — chosen over serializing the whole suite or hand-maintaining a libraries: path map"
  - "The pre-warm step must itself be a flutter test invocation, never dart run, because Platform.script (and therefore isar_community's download directory) resolves differently between the two — this plan's first attempt used dart run and was a documented no-op"

requirements-completed: [FIN-04, FIN-06]

# Metrics
duration: 15min
completed: 2026-08-24
---

# Phase 03 Plan 13: Real-Isar Test Harness + CI Pre-Warm Summary

**IsarTestHarness opens a real isar_community instance in flutter test via a temp-directory-scoped open()/close() helper, with the isar-core concurrent-download race mitigated by a flutter-test-based CI pre-warm step (not dart run) that resolves the same Platform.script-derived download path as the later parallel test workers.**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-08-24T03:12:48Z
- **Tasks:** 2
- **Files modified:** 5 (3 created, 2 modified)

## Accomplishments

- `IsarTestHarness` (`test/support/isar_test_harness.dart`) opens a real `isar_community` `Isar` instance against an isolated `Directory.systemTemp` temp directory per call, and its `close()` deletes both the instance (`deleteFromDisk: true`) and the temp directory, verified idempotent.
- The binary-acquisition decision (download-on-demand) and its no-network residual risk are stated explicitly in the harness's top-of-file doc comment, along with the concurrent-download race in `isar_community`'s `_downloadIsarCore` and the `Platform.script` path-resolution mismatch between `dart run` and `flutter test` that made this plan's first mitigation attempt a no-op.
- CI now runs a "Warm Isar Core cache" step (`flutter test --no-pub -j 1 test/support/_warm_isar_core_test.dart`) strictly before the main `Test` step, itself a `flutter test` invocation so it resolves the isar-core download directory identically to the later parallel workers.
- `test/support/isar_test_harness_test.dart` proves the harness behaviorally: one test round-trips a `TransactionModel` write/read through a real Isar collection, the other proves `close()` actually removes the backing temp directory.
- Full suite: 300/300 passing (297 baseline + 2 harness self-tests + 1 CI pre-warm test), `flutter analyze --no-fatal-infos --fatal-warnings` still exactly 65 issues with 0 long lines, `dart run tool/check_architecture.dart` PASS.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build IsarTestHarness, decide the binary route, and pre-warm CI with a matching flutter test invocation** - `ac70840` (feat)
2. **Task 2: Prove the harness works — open, write, read, tear down** - `f02995b` (test)

**Deviation fix:** `a091f4a` (chore) — `.gitignore` entry for the downloaded `libisar.so` binary (see Deviations below).

_Note: this plan's tasks were not TDD-gated (`tdd` not set on either task); Task 2 is a proving test written after Task 1's implementation, not a RED/GREEN pair._

## Files Created/Modified

- `test/support/isar_test_harness.dart` - `IsarTestHarness` class: `open(schemas)` / `close()` / `isar` getter / `tempDir` getter, plus a doc comment recording the binary-acquisition decision, the concurrent-download race, and the `Platform.script` path mismatch
- `test/support/_warm_isar_core_test.dart` - Single-test `flutter_test` file that opens and closes the harness once, run as CI's pre-warm trigger
- `test/support/isar_test_harness_test.dart` - Two tests proving the harness opens a real Isar, round-trips a write/read, and cleans up its temp directory on `close()`
- `.github/workflows/ci.yml` - New "Warm Isar Core cache" step inserted between "Architecture guard" and "Test"
- `.gitignore` - Ignores `/libisar.so` (and the Windows/macOS equivalents), the native binary `initializeIsarCore(download: true)` caches at the repo root

## Decisions Made

- Download-on-demand via `Isar.initializeIsarCore(download: true)` chosen over a vendored native binary — zero repo changes, self-caching, avoids drift from the pinned `isar_community` version.
- The pre-warm step is itself a `flutter test` invocation (`-j 1`) rather than pinning the whole CI run to `-j 1` (wall-clock cost every run) or hand-maintaining an explicit `libraries:` path map (reintroduces the exact "two values must stay in sync by hand" failure class that broke the `dart run` attempt).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking/housekeeping] Ignored the downloaded Isar Core native binary**
- **Found during:** Task 2 (running the harness self-test and full suite)
- **Issue:** Running `flutter test` against `test/support/isar_test_harness_test.dart` and `_warm_isar_core_test.dart` triggers `Isar.initializeIsarCore(download: true)`, which caches `libisar.so` at the repo root (per the plan's own documented `Platform.script` resolution). This left an untracked generated binary in the working tree after every task commit.
- **Fix:** Added `/libisar.so`, `/isar.dll`, `/libisar.dylib` to `.gitignore` rather than committing the binary or leaving it untracked.
- **Files modified:** `.gitignore`
- **Verification:** `git status --short` clean after the change; `flutter test` re-run confirms the binary regenerates and stays untracked.
- **Committed in:** `a091f4a`

---

**Total deviations:** 1 auto-fixed (1 housekeeping/blocking)
**Impact on plan:** No scope creep — this is exactly the residual, expected side effect of the plan's own chosen binary-acquisition route (Task 1's doc comment names it), just not previously reflected in `.gitignore`.

## Issues Encountered

None — the isar-core download succeeded in this execution environment (network reachable), so the documented no-network residual risk did not materialize here. If a future CI run or offline machine hits it, `Isar.initializeIsarCore(download: true)` will fail loudly with a download/network error rather than silently, per Task 1's doc comment.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

`03-14` (wave 2, depends on this plan) can now import `IsarTestHarness` directly from `test/support/isar_test_harness.dart` to write real-Isar behavioral regression tests for `TransactionDao.findByMonth` and `findByLinkedGoal` (BL-01), with CI already protected against the concurrent-download race that a second and third harness-consuming test file would otherwise trigger. `test/data/tasks/item_dao_test.dart`'s empty stub remains unfilled and unruled-on — out of this plan's scope, noted in STATE.md.

---
*Phase: 03-finance-core*
*Completed: 2026-08-24*
