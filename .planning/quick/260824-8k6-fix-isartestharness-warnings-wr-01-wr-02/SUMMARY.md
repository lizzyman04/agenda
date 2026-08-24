---
status: complete
quick_id: 260824-8k6
subsystem: testing
tags: [isar, isar_community, test-infrastructure, flutter-test]

# Dependency graph
requires:
  - phase: 03-finance-core
    provides: IsarTestHarness (test/support/isar_test_harness.dart), created to
      close BL-01 and exercise real Isar query behavior in tests
provides:
  - IsarTestHarness.open() with an ordering guarantee (_tempDir assigned before
    Isar.open() is awaited), so a failed open leaves close() able to clean up
  - IsarTestHarness.open() guarded against double-open (throws StateError)
  - Monotonic per-process instance naming (no wall-clock collision risk)
  - Both self-tests in isar_test_harness_test.dart use addTearDown
affects: [test-infrastructure, item_dao_test (future harness consumer)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Real-Isar test harnesses must assign resource handles before awaiting
      the call that can fail, so cleanup can run on the failure path too."
    - "Forcing a duplicate CollectionSchema into Isar.open() is a reliable,
      honest way to make isar_community 3.3.2 throw synchronously
      (IsarError: Duplicate collection ...) for RED-phase test authoring,
      without mocking the harness under test."

key-files:
  created: []
  modified:
    - test/support/isar_test_harness.dart
    - test/support/isar_test_harness_test.dart

key-decisions:
  - "WR-01's RED test forces the throw honestly by passing a schema list
    Isar rejects (the same CollectionSchema twice, which isar_community
    3.3.2 rejects synchronously with IsarError: Duplicate collection),
    rather than falling back to the plan's ordering-invariant alternative
    — a reliable in-process trigger was found and verified against the
    unmodified harness before Task 2."
  - "WR-02's guard is a plain 'if (_isar != null) throw StateError(...)' at
    the top of open(), checked before core init or temp-dir creation, so a
    refused second call leaves the first instance completely untouched."
  - "IN-01's counter is a private top-level int, not a static class field,
    matching the existing _coreInitialized guard's structure in the same
    file."

requirements-completed: []

# Metrics
duration: 34min
completed: 2026-08-24
---

# Quick Task 260824-8k6: Close the IsarTestHarness review findings Summary

**Fixed IsarTestHarness's temp-dir leak on failed open (WR-01) and missing
double-open guard (WR-02), replaced its wall-clock instance name with a
monotonic counter (IN-01), and made both self-tests teardown-safe (IN-02) —
all four review findings from the 03-13/03-14 delta code review closed with
RED-first tests that were observed failing against the unmodified harness.**

## Performance

- **Duration:** 34 min
- **Started:** 2026-08-24T04:09:49Z (plan creation)
- **Completed:** 2026-08-24T04:43:04Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Two new tests (`test/support/isar_test_harness_test.dart`) prove the
  temp-dir leak and the double-open hole, observed FAILING against the
  unmodified harness before any fix was applied.
- `IsarTestHarness.open()` now assigns `_tempDir` before awaiting
  `Isar.open()`, so a failed open still leaves `close()` able to remove the
  orphaned directory (WR-01).
- `IsarTestHarness.open()` now throws `StateError` on a second call instead
  of silently overwriting `_isar`/`_tempDir` and orphaning the first
  instance (WR-02); doc comment updated to state this explicitly.
- The wall-clock-derived instance name (`DateTime.now().microsecondsSinceEpoch`)
  was replaced with a monotonically-incrementing private counter (IN-01).
- The harness's own `'close() removes the temp directory'` self-test now
  uses `addTearDown` instead of a trailing `close()` call, matching the
  first test, so cleanup runs even if the assertion fails (IN-02).
- All three verification gates (full test suite, `flutter analyze
  --fatal-warnings`, `dart run tool/check_architecture.dart`) hold at their
  pre-existing baselines with strictly more passing tests than before.

## Task Commits

Each task was committed atomically:

1. **Task 1: RED — add failing tests for WR-01/WR-02** - `0f55e3a` (test)
2. **Task 2: fix all four findings (WR-01, WR-02, IN-01, IN-02)** - `4d5a385` (fix)

_TDD-shaped quick task: RED (test) commit followed by GREEN (fix) commit._

## Files Created/Modified
- `test/support/isar_test_harness.dart` - `open()` now assigns `_tempDir`
  before awaiting `Isar.open()`, guards against a second call with
  `StateError`, and derives its instance name from a monotonic counter
  instead of `DateTime.now().microsecondsSinceEpoch`. Doc comments updated
  to match. Top-of-file binary-acquisition/race-mitigation doc comment
  untouched, as instructed.
- `test/support/isar_test_harness_test.dart` - Added two tests (WR-01 leak
  recovery, WR-02 double-open refusal) and converted the pre-existing
  `'close() removes the temp directory'` test to `addTearDown` (IN-02).

## Decisions Made
- Found a reliable, honest way to make `Isar.open()` itself throw for the
  WR-01 RED test: passing the same `CollectionSchema` twice in the schema
  list. `isar_community` 3.3.2 rejects this synchronously with
  `IsarError: Duplicate collection TransactionModel.`, verified with a
  disposable probe test against the unmodified harness (probe deleted
  before the real test was written; not part of any commit). This let the
  plan's honest-throw path be taken rather than its ordering-invariant
  fallback.
- Kept the WR-02 guard as the very first statement in `open()`, before
  `_coreInitialized` check or temp-dir creation, so a refused second call
  has zero side effects on the first (still-open) instance.

## Deviations from Plan

None - plan executed exactly as written. Both tasks completed as scoped;
no auto-fixes, no architectural questions, no out-of-scope changes.

## Issues Encountered
- A full-suite `flutter test --no-pub` run mid-session showed one unrelated
  test (`test/data/finance/net_worth_aggregate_completeness_test.dart`,
  the BL-01 DebtDao 600-row test) timing out with "did not complete [E]"
  under heavy concurrent load from earlier probe processes and background
  test runs in this session. Re-running that file in isolation passed in
  1 second (`+2: All tests passed!`), and a subsequent clean full-suite run
  passed all 306 tests in one pass. This was session-local resource
  contention, not a regression introduced by this task's changes — the
  isar_test_harness.dart changes have no relationship to
  net_worth_aggregate_completeness_test.dart's DebtDao/SavingsGoalDao
  collections.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `IsarTestHarness` is now safe for its named future consumer
  (`test/data/tasks/item_dao_test.dart`'s empty stub) to build on without
  inheriting the temp-dir leak, double-open hole, or clock-collision risk.
- The harness's network-dependent `initializeIsarCore(download: true)`
  residual risk remains documented and accepted, unchanged by this task.
- No blockers for future work touching `test/support/isar_test_harness.dart`.

---
*Quick task: 260824-8k6*
*Completed: 2026-08-24*
