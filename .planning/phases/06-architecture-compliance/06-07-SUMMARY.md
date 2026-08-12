---
phase: 06
plan: 07
subsystem: finance-application-layer
tags: [architecture-compliance, refactor, pure-functions, finance]
dependency-graph:
  requires: []
  provides:
    - lib/application/finance/dashboard/dashboard_aggregator.dart
    - lib/application/finance/budget/budget_aggregator.dart
  affects:
    - lib/application/finance/dashboard/home_dashboard_cubit.dart
    - lib/application/finance/budget/budget_cubit.dart
tech-stack:
  added: []
  patterns:
    - "Pure-function extraction from cubits (Pattern 3, same shape as 06-04's recurring_completion.dart)"
key-files:
  created:
    - lib/application/finance/dashboard/dashboard_aggregator.dart
    - lib/application/finance/budget/budget_aggregator.dart
    - test/application/finance/dashboard_aggregator_test.dart
    - test/application/finance/budget_aggregator_test.dart
  modified:
    - lib/application/finance/dashboard/home_dashboard_cubit.dart
    - lib/application/finance/budget/budget_cubit.dart
decisions:
  - "computeNetWorth extracted as a pure one-line combination function (balance + goalsSaved - debt) rather than left inline in the cubit, reconciling a conflict between the plan's <action> text (says keep inline) and its own must_haves artifacts/key_links list (which names computeNetWorth as one of the extracted functions and greps for the call pattern in the cubit). Extracting it is harmless (same formula, same result) and satisfies both the artifact spec and the key_links regex check."
  - "Function names follow the task's <action> spec exactly (computeGoalsSavedTotal, computeDebtTotal, computeTaggedByGoal) rather than the shorter names listed in must_haves.artifacts (computeGoalsSaved) — action-level detail took precedence as the more specific instruction, and the names match the local variables they replace in the cubit (goalsSavedTotal, debtTotal)."
metrics:
  duration_minutes: 35
  completed: 2026-08-11
---

# Phase 06 Plan 07: Extract Dashboard and Budget Aggregation Math Summary

Extracted the pure aggregation math out of `HomeDashboardCubit` and `BudgetCubit` into two new files — `dashboard_aggregator.dart` and `budget_aggregator.dart` — leaving each cubit with only repository orchestration (`isClosed` checks, `emit()` calls). Both cubits are now at or under the 150-line architecture cap; the extracted formulas (D-07 balance, D-08 net worth, D-09 category-spend) are unit-testable in isolation for the first time.

## What Was Built

### Task 1: `dashboard_aggregator.dart`

Six top-level pure functions extracted verbatim from `HomeDashboardCubit._reload()`:
- `computeBalance(transactions)` — D-07 income/expense single-pass sum
- `computeTaggedByGoal(transactions)` — goalId → tagged-amount map
- `computeGoalsSavedTotal(goals, taggedByGoal)` — fold over `SavingsGoal.amountSavedCents`
- `computeDebtTotal(debts)` — toPay && !isPaid filter+fold (D-08)
- `computeNetWorth({balanceCents, goalsSavedTotalCents, debtTotalCents})` — the one-line combination formula
- `computeCategorySpend(transactions, {year, month})` — D-09 expense-filter-by-month groupBy, including soft-delete exclusion

`home_dashboard_cubit.dart` went from 202 → 150 lines. `dashboard_aggregator.dart` is 85 lines.

### Task 2: `budget_aggregator.dart`

`mergeBudgetData({required transactions, required budgets})` moves the spentMap grouping, limitMap building, combined-map building, and the "categories with limits but no spend" backfill loop into one pure function, matching the signature specified in the plan's must_haves.

`budget_cubit.dart` went from 155 → 132 lines. `budget_aggregator.dart` is 47 lines.

### Bonus: direct aggregator unit tests

The plan noted that if the aggregation math had no test asserting on concrete numbers, that was worth flagging — but both `home_dashboard_cubit_test.dart` (7 tests) and `budget_cubit_test.dart` (3 tests) already assert on exact figures (balanceCents, netWorthCents, categorySpend, spentCents), so the regression gate was solid going in. Since the refactor now makes the math directly testable without mocking three repositories, I added:
- `test/application/finance/dashboard_aggregator_test.dart` (8 tests) — each of the six functions in isolation, including empty-list and soft-delete edge cases not exercised by the cubit test suite
- `test/application/finance/budget_aggregator_test.dart` (4 tests) — spend-only, limit-only, both-present, and empty-input cases for `mergeBudgetData`

## Verification

- `flutter analyze lib/application/finance/dashboard/ lib/application/finance/budget/` — clean, zero issues (two transient `comment_references` info-lints from bracket-doc-comments referencing types not imported in scope were fixed by switching to backtick code-spans)
- `flutter test test/application/finance/home_dashboard_cubit_test.dart test/application/finance/budget_cubit_test.dart` — 10/10 pass, unchanged from before the refactor (same test count, same assertions)
- `flutter test test/application/finance/` (full directory, including new aggregator tests) — 32/32 pass
- `wc -l`: `home_dashboard_cubit.dart` 150, `dashboard_aggregator.dart` 85, `budget_cubit.dart` 132, `budget_aggregator.dart` 47 — all comfortably at or under the 150-line cap
- `dart run tool/check_architecture.dart` — neither `home_dashboard_cubit.dart` nor `budget_cubit.dart` appear in the LINES violation list (remaining violations listed are pre-existing, in unrelated presentation-layer/other-application-layer files, out of scope for this plan)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Lint] Fixed invalid doc-comment bracket references**
- **Found during:** Task 1 verification (`flutter analyze`)
- **Issue:** `[HomeDashboardCubit]` and `[dashboard_aggregator.dart]` in doc comments triggered `comment_references` info-lints because those names aren't in scope at the reference site (one's a filename, not a symbol; the other lives in a different file that doesn't import back).
- **Fix:** Changed to backtick code-spans (`` `HomeDashboardCubit` ``, `` `dashboard_aggregator.dart` ``) instead of bracket doc-references.
- **Files modified:** `lib/application/finance/dashboard/dashboard_aggregator.dart`, `lib/application/finance/dashboard/home_dashboard_cubit.dart`
- **Commit:** 28f7f88

**2. [Rule 1 - Lint] Removed redundant default-value argument in a new test**
- **Found during:** analyzing the bonus aggregator test files
- **Issue:** `_makeTx(amountCents: 5000)` triggered `avoid_redundant_argument_values` since 5000 is the helper's default.
- **Fix:** Changed to `_makeTx()`.
- **Files modified:** `test/application/finance/dashboard_aggregator_test.dart`
- **Commit:** 17d1b73

### Plan Internal Inconsistency Reconciled (not a deviation from intent, but worth flagging)

The plan's `<task><action>` text says the netWorth combination formula "stays in the cubit... it's the orchestration step, not extracted math." But the plan's own frontmatter `must_haves.artifacts` lists `computeNetWorth` as one of the four functions `dashboard_aggregator.dart` "provides", and `must_haves.key_links` requires the pattern `computeNetWorth\(` to appear in the cubit's call site. I extracted `computeNetWorth` as a trivial pure one-liner and called it from the cubit, satisfying both the artifact spec and the key_links grep check without contradicting the underlying intent (the formula is unchanged either way — inline or extracted, `balance + goalsSavedTotal - debtTotal` is the same computation).

## Known Stubs

None.

## Threat Flags

None. This plan only moved existing pure computation into new files; no new network endpoints, auth paths, file access, or schema changes were introduced. The plan's own threat register (T-06-07-01, tampering/financial-calculation-drift) is mitigated by the byte-identical formula transplant and the unchanged, passing regression test suites plus the new direct aggregator tests.

## Self-Check: PASSED

- FOUND: lib/application/finance/dashboard/dashboard_aggregator.dart
- FOUND: lib/application/finance/budget/budget_aggregator.dart
- FOUND: test/application/finance/dashboard_aggregator_test.dart
- FOUND: test/application/finance/budget_aggregator_test.dart
- FOUND commit: 28f7f88 (refactor: dashboard aggregation extraction)
- FOUND commit: e129c1b (refactor: budget merge extraction)
- FOUND commit: 17d1b73 (test: aggregator unit tests)
