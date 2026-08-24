---
phase: 03-finance-core
plan: 14
subsystem: database
tags: [isar_community, flutter_test, mocktail, bl-01, data-layer]

# Dependency graph
requires:
  - phase: 03-finance-core
    provides: IsarTestHarness (test/support/isar_test_harness.dart, plan 03-13) — real isar_community instance for flutter test
provides:
  - TransactionDao.findByMonth and findByLinkedGoal uncapped, closing BL-01
  - Corrected transaction_dao.dart class doc naming all three uncapped methods
  - test/data/finance/transaction_dao_aggregate_completeness_test.dart — real-Isar behavioral regression coverage for BL-01
affects: [03-VERIFICATION]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Real-Isar DAO test pattern: mock only IsarService.db, open a genuine Isar via IsarTestHarness, exercise the DAO's actual query chain — supersedes source-text assertions for defects that live inside a query shape"

key-files:
  created:
    - test/data/finance/transaction_dao_aggregate_completeness_test.dart
  modified:
    - lib/data/finance/transaction/transaction_dao.dart

key-decisions:
  - "Uncapped both findByMonth and findByLinkedGoal (no sortBy added) rather than sorting-then-capping, mirroring findAllForAggregates exactly — both feed order-independent sums (budget spend, goal progress), not paginated lists"
  - "Reworded the class doc comment to avoid the literal substring '.limit(500)' in prose, so the plan's own acceptance grep ('exactly one match') isn't defeated by the doc comment itself"

requirements-completed: [FIN-04, FIN-06]

# Metrics
duration: 30min
completed: 2026-08-24
---

# Phase 03 Plan 14: Uncap findByMonth/findByLinkedGoal (BL-01) Summary

**Removed the unsorted `.limit(500)` from `TransactionDao.findByMonth` and `findByLinkedGoal` (both aggregate reads feeding budget spend and goal progress totals), proven by a real-Isar behavioral test observed RED against the pre-fix code and GREEN after, with both cap-reintroduction mutations confirmed.**

## Performance

- **Duration:** ~30 min (includes worktree resync + `flutter pub get` after `git reset --hard` to the expected base commit, needed before any `flutter test` invocation would run)
- **Completed:** 2026-08-24T05:27:14+02:00
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments

- `TransactionDao.findByMonth` and `TransactionDao.findByLinkedGoal` no longer carry `.limit(500)` — both are now deliberately uncapped aggregate reads, exactly mirroring `findAllForAggregates`'s existing pattern (query shape and doc-comment style).
- The class-level doc comment at the top of `transaction_dao.dart` no longer claims `findAllForAggregates` is "the single, deliberate exception" to the cap. It now names all three uncapped methods (`findAllForAggregates`, `findByMonth`, `findByLinkedGoal`) and states `findAll` is the only remaining capped list query (sorted newest-first before the cap, per CR-04).
- `test/data/finance/transaction_dao_aggregate_completeness_test.dart` is a genuinely behavioral regression test, using the 03-13 `IsarTestHarness` to open a real `isar_community` collection with only `IsarService` mocked. It was run against the still-capped DAO and observed failing (`Expected: <600> / Actual: <500>` for both methods) before Task 2's fix, and is green after.
- Two mutation checks were run: reintroducing `.limit(500)` on `findByMonth` alone fails only that group; reintroducing it on `findByLinkedGoal` alone fails only that group. Both confirm the new tests are load-bearing, not merely present.
- Full suite: 302/302 passing (300 baseline + 2 new), `flutter analyze --no-fatal-infos --fatal-warnings` exactly 65 issues with 0 long lines, `dart run tool/check_architecture.dart` PASS.

## Task Commits

Each task was committed atomically:

1. **Task 1: RED — behavioral tests proving both methods drop rows past 500** - `cc98a66` (test)
2. **Task 2: GREEN — uncap both methods, correct the class doc, mutation check** - `705ef49` (fix)

_Note: this plan's `tdd="true"` gate applies to Task 1 only (the plan's own frontmatter marks Task 1, not the whole plan, as TDD); Task 2 is the fix + doc correction + mutation-check task, not a separate REFACTOR step._

## RED evidence (Task 1, quoted verbatim)

Run against the still-capped DAO at HEAD before any Task 2 edit:

```
BL-01 · findByMonth returns every row past the 500-row cap returns all 600 in-month expense rows, not merely the first 500 [E]
  Expected: <600>
    Actual: <500>
  findByMonth must return every matching row, not just the first 500 (BL-01) — an unsorted .limit(500) silently keeps the OLDEST 500 and drops the rest.

BL-01 · findByLinkedGoal returns every row past the 500-row cap returns all 600 tagged rows, not merely the first 500 [E]
  Expected: <600>
    Actual: <500>
  findByLinkedGoal must return every matching row, not just the first 500 (BL-01) — an unsorted .limit(500) silently keeps the OLDEST 500 and drops the rest.

00:01 +0 -2: Some tests failed.
```

The three exclusion assertions per group (wrong type/month/goal, soft-deleted rows) passed even pre-fix, as expected — those filters were already correct; only the row-count cap was the defect.

## Mutation check evidence (Task 2, quoted verbatim)

**Mutation A — `.limit(500)` reintroduced on `findByMonth` only:**

```
BL-01 · findByMonth returns every row past the 500-row cap returns all 600 in-month expense rows, not merely the first 500 [E]
  Expected: <600>
    Actual: <500>
  findByMonth must return every matching row, not just the first 500 (BL-01) — an unsorted .limit(500) silently keeps the OLDEST 500 and drops the rest.

BL-01 · findByLinkedGoal returns every row past the 500-row cap returns all 600 tagged rows, not merely the first 500
00:02 +1 -1: Some tests failed.
```

`findByMonth` group fails; `findByLinkedGoal` group still passes (`+1`). Reverted immediately after (`git diff` on the file confirmed clean before the next mutation).

**Mutation B — `.limit(500)` reintroduced on `findByLinkedGoal` only:**

```
BL-01 · findByMonth returns every row past the 500-row cap returns all 600 in-month expense rows, not merely the first 500
BL-01 · findByLinkedGoal returns every row past the 500-row cap returns all 600 tagged rows, not merely the first 500 [E]
  Expected: <600>
    Actual: <500>
  findByLinkedGoal must return every matching row, not just the first 500 (BL-01) — an unsorted .limit(500) silently keeps the OLDEST 500 and drops the rest.

00:02 +1 -1: Some tests failed.
```

`findByLinkedGoal` group fails; `findByMonth` group still passes (`+1`). Reverted afterward, then verified `grep -n "limit(500)" lib/data/finance/transaction/transaction_dao.dart` shows exactly one match (line 48, inside `findAll()`).

## Files Created/Modified

- `test/data/finance/transaction_dao_aggregate_completeness_test.dart` - Real-Isar behavioral test: seeds 600+ rows per group via `isar.writeTxn(() => collection.putAll(...))`, opens the DAO against a real Isar via `IsarTestHarness` with only `IsarService` mocked (`MockIsarService`), asserts both uncapped methods return every matching row and still exclude wrong-type/out-of-range/soft-deleted/wrong-goal rows.
- `lib/data/finance/transaction/transaction_dao.dart` - Removed `.limit(500)` from `findByMonth` and `findByLinkedGoal`; rewrote both methods' doc comments and the class-level doc comment to name all three uncapped methods and correct the false "single exception" claim. File is 111 lines (well under the 150-line cap).

## Decisions Made

- Uncapped both defective methods rather than sorting-then-capping — they feed order-independent sums (budget spend total, goal-progress total), so a sort would add cost with no correctness benefit; this exactly mirrors the accepted `findAllForAggregates` design from CR-04/03-09.
- Reworded the class doc to describe the cap as "a 500-row cap" rather than repeating the literal `.limit(500)` substring in prose, so the plan's acceptance criterion (`grep -n "limit(500)"` showing exactly one match) isn't accidentally defeated by the corrected doc comment itself.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Worktree required `git reset --hard` to the expected base commit, then a fresh `flutter pub get`**
- **Found during:** Setup, before Task 1
- **Issue:** The worktree's `HEAD` (`9ae0000`) was behind the base commit the orchestrator specified (`3d3fb2f`, which includes 03-13's merge). `flutter test` also crashed with a Flutter-tool-internal `StateError: Bad state: No element` in `testCompilerBuildNativeAssets` until dependencies were refetched.
- **Fix:** Ran `git reset --hard 3d3fb2f544f8e23fdaf596609ebe030d6039170f` (per the plan's own `<worktree_branch_check>` instructions), then `flutter pub get`, which resolved the tool crash.
- **Files modified:** None (tooling/dependency state only; `git diff --stat` after `pub get` showed no `pubspec.lock` changes).
- **Verification:** `flutter test --no-pub test/support/isar_test_harness_test.dart` passed cleanly afterward.

**2. [Rule 1 - Bug] Fixed 4 `avoid_redundant_argument_values` analyzer infos introduced by Task 1's own test file**
- **Found during:** Task 2 (running `flutter analyze` to confirm the 65-issue budget)
- **Issue:** Task 1's test file explicitly passed `DateTime(2026, 1, 1)` / `DateTime(2026, 2, 1)` / `DateTime(2026, 1)` where the constructor's own default `month`/`day` values (both `1`) made the explicit argument redundant — 4 new analyzer infos, pushing the count from 65 to 69.
- **Fix:** Simplified to `DateTime(2026)` / `DateTime(2026, 2)`, semantically identical, no behavior change.
- **Files modified:** `test/data/finance/transaction_dao_aggregate_completeness_test.dart` (folded into Task 2's commit, since it was required to satisfy Task 2's own verification gate).
- **Verification:** `flutter analyze --no-fatal-infos --fatal-warnings` returns to exactly 65 issues; the test file's two groups still pass in full.

---

**Total deviations:** 2 auto-fixed (1 blocking/tooling, 1 bug/lint)
**Impact on plan:** No scope creep. Both fixes were prerequisites for running the plan's own verification gates as specified; neither touched `TransactionDao`'s query logic beyond what the plan mandated.

## Issues Encountered

None beyond the two deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Both BL-01 gaps from `03-VERIFICATION.md` (roadmap success criteria 2 and 3 — budget progress and savings-goal progress) are now closed: `BudgetCubit._reload` and `GoalCubit._refreshGoal` both read from uncapped DAO queries, so their totals can no longer silently understate past 500 transactions. Phase 03 is ready for `/gsd-verifier` to rerun; per `.planning/STATE.md`, the phase stays NOT complete until that rerun returns `passed`. `test/data/tasks/item_dao_test.dart`'s empty stub remains unfilled and unruled-on — still out of scope for this plan, as noted by 03-13's SUMMARY.

---
*Phase: 03-finance-core*
*Completed: 2026-08-24*

## Self-Check: PASSED

- FOUND: test/data/finance/transaction_dao_aggregate_completeness_test.dart
- FOUND: lib/data/finance/transaction/transaction_dao.dart
- FOUND: .planning/phases/03-finance-core/03-14-SUMMARY.md
- FOUND: commit cc98a66 (Task 1)
- FOUND: commit 705ef49 (Task 2)
