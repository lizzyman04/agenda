---
quick_id: 260824-82b
slug: uncap-savingsgoaldao-findall-and-debtdao
type: quick
created: 2026-08-24T03:48:23Z
source: .planning/phases/03-finance-core/deferred-items.md (logged during 03-14)
files_modified:
  - lib/data/finance/goal/savings_goal_dao.dart
  - lib/data/finance/debt/debt_dao.dart
  - test/data/finance/net_worth_aggregate_completeness_test.dart
---

# Quick Task 260824-82b: Uncap SavingsGoalDao.findAll and DebtDao.findAll

## Objective

Close the last two live instances of the BL-01 defect class. `SavingsGoalDao.findAll()` and
`DebtDao.findAll()` each carry `.limit(500)` with no `sortBy`. Isar returns rows in id
(insertion) order, so an unsorted cap keeps the **oldest** 500 and silently discards the
newest. Both feed money **totals**, not just display lists:

- `SavingsGoalDao.findAll()` → `GoalRepositoryImpl.getActiveGoals()` → `HomeDashboardCubit._reload` (`home_dashboard_cubit.dart:78`) → `computeGoalsSavedTotal` (a `.fold` sum)
- `DebtDao.findAll()` → `DebtRepositoryImpl.getDebts()` → `HomeDashboardCubit._reload` (`home_dashboard_cubit.dart:86`) → `computeDebtTotal` (a `.fold` sum)

Both sums land in `computeNetWorth` in `lib/application/finance/dashboard/dashboard_aggregator.dart`
(net worth = balance + goalsSaved − debt). Past 500 rows the net-worth figure reads wrong with
no error and no exception — exactly the failure mode that BL-01 produced for budget spend and
goal progress. Net worth's balance input is already safe: it comes from the uncapped
`TransactionDao.findAllForAggregates`.

## Why uncap rather than split

Plan 03-09 split `TransactionDao` into a capped-sorted list read (`findAll`) and an uncapped
aggregate read (`findAllForAggregates`) because transaction counts genuinely reach thousands,
so the display list needs a bound.

Goals and debts are different. Both `findAll()`s are dual-use — they feed list screens and
pickers as well as the net-worth totals:

- `getActiveGoals()` — `goal_list_cubit.dart:36`, `transaction_form_logic.dart:51`, `task_form_logic.dart:15`, plus the dashboard
- `getDebts()` — `debt_cubit.dart:110`, `task_form_logic.dart:25`, plus the dashboard

but the 500 cap never binds in any realistic domain: a user does not accumulate 500 active
savings goals or 500 active debts. Splitting would add a second method to every layer
(DAO, repository interface, repository impl) that no caller needs and that exists only to
carry a bound nothing reaches. Uncapping removes the defect class outright and matches
`findAllForAggregates`' existing precedent in the same package.

## Tasks

### Task 1 (RED first): Real-Isar regression test proving both reads drop rows past 500

Create `test/data/finance/net_worth_aggregate_completeness_test.dart`, modelled directly on
`test/data/finance/transaction_dao_aggregate_completeness_test.dart` (written by 03-14) and
using `IsarTestHarness` from `test/support/isar_test_harness.dart`.

Two groups, mirroring the 03-14 structure:

1. `SavingsGoalDao.findAll` — seed 600 non-deleted `SavingsGoalModel` rows, assert
   `findAll()` returns 600, not 500.
2. `DebtDao.findAll` — seed 600 non-deleted `DebtModel` rows, assert `findAll()` returns
   600, not 500.

Assert on **behavior** (the returned row count and data), never on DAO source text. The
pre-existing `test/data/finance/transaction_dao_ordering_test.dart` asserts on source text,
which is precisely why BL-01 survived a green 297-test suite — do not repeat that.

Failure messages must name the defect so a future reader understands it, e.g.
`"SavingsGoalDao.findAll must return every matching row, not just the first 500 — an unsorted
.limit(500) silently keeps the OLDEST 500 and drops the rest (BL-01 defect class)."`

**Observe this test FAIL against the current capped DAOs before touching Task 2.** A test that
passes before the fix has proven nothing. Expect `Expected: <600> / Actual: <500>` on both.

<verify>
<automated>flutter test --no-pub test/data/finance/net_worth_aggregate_completeness_test.dart</automated>
</verify>

<acceptance_criteria>
- The new test file exists and imports `IsarTestHarness` from `test/support/isar_test_harness.dart`.
- Run against the UNMODIFIED DAOs, both groups FAIL with `Expected: <600> / Actual: <500>`.
- `grep -n "readAsString\|File(" test/data/finance/net_worth_aggregate_completeness_test.dart` returns NO match — confirms the test asserts on behavior, not on DAO source text.
</acceptance_criteria>

<done>
A real-Isar behavioral test exists that fails against the current capped `SavingsGoalDao.findAll`
and `DebtDao.findAll`, with the failure observed and recorded, not assumed.
</done>

### Task 2: Uncap both reads and correct their doc comments

In `lib/data/finance/goal/savings_goal_dao.dart`, remove `.limit(500)` from `findAll()` and
replace the doc comment `/// Returns all active (non-deleted) savings goals. Limit 500.` with
one that states the read is deliberately uncapped, names the total it feeds
(`computeGoalsSavedTotal` → `computeNetWorth`), and says never to add `.limit()` back.

Make the same change in `lib/data/finance/debt/debt_dao.dart` for `findAll()`, naming
`computeDebtTotal` → `computeNetWorth`.

Follow the wording pattern already established at the top of
`lib/data/finance/transaction/transaction_dao.dart` and on its `findByMonth` /
`findByLinkedGoal` doc comments — a capped read here produces a silently WRONG total rather
than an obviously missing one.

Change nothing else in either filter chain. Do not touch `findById`, any write method, or any
other DAO.

<verify>
<automated>flutter test --no-pub && flutter analyze --no-fatal-infos --fatal-warnings && dart run tool/check_architecture.dart</automated>
</verify>

<acceptance_criteria>
- `grep -n "limit(500)" lib/data/finance/goal/savings_goal_dao.dart lib/data/finance/debt/debt_dao.dart` returns NO match.
- Task 1's test now passes both groups.
- Each `findAll()` doc comment names the specific total it feeds and says not to reintroduce `.limit()`.
- `flutter test --no-pub`: strictly more than 302 passing, exit 0.
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, no increase over the 65-issue budget, 0 `lines_longer_than_80_chars`.
- `dart run tool/check_architecture.dart`: exit 0.
</acceptance_criteria>

<done>
Both reads are uncapped, both doc comments explain why, the regression test that failed in
Task 1 now passes, and all three gates hold at their current baselines.
</done>

## Out of scope

- `TransactionCategoryDao` (13 seeded categories, and its `findAll`/`findByType` feed pickers, not sums).
- `RecurringPaymentDao.findAll` and `TransactionDao.findAll` — display lists; the latter is
  deliberately sorted-then-capped per CR-04.
- `BudgetDao.findByMonth` — bounded by category count.
- `ItemDao`'s five capped reads — tasks domain, no money total involved.
- The two `IsarTestHarness` warnings from `03-REVIEW.md` (temp-dir leak on `Isar.open()` throw;
  no double-`open()` guard). Real, but separate work.
