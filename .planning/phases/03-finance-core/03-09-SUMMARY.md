---
phase: 03-finance-core
plan: 09
status: complete
completed: 2026-08-14
closes: [CR-04]
key_files:
  modified:
    - lib/data/finance/transaction/transaction_dao.dart
    - lib/domain/finance/transaction/transaction_repository.dart
    - lib/infrastructure/finance/transaction_repository_impl.dart
    - lib/application/finance/dashboard/home_dashboard_cubit.dart
    - lib/application/finance/dashboard/README.md
    - test/application/finance/home_dashboard_cubit_test.dart
    - test/widget_test.dart
  created:
    - test/data/finance/transaction_dao_ordering_test.dart
commits:
  - 5c9be2f  # fix(03-09): separate uncapped aggregate read from capped list read
  - 6ea2602  # fix(03-09): aggregate the dashboard from the complete transaction set
  - c3a0c80  # test(03-09): pin aggregate completeness and newest-first capping
gates:
  architecture_guard: "exit 0"
  analyze: "exit 0, 65 infos"
  tests: "287/287 passing (281 baseline + 6)"
---

# 03-09: Fix the dashboard balance past 500 transactions

Closes **CR-04** (Critical) from `03-REVIEW.md`.

## What was wrong

`TransactionDao.findAll()` was `.filter().deletedAtIsNull().limit(500).findAll()`
with no sort. Isar returns rows in id order, so the cap kept the **oldest** 500
transactions and discarded everything newer. That truncated list reached
`HomeDashboardCubit` through `TransactionRepositoryImpl.getTransactions()` and
fed `computeBalance`, `computeNetWorth` and `computeCategorySpend`.

Past transaction 501 the headline balance was simply wrong, and drifted further
every day the user kept logging. This falsified phase 03's own success
criterion 1 — "the balance on the dashboard updates immediately".

## What changed

**One read became two, because they have genuinely different requirements.**

- `findAllForAggregates()` — new, deliberately **uncapped and unsorted**.
  Aggregates are order-independent sums, but they must see every row. Surfaced
  through the domain interface as `getAllTransactionsForAggregates()`, with the
  same `try` / `Err(DatabaseFailure(...))` shape as every sibling method.
- `findAll()` — now `.sortByDateDesc()` **before** `.limit(500)`, so the cap
  retains the newest 500 for list rendering.
- `HomeDashboardCubit` now fetches through the aggregate path.
- The two doc comments that had become false were corrected: the interface no
  longer claims a flat "Limit 500", and the DAO class comment no longer claims
  *all* list queries apply a limit.

Both new doc comments record *why* rather than *what* — specifically that a
capped aggregate read produces a silently wrong total rather than an obviously
missing one, which is the entire failure mode. That is the sentence intended to
stop someone "optimising" the uncapped read back to the capped one.

## Verification

Gate re-measured on the merged result, each command run unpiped:

| Gate | Result |
|---|---|
| `dart run tool/check_architecture.dart` | exit 0 |
| `flutter analyze --no-fatal-infos --fatal-warnings` | exit 0, **65 infos** (budget held) |
| `flutter test --no-pub` | exit 0, **287/287** (281 baseline + 6 new) |

**Both mutations were actually run, not asserted.**

- Removing `sortByDateDesc()` → `+4 -1`, failing on
  *"findAll() has no descending date sort — an unsorted .limit(500) keeps the
  OLDEST 500 rows (CR-04)."*
- Repointing the aggregate path at `getTransactions()` → `+3 -1`, failing with
  `Expected: <1049999>` / `Actual: <50000>` — the silently wrong balance CR-04
  described, reproduced numerically.

Tree restored after each; `git diff --stat` empty on both files.

## Deviations

**1. Test strategy — source-assertion fallback, as the plan permitted.**
The plan asked for a real-Isar test if that infrastructure already existed, and
explicitly forbade inventing it otherwise. It does not exist: `initializeIsarCore`
appears nowhere, `test/data/tasks/item_dao_test.dart` is an empty stub, and
`migration_runner_test.dart` drives a Fake. So the fix is pinned at three levels
— repository read routing (mocked DAO), dashboard balance past the cap (mocked
repository), and the DAO query shape asserted by reading the source file, the
same pattern `test/l10n/l10n_test.dart` already uses.

Worth stating plainly: **level 3 asserts on source text, not behaviour.** It
will catch the sort being deleted, but it would not catch Isar changing what
`sortByDateDesc()` means. Levels 1 and 2 are behavioural and carry the real
weight. A real-Isar DAO test remains the stronger option if that infrastructure
is ever built.

**2. Interrupted execution.** The executor agent hit a session limit partway
through and terminated with tasks 1 and 2 committed, task 3's test file written
but uncommitted, and no SUMMARY. The orchestrator finished it inline rather than
dispatching a fresh agent. Nothing was reconstructed from notes — the partial
work was read, run, and gated directly.

**3. Gate breach caught during that handover.** The uncommitted test file had
never been gated, and it pushed `flutter analyze` to **66 infos** via one
`lines_longer_than_80_chars` at line 107. That is over the load-bearing 65
budget, and notable because the project's long-line count had been **0**
project-wide. Fixed by wrapping the `List.generate` call before committing.
Had the agent committed without gating, the breach would have landed on main.

## Carried forward

Wave 3 has three plans left — 03-10 (CR-01), 03-11 (CR-02), 03-12 (CR-03 +
WR-07). The new baseline for them is **287 tests**, not 281.
