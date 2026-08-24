---
quick_id: 260824-82b
slug: uncap-savingsgoaldao-findall-and-debtdao
status: complete
subsystem: database
tags: [isar, isar_community, dao, dashboard, net-worth]

key-files:
  created:
    - test/data/finance/net_worth_aggregate_completeness_test.dart
  modified:
    - lib/data/finance/goal/savings_goal_dao.dart
    - lib/data/finance/debt/debt_dao.dart

key-decisions:
  - "Uncapped both findAll() reads rather than splitting into a second aggregate-only method (as TransactionDao does), because both are dual-use (list screens/pickers AND dashboard totals) and the 500-row cap never binds in any realistic domain for goals or debts — splitting would add a method nothing needs."

duration: 7min
completed: 2026-08-24
---

# Quick Task 260824-82b: Uncap SavingsGoalDao.findAll and DebtDao.findAll Summary

**Removed the unsorted `.limit(500)` from `SavingsGoalDao.findAll` and `DebtDao.findAll`, closing the last two live instances of the BL-01 defect class that silently corrupted net-worth totals past 500 rows.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-08-24T03:48:23Z
- **Completed:** 2026-08-24T03:55:23Z
- **Tasks:** 2 completed
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments

- Added a real-Isar behavioral regression test (`net_worth_aggregate_completeness_test.dart`) proving both `SavingsGoalDao.findAll` and `DebtDao.findAll` dropped rows past 500 — observed FAILING (`Expected: <600> / Actual: <500>`, both groups) against the unmodified DAOs before any fix was applied
- Removed `.limit(500)` from both `findAll()` queries
- Rewrote both doc comments to name the exact total each read feeds (`computeGoalsSavedTotal` / `computeDebtTotal` → `computeNetWorth`) and to state the read must never be capped again, matching the wording pattern already established in `TransactionDao`
- Closed the last two known live instances of the BL-01 defect class (following 03-09's `TransactionDao.findAll` fix and 03-13/03-14's `findByMonth`/`findByLinkedGoal` fixes)

## Task Commits

Each task was committed atomically:

1. **Task 1: Real-Isar regression test proving both reads drop rows past 500 (RED)** - `730635b` (test)
2. **Task 2: Uncap both reads and correct their doc comments (GREEN)** - `ca5661c` (fix)

## Files Created/Modified

- `test/data/finance/net_worth_aggregate_completeness_test.dart` - New behavioral test (`IsarTestHarness`, real Isar collections) with two groups: `SavingsGoalDao.findAll` and `DebtDao.findAll`, each seeding 600 non-deleted rows plus one soft-deleted row and asserting on returned count/data, never on DAO source text
- `lib/data/finance/goal/savings_goal_dao.dart` - Removed `.limit(500)` from `findAll()`; doc comment now names `computeGoalsSavedTotal` → `computeNetWorth` and states the read must stay uncapped
- `lib/data/finance/debt/debt_dao.dart` - Removed `.limit(500)` from `findAll()`; doc comment now names `computeDebtTotal` → `computeNetWorth` and states the read must stay uncapped

## Decisions Made

- Uncapped rather than split into a second aggregate-only method (the pattern `TransactionDao` uses for `findAllForAggregates`). Both `SavingsGoalDao.findAll` and `DebtDao.findAll` are dual-use — feeding list screens/pickers as well as the dashboard totals — and neither goals nor debts realistically reach 500 active rows, so the cap never binds and splitting would add a method layer (DAO, repository interface, repository impl) with no caller. This decision was already made in the plan; execution followed it as specified.

## Deviations from Plan

None - plan executed exactly as written. One environment-only adjustment was needed to get the test harness running at all (see Issues Encountered below); it required no code or plan changes.

## Issues Encountered

- The worktree's `.dart_tool` had never had `flutter pub get` run in it, which caused every `flutter test` invocation (even on pre-existing test files, unrelated to this task) to crash inside `flutter_tools`' native-assets resolution (`StateError: Bad state: No element` in `testCompilerBuildNativeAssets`). Running `flutter pub get` once resolved it; no code, plan, or dependency version changes were needed. This is a first-run worktree environment quirk, not a defect introduced by this task, and is not tracked as a Rule 1-4 deviation because it involved no source change.

## Next Phase Readiness

- Both live instances of the BL-01 defect class identified in `deferred-items.md` are now closed. No further known-live capped-unsorted reads remain in the finance DAOs feeding money totals (goal/debt/transaction findAll and findByMonth/findByLinkedGoal are all now correctly uncapped or deliberately sorted-then-capped per CR-04 for `TransactionDao.findAll`'s display-list use).
- Out-of-scope items noted in the plan (the two `IsarTestHarness` warnings from `03-REVIEW.md`: temp-dir leak on `Isar.open()` throw, no double-`open()` guard) remain open as separate, real work — not addressed here.

---
*Quick task: 260824-82b*
*Completed: 2026-08-24*

## Self-Check: PASSED

- FOUND: test/data/finance/net_worth_aggregate_completeness_test.dart
- FOUND: lib/data/finance/goal/savings_goal_dao.dart (modified, no limit(500))
- FOUND: lib/data/finance/debt/debt_dao.dart (modified, no limit(500))
- FOUND commit: 730635b
- FOUND commit: ca5661c
