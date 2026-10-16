---
phase: 04-notifications-backup
plan: 09
subsystem: data
tags: [isar, isar_community, query, reactive, watchLazy, notifications, bl-01]

requires:
  - phase: 03-finance-core
    provides: "IsarTestHarness real-Isar test pattern and the BL-01/CR-04 sort-before-limit lesson"
provides:
  - "findRemindableItems: soonest-N remindable items, sorted by due date BEFORE the limit"
  - "findItemsDueInWindow: every remindable item in [from, toExclusive), no cap"
  - "ItemDao.findRemindable / findDueInWindow and ItemRepository.getRemindableItems / getItemsDueInWindow"
  - "BudgetRepository.watchChanges and RecurringPaymentRepository.watchChanges (BudgetDao / RecurringPaymentDao .watchLazy)"
affects: [04-07 reminder planner, 04-14 budget alert evaluator, 04-notifications coordinator, briefing counts]

actuals:
  tokens: 4943
  tasks: 3
  commits: 3
plan_head_before: df2cb3ca8c8c9f0ade7cfb0e1aa71b1da3f310e2

tech-stack:
  added: []
  patterns:
    - "Reminder reads live in top-level query functions over IsarCollection (item_reminder_queries.dart), the ItemDao only delegates; sort precedes limit"
    - "Reactive repositories expose Stream<void> watchChanges() backed by DAO watchLazy(), same shape as DebtRepository"

key-files:
  created:
    - lib/data/tasks/item_reminder_queries.dart
    - test/data/tasks/item_reminder_queries_test.dart
    - test/data/finance/reactive_watch_test.dart
  modified:
    - lib/data/tasks/item_dao.dart
    - lib/domain/tasks/item_repository.dart
    - lib/infrastructure/tasks/item_repository_impl_queries.dart
    - lib/domain/finance/budget/budget_repository.dart
    - lib/data/finance/budget/budget_dao.dart
    - lib/infrastructure/finance/budget_repository_impl.dart
    - lib/domain/finance/recurring/recurring_payment_repository.dart
    - lib/data/finance/recurring/recurring_payment_dao.dart
    - lib/data/finance/recurring/recurring_payment_model.dart
    - lib/infrastructure/finance/recurring_payment_repository_impl.dart
    - test/widget_test.dart

key-decisions:
  - "Reminder reads are separate methods, not a flag on the display queries: the display queries keep their 500 cap, the new ones are documented as not for display"
  - "findDueInWindow has no limit call at all (a briefing count capped at 500 is wrong); findRemindable sorts by due date then limits so the cap keeps the soonest rows"

patterns-established:
  - "Regression tests for sort-before-limit seed ids in the OPPOSITE order of the sort key, so an id-ordered cap returns visibly wrong rows"
  - "watchLazy tests subscribe BEFORE writing, since a lazy watcher only reports changes made while listening"

requirements-completed: [NOTF-01, NOTF-02, NOTF-03, NOTF-04, NOTF-07]

coverage:
  - id: D1
    description: "Reminder read returns the soonest N remindable items (sorted before limited), so 700 open tasks yield the 60 earliest, not the 60 lowest ids"
    requirement: "NOTF-01"
    verification:
      - kind: integration
        ref: "test/data/tasks/item_reminder_queries_test.dart#findRemindable sorts by due date BEFORE it limits"
        status: pass
    human_judgment: false
  - id: D2
    description: "Briefing window read returns every remindable item due in [from, toExclusive) with no cap (650 rows returned, boundary row excluded)"
    requirement: "NOTF-02"
    verification:
      - kind: integration
        ref: "test/data/tasks/item_reminder_queries_test.dart#findDueInWindow is uncapped"
        status: pass
    human_judgment: false
  - id: D3
    description: "Repository wrappers return Err(DatabaseFailure) when the DAO throws and map real rows when it does not"
    requirement: "NOTF-03"
    verification:
      - kind: unit
        ref: "test/data/tasks/item_reminder_queries_test.dart#ItemRepositoryImpl reminder reads"
        status: pass
    human_judgment: false
  - id: D4
    description: "BudgetRepository.watchChanges emits after each budget write"
    requirement: "NOTF-04"
    verification:
      - kind: integration
        ref: "test/data/finance/reactive_watch_test.dart#BudgetDao.watchLazy emits after each save"
        status: pass
    human_judgment: false
  - id: D5
    description: "RecurringPaymentRepository.watchChanges emits after each payment write; stale comments claiming Phase 4 advances nextDueDate corrected"
    requirement: "NOTF-07"
    verification:
      - kind: integration
        ref: "test/data/finance/reactive_watch_test.dart#RecurringPaymentDao.watchLazy emits after each save"
        status: pass
    human_judgment: false

duration: 18min
completed: 2026-10-16
status: complete
---

# Phase 4 Plan 09: Reminder Reads and Reactive Watch Streams Summary

**Sorted-then-limited "soonest N" reminder read, uncapped due-date window read, and `watchChanges()` on the budget and recurring-payment repositories, guarded by 700-row and 650-row real-Isar regression tests.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-10-16T06:03:00Z
- **Completed:** 2026-10-16T06:21:00Z
- **Tasks:** 3
- **Files modified:** 14 (3 created, 11 modified)

## Accomplishments

- Added `findRemindableItems` and `findItemsDueInWindow` as top-level functions over `IsarCollection<ItemModel>`. The first sorts by due date before applying the limit; the second has no limit call at all. Both carry a doc comment naming the BL-01/CR-04 class and marking them as not display reads.
- Plumbed them through `ItemDao` (still exactly 150 lines), `ItemRepository` and the `_ItemRepositoryImplQueries` mixin with the project's `Err(DatabaseFailure)` try/catch idiom.
- Added `Stream<void> watchChanges()` to `BudgetRepository` and `RecurringPaymentRepository`, backed by a new `watchLazy()` on each DAO, exactly like `DebtRepository`. Removed the "not reactive" doc claims.
- Corrected the stale comments that claimed Phase 4 advances `nextDueDate`: the planner computes the effective date in memory and nothing is written (D-15).
- Updated the `_StubItemRepository`, `_StubBudgetRepository` and `_StubRecurringPaymentRepository` in `test/widget_test.dart` so the shell test still compiles.

## Task Commits

1. **Task 1: Tracer, soonest-N reminder read and uncapped window read** - `3eb4d32` (feat)
2. **Task 2: BudgetRepository.watchChanges** - `22f61c4` (feat)
3. **Task 3: RecurringPaymentRepository.watchChanges** - `f26b3a1` (feat)

**Plan metadata:** committed separately as `docs(04-09)`.

## Files Created/Modified

- `lib/data/tasks/item_reminder_queries.dart` - the two uncapped/sorted reminder query functions
- `lib/data/tasks/item_dao.dart` - `findRemindable` and `findDueInWindow` delegates (150 lines, at the cap)
- `lib/domain/tasks/item_repository.dart` - `getRemindableItems`, `getItemsDueInWindow`
- `lib/infrastructure/tasks/item_repository_impl_queries.dart` - implementations
- `lib/domain/finance/budget/budget_repository.dart`, `lib/data/finance/budget/budget_dao.dart`, `lib/infrastructure/finance/budget_repository_impl.dart` - budget `watchChanges`
- `lib/domain/finance/recurring/recurring_payment_repository.dart`, `lib/data/finance/recurring/recurring_payment_dao.dart`, `lib/infrastructure/finance/recurring_payment_repository_impl.dart` - recurring-payment `watchChanges` and comment corrections
- `lib/data/finance/recurring/recurring_payment_model.dart` - stale comment corrected (comment-only; Isar schema unchanged)
- `test/data/tasks/item_reminder_queries_test.dart` - real-Isar sort-before-limit and uncapped-window regressions plus repository error mapping
- `test/data/finance/reactive_watch_test.dart` - real-Isar emission tests for both DAOs
- `test/widget_test.dart` - stub repositories updated

## Decisions Made

- Kept the reminder reads as dedicated methods rather than loosening the display queries, so the 500 display cap on the existing queries is untouched.
- Followed the plan's instruction to leave `RecurringPaymentDao.findAll` unchanged (isActive-descending, due-date-ascending, 500 cap).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Stale "Phase 4 advances nextDueDate" comment in the Isar model**
- **Found during:** Task 3
- **Issue:** `recurring_payment_model.dart` carried the same false claim the plan told me to correct in the DAO and impl (it is not in the plan's `files_modified`). Leaving it would contradict the corrected comments next to it.
- **Fix:** Reworded the class doc and the `nextDueDate` field doc. Comment-only, so `recurring_payment_model.g.dart` and the collection schema are unaffected.
- **Files modified:** `lib/data/finance/recurring/recurring_payment_model.dart`
- **Verification:** `flutter analyze` unchanged at 63 issues; full suite green.
- **Committed in:** `f26b3a1`

---

**Total deviations:** 1 auto-fixed (1 Rule 1).
**Impact on plan:** Documentation-only; no behavior or schema change, no scope creep.

## Issues Encountered

- The first draft of the budget emission test used `StreamIterator`, which both lacked a `dart:async` import and subscribes lazily on the first `moveNext` (after the write, so the event would have been missed). Replaced with a small subscribe-first counter helper.
- The Task 3 verify command's analyzer budget is 65; the run measured 63, so the plan's new files added no issues (one `comment_references` info and two dynamic-call infos in my first test draft were fixed before commit).

## Verification Results

- Mutation check: removing `sortByDueDate` and capping the window read at 500 made the sort-before-limit and uncapped-window tests fail (`Expected: <650> Actual: <500>`); the file was restored and re-run green.
- `flutter test --no-pub` (full suite): 410 passed, exit 0.
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, 63 issues (budget 65).
- `dart run tool/check_architecture.dart`: PASS.

## Known Stubs

None. The `Success(<Item>[])` and `Stream.empty()` returns in `test/widget_test.dart` are the existing shell-test stub pattern, not production stubs.

## Threat Flags

None. No new network, auth or trust-boundary surface; T-04-09-01 and T-04-09-02 are mitigated by the 700-row and 650-row tests.

## Next Phase Readiness

The planner and coordinator plans can now call `getRemindableItems` / `getItemsDueInWindow` and subscribe to the item, budget and recurring-payment `watchChanges()` streams.

## Self-Check: PASSED

- Created files exist: `item_reminder_queries.dart`, `item_reminder_queries_test.dart`, `reactive_watch_test.dart`.
- Commits present: `3eb4d32`, `22f61c4`, `f26b3a1`; measured count `rev-list df2cb3c..HEAD` = 3.
- Acceptance criteria re-run: `sortByDueDate` present (2 matches), `watchChanges` present in both repository interfaces, no "not reactive" text remains, architecture guard PASS, `item_dao.dart` at 150 lines.
