---
phase: "03-finance-core"
plan: "03"
subsystem: "application/finance"
tags: ["cubit", "bloc", "tdd", "application-layer", "dashboard", "reactive", "finance"]
dependency_graph:
  requires:
    - "03-01: domain entities and repository interfaces"
    - "03-02: data layer, DAOs, repository implementations, DI wiring"
  provides:
    - "lib/application/finance/transaction/transaction_cubit.dart"
    - "lib/application/finance/transaction/transaction_state.dart"
    - "lib/application/finance/budget/budget_cubit.dart"
    - "lib/application/finance/budget/budget_state.dart"
    - "lib/application/finance/goal/goal_cubit.dart"
    - "lib/application/finance/goal/goal_state.dart"
    - "lib/application/finance/goal/goal_list_cubit.dart"
    - "lib/application/finance/goal/goal_list_state.dart"
    - "lib/application/finance/debt/debt_cubit.dart"
    - "lib/application/finance/debt/debt_state.dart"
    - "lib/application/finance/recurring/recurring_payment_cubit.dart"
    - "lib/application/finance/recurring/recurring_payment_state.dart"
    - "lib/application/finance/dashboard/home_dashboard_cubit.dart"
    - "lib/application/finance/dashboard/home_dashboard_state.dart"
  affects:
    - "03-04: Presentation screens wire BlocProviders to these cubits"
    - "03-05: HomeDashboardCubit drives the finance dashboard screen"
tech_stack:
  added: []
  patterns:
    - "watchChanges().listen() + start() + _reload() reactive cubit pattern (replicated from TaskListCubit)"
    - "Double isClosed guard (before async gap + after await) in every _reload()"
    - "Sealed state class + Equatable final subclasses (Initial, Loading, Loaded, Error)"
    - "GoalCubit as detail cubit (no auto-start) with _refreshGoal() aggregate pattern"
    - "HomeDashboardCubit single-pass Dart aggregation — no N+1 Isar queries"
    - "BudgetCubit subscribes to TransactionRepository.watchChanges() (not BudgetRepository)"
    - "RecurringPaymentCubit non-reactive (no watchChanges) — load-on-demand"
    - "@injectable annotation on all 7 cubit classes for DI resolution"
key_files:
  created:
    - "lib/application/finance/transaction/transaction_cubit.dart"
    - "lib/application/finance/transaction/transaction_state.dart"
    - "lib/application/finance/budget/budget_cubit.dart"
    - "lib/application/finance/budget/budget_state.dart"
    - "lib/application/finance/goal/goal_cubit.dart"
    - "lib/application/finance/goal/goal_state.dart"
    - "lib/application/finance/goal/goal_list_cubit.dart"
    - "lib/application/finance/goal/goal_list_state.dart"
    - "lib/application/finance/debt/debt_cubit.dart"
    - "lib/application/finance/debt/debt_state.dart"
    - "lib/application/finance/recurring/recurring_payment_cubit.dart"
    - "lib/application/finance/recurring/recurring_payment_state.dart"
    - "lib/application/finance/dashboard/home_dashboard_cubit.dart"
    - "lib/application/finance/dashboard/home_dashboard_state.dart"
    - "test/application/finance/transaction_cubit_test.dart"
    - "test/application/finance/budget_cubit_test.dart"
    - "test/application/finance/goal_cubit_test.dart"
    - "test/application/finance/debt_cubit_test.dart"
    - "test/application/finance/home_dashboard_cubit_test.dart"
  modified: []
decisions:
  - "BudgetCubit subscribes to TransactionRepository.watchChanges() (not BudgetRepository) — BudgetRepository has no watchChanges; any new transaction correctly triggers budget re-computation"
  - "RecurringPaymentCubit is non-reactive by design — no watchChanges on RecurringPaymentRepository per plan and D-CONTEXT"
  - "GoalCubit is a detail cubit (not a list cubit) — no auto-start; caller invokes loadGoal(id) explicitly per screen navigation"
  - "HomeDashboardCubit aggregates tagged-tx amounts from allTx in a single Dart pass (no per-goal Isar query) — prevents N+1 pattern"
  - "DebtCubit.togglePaid() calls explicit _reload() after toggle (not relying solely on watchChanges) — ensures immediate state update"
metrics:
  duration: "~13 minutes"
  completed: "2026-05-14"
  tasks_completed: 2
  tasks_total: 2
  files_created: 19
  files_modified: 0
  tests_written: 20
  tests_passing: 20
---

# Phase 3 Plan 3: Finance Application Layer Summary

Seven application-layer Cubits with sealed state hierarchies — TransactionCubit, BudgetCubit, GoalCubit, GoalListCubit, DebtCubit, RecurringPaymentCubit, HomeDashboardCubit — implemented TDD with 20 passing unit tests; HomeDashboardCubit performs single-pass Dart aggregation for balance (D-07), net worth (D-08), and per-category chart data (D-09).

## What Was Built

### Task 1: TransactionCubit, BudgetCubit, GoalCubit, DebtCubit, RecurringPaymentCubit (commit 2301d2f)

Twelve Dart files in `lib/application/finance/`:

**TransactionCubit** (`transaction/`) — `@injectable`; constructor takes `TransactionRepository`. Implements `start()` subscribing to `watchChanges()`, `_reload()` calling `getTransactions()`, `createTransaction(Transaction)`, `updateTransaction(Transaction)`, `softDelete(int)`. State: `TransactionLoaded` holds `List<Transaction>`. `close()` cancels subscription.

**BudgetCubit** (`budget/`) — `@injectable`; constructor takes `TransactionRepository`, `BudgetRepository`, `TransactionCategoryRepository`. Subscribes to `_transactionRepository.watchChanges()` (not BudgetRepository — budget computation must re-run whenever a transaction changes). `_reload()`: (1) fetch expense txs for current month via `getByMonth()`; (2) groupBy categoryId in single Dart loop to get `spentCents`; (3) load budget limits via `getForMonth()`; (4) load expense categories; (5) emit `BudgetLoaded(budgets: Map<int,({limitCents, spentCents})>, categories)`.

**GoalCubit** (`goal/`) — `@injectable`; detail cubit (no auto-start). Constructor takes `GoalRepository`, `TransactionRepository`. `loadGoal(int id)` emits `GoalLoading` then calls `_refreshGoal()`. `_refreshGoal()` calls `getByLinkedGoal(goal.id)`, folds tagged amounts, emits `GoalLoaded(goal, taggedTransactionsCents)`. `addContribution()` calls `goalRepo.addContribution()` then re-emits `GoalLoaded`.

**GoalListCubit** (`goal/`) — `@injectable`; reactive list cubit. Subscribes to `GoalRepository.watchChanges()`. `_reload()` calls `getActiveGoals()`. State: `GoalListLoaded(List<SavingsGoal>)`.

**DebtCubit** (`debt/`) — `@injectable`; constructor takes `DebtRepository`. Implements `start()`, `createDebt`, `updateDebt`, `togglePaid(int)` (explicit `_reload()` after toggle), `softDelete`. State: `DebtLoaded(List<Debt>)`.

**RecurringPaymentCubit** (`recurring/`) — `@injectable`; non-reactive (no `watchChanges`). Constructor takes `RecurringPaymentRepository`. `start()`, `createPayment`, `updatePayment`, `softDelete` — all call `_reload()` explicitly. State: `RecurringPaymentLoaded(List<RecurringPayment>)`.

**Tests:** 13 unit tests using `bloc_test` + `mocktail` — TransactionCubit (4: start→loaded, start→error, createTransaction→calls repo, softDelete→calls repo), BudgetCubit (3: correct spentCents, zero spentCents for no txs, setLimit calls repo), GoalCubit (2: loadGoal combines amounts, addContribution calls repo), DebtCubit (4: start→loaded, start→error, togglePaid calls repo, togglePaid→updated state).

### Task 2: HomeDashboardCubit — single-pass aggregation (commit 793cd8c)

Two Dart files in `lib/application/finance/dashboard/`:

**HomeDashboardState** — sealed class: `HomeDashboardInitial`, `HomeDashboardLoading`, `HomeDashboardLoaded` (fields: `balanceCents int`, `netWorthCents int`, `selectedMonth DateTime`, `categorySpend Map<int,int>`, `categories List<TransactionCategory>`), `HomeDashboardError(Failure)`. All extend `Equatable`.

**HomeDashboardCubit** — `@injectable`; constructor takes 4 repositories (`TransactionRepository`, `GoalRepository`, `DebtRepository`, `TransactionCategoryRepository`). Single `_txWatchSub` field, `DateTime _selectedMonth = DateTime.now()`.

`start()`: subscribes to `_transactionRepository.watchChanges()`; calls `_reload()`.

`selectMonth(DateTime month)`: sets `_selectedMonth = DateTime(month.year, month.month)`; calls `_reload()`.

`_reload()` — single-pass 7-step implementation:
1. `if (isClosed) return;` — guard before async gap
2. `await getTransactions()` — one Isar query for all non-deleted txs
3. `if (isClosed) return;` — guard after await
4. Balance: single Dart for-loop `income += amountCents` or `expenses += amountCents`; `balance = income - expenses` (D-07)
5. `getActiveGoals()` + build `taggedByGoal` map from `allTx` in one pass (no per-goal Isar query)
6. `getDebts()` + D-08 formula: `netWorth = balance + goalsSavedTotal - toPay && !isPaid debts`
7. Filter `allTx` to `selectedMonth` expenses; `groupBy categoryId` in single Dart loop
8. `getAll()` for category labels
9. `if (isClosed) return;` — final guard
10. `emit HomeDashboardLoaded`

`close()`: cancels `_txWatchSub`.

**Tests:** 7 unit tests — balance formula (5000+3000-2000=6000), netWorth D-08 (6000+0-1500=4500), toReceive exclusion (6000 unchanged), categorySpend current-month only, selectMonth March filters to March, empty categorySpend with no expense txs, soft-deleted-tx exclusion.

## Verification Results

```
flutter test test/application/finance/
20/20 tests passed

dart analyze lib/application/finance/
No issues found!

grep -rn "if (isClosed)" lib/application/finance/
17 occurrences (budget: 4, transaction: 2, goal_list: 2, recurring: 2, debt: 2, dashboard: 5)

grep -rn "@injectable" lib/application/finance/
7 occurrences — one per cubit class

HomeDashboardCubit: single _txWatchSub field ✓
HomeDashboardCubit: single _reload() method with all aggregations ✓
BudgetCubit: subscribes to TransactionRepository.watchChanges() ✓
GoalCubit.loadGoal: getGoal + getByLinkedGoal + fold tagged amounts ✓
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] TransactionCubit test needed registerFallbackValue for Transaction**
- **Found during:** Task 1, GREEN phase — test used `any()` on `Transaction` type
- **Issue:** Mocktail requires `registerFallbackValue` for non-primitive types used with `any()` matchers; `Transaction` was not registered
- **Fix:** Added `setUpAll(() { registerFallbackValue(_makeTransaction(id: 0)); })` to transaction test
- **Files modified:** `test/application/finance/transaction_cubit_test.dart`
- **Commit:** 2301d2f

**2. [Rule 1 - Bug] BudgetCubit test compilation error — `now` undefined in `act` block**
- **Found during:** Task 1, GREEN phase — test used `now.month` / `now.year` inside `act:` block but `now` was a local variable in `build:` scope
- **Issue:** `now` is scoped to `build:` callback; not accessible in `act:` or `verify:` blocks
- **Fix:** Moved `DateTime.now()` call inside the `act:` callback; used `any()` matchers in `verify:` block instead of specific values
- **Files modified:** `test/application/finance/budget_cubit_test.dart`
- **Commit:** 2301d2f

**3. [Rule 1 - Bug] BudgetCubit had `_currentMonth` field flagged as non-final**
- **Found during:** Task 1, post-GREEN analyze — `prefer_final_fields` lint
- **Issue:** `_currentMonth` was declared as a mutable `DateTime` field but never updated (BudgetCubit has no `selectMonth` method in Phase 3)
- **Fix:** Removed `_currentMonth` field; replaced with inline `DateTime.now()` call in `_reload()`
- **Files modified:** `lib/application/finance/budget/budget_cubit.dart`
- **Commit:** 2301d2f (same commit, applied before final commit)

## Known Stubs

None — this plan is the application layer only. No UI rendering, no display-only stubs. All cubits emit domain entities; presentation wiring is Plan 04.

## Threat Flags

No new threat surface beyond what is documented in the plan's threat model:
- T-03-03-01 (Tampering — HomeDashboardCubit net worth formula): Mitigated. D-08 formula enforced in code (`debtDirection == toPay && !isPaid`). Test coverage verifies `toReceive` debts are excluded.
- T-03-03-02 (DoS — subscription leak): Mitigated. `close()` cancels `_txWatchSub`. Pattern consistent with TaskListCubit.
- T-03-03-03 (Tampering — BudgetCubit spentCents): Mitigated. `getByMonth()` filter already scoped to expense type and month in DAO layer; cubit groups by categoryId only.
- T-03-03-04 (Tampering — GoalCubit double-counting): Mitigated. Two paths (contributions + tagged txs) kept separate; `_refreshGoal()` folds tagged from transactionRepo, `goal.amountSavedCents()` folds manual contributions.
- T-03-03-05 (DoS — emit-after-close): Mitigated. Double `isClosed` guard in every `_reload()` method; 17 total guard occurrences across 7 cubits.

## Self-Check: PASSED

Files verified:
- lib/application/finance/transaction/transaction_cubit.dart: FOUND
- lib/application/finance/transaction/transaction_state.dart: FOUND
- lib/application/finance/budget/budget_cubit.dart: FOUND
- lib/application/finance/budget/budget_state.dart: FOUND
- lib/application/finance/goal/goal_cubit.dart: FOUND
- lib/application/finance/goal/goal_state.dart: FOUND
- lib/application/finance/goal/goal_list_cubit.dart: FOUND
- lib/application/finance/goal/goal_list_state.dart: FOUND
- lib/application/finance/debt/debt_cubit.dart: FOUND
- lib/application/finance/debt/debt_state.dart: FOUND
- lib/application/finance/recurring/recurring_payment_cubit.dart: FOUND
- lib/application/finance/recurring/recurring_payment_state.dart: FOUND
- lib/application/finance/dashboard/home_dashboard_cubit.dart: FOUND
- lib/application/finance/dashboard/home_dashboard_state.dart: FOUND
- test/application/finance/transaction_cubit_test.dart: FOUND
- test/application/finance/budget_cubit_test.dart: FOUND
- test/application/finance/goal_cubit_test.dart: FOUND
- test/application/finance/debt_cubit_test.dart: FOUND
- test/application/finance/home_dashboard_cubit_test.dart: FOUND

Commits verified:
- 2301d2f: Task 1 — 5 cubits + 13 tests (FOUND)
- 793cd8c: Task 2 — HomeDashboardCubit + 7 tests (FOUND)
