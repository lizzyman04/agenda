---
phase: "03-finance-core"
plan: "01"
subsystem: "domain/finance"
tags: ["domain", "entities", "repository-interfaces", "utilities", "pure-dart", "tdd"]
dependency_graph:
  requires: []
  provides:
    - "lib/domain/finance/transaction.dart"
    - "lib/domain/finance/transaction_type.dart"
    - "lib/domain/finance/transaction_category.dart"
    - "lib/domain/finance/transaction_repository.dart"
    - "lib/domain/finance/transaction_category_repository.dart"
    - "lib/domain/finance/budget.dart"
    - "lib/domain/finance/budget_repository.dart"
    - "lib/domain/finance/savings_goal.dart"
    - "lib/domain/finance/savings_goal_contribution.dart"
    - "lib/domain/finance/goal_repository.dart"
    - "lib/domain/finance/debt.dart"
    - "lib/domain/finance/debt_direction.dart"
    - "lib/domain/finance/debt_repository.dart"
    - "lib/domain/finance/recurring_payment.dart"
    - "lib/domain/finance/recurring_cycle.dart"
    - "lib/domain/finance/recurring_payment_repository.dart"
    - "lib/core/constants/currencies.dart"
    - "lib/core/constants/finance_colors.dart"
    - "lib/core/utils/amount_formatter.dart"
  affects:
    - "03-02: Isar models and DAOs consume domain entities and repository interfaces"
    - "03-03: Application cubits consume domain entities and repository interfaces"
    - "03-04: Presentation layer imports domain entities for display"
    - "03-05: Dashboard cubit uses formatAmount, FinanceColors, and Currencies"
tech_stack:
  added: []
  patterns:
    - "clearField sentinel for nullable copyWith params (replicated from Item domain entity)"
    - "AsyncResult<T> and Stream<void> repository interface pattern"
    - "int cents arithmetic — no double for money storage"
    - "amountSavedCents(int taggedTransactionsCents) parameterized getter for pure domain computation"
    - "ISO 4217 static const list — no network, no external package"
    - "NumberFormat.currency for locale-aware amount display (display-only, never stored)"
key_files:
  created:
    - "lib/domain/finance/transaction.dart"
    - "lib/domain/finance/transaction_type.dart"
    - "lib/domain/finance/transaction_category.dart"
    - "lib/domain/finance/transaction_repository.dart"
    - "lib/domain/finance/transaction_category_repository.dart"
    - "lib/domain/finance/budget.dart"
    - "lib/domain/finance/budget_repository.dart"
    - "lib/domain/finance/savings_goal.dart"
    - "lib/domain/finance/savings_goal_contribution.dart"
    - "lib/domain/finance/goal_repository.dart"
    - "lib/domain/finance/debt.dart"
    - "lib/domain/finance/debt_direction.dart"
    - "lib/domain/finance/debt_repository.dart"
    - "lib/domain/finance/recurring_payment.dart"
    - "lib/domain/finance/recurring_cycle.dart"
    - "lib/domain/finance/recurring_payment_repository.dart"
    - "lib/core/constants/currencies.dart"
    - "lib/core/constants/finance_colors.dart"
    - "lib/core/utils/amount_formatter.dart"
    - "test/domain/finance/transaction_test.dart"
    - "test/domain/finance/savings_goal_test.dart"
    - "test/core/utils/amount_formatter_test.dart"
  modified: []
decisions:
  - "SavingsGoal.amountSavedCents and progressPercent take taggedTransactionsCents as a parameter — keeps domain pure; caller (GoalCubit) aggregates tagged transaction amounts before calling"
  - "BudgetRepository and RecurringPaymentRepository have no watchChanges stream — both are load-on-demand per plan success criteria"
  - "Currencies list has 155 ISO 4217 entries with MZN first (D-17 compliance)"
  - "formatAmount uses NumberFormat.currency with empty symbol then prepends symbol+space — matches D-18 format MT 1.250,00 / MT 1,250.00"
metrics:
  duration: "~20 minutes"
  completed: "2026-05-14"
  tasks_completed: 2
  tasks_total: 2
  files_created: 22
  files_modified: 0
  tests_written: 13
  tests_passing: 13
---

# Phase 3 Plan 1: Finance Domain Layer Summary

Pure Dart finance domain — 5 entities, 3 enums, 5 repository interfaces, 3 core utilities — defined before any Isar or Flutter dependency.

## What Was Built

### Task 1: Finance Domain Entities and Enums (commit edd5d51)

Ten pure-Dart files in `lib/domain/finance/`:

- **Transaction** — amountCents (int), type, categoryId, date, note (nullable), linkedGoalId (nullable), deletedAt (soft delete); clearField sentinel + copyWith
- **TransactionType** — enum { income, expense }
- **TransactionCategory** — id, namePtBr, nameEn (nullable), type, isDefault, createdAt; clearField + copyWith
- **SavingsGoal** — id, title, targetAmountCents, contributions (List), isCompleted, deadline (nullable), deletedAt; computed `amountSavedCents(int taggedCents)` and `progressPercent(int taggedCents)` methods
- **SavingsGoalContribution** — const value object (amountCents, date, note); no id, no copyWith
- **Budget** — id, categoryId, month (1-12), year, limitCents; copyWith
- **Debt** — id, title, amountCents, direction, counterparty, dueDate, isPaid, paidAt (nullable), deletedAt; clearField + copyWith
- **DebtDirection** — enum { toPay, toReceive }
- **RecurringPayment** — id, title, amountCents, categoryId, cycle, nextDueDate, isActive, deletedAt; clearField + copyWith
- **RecurringCycle** — enum { daily, weekly, biweekly, monthly, quarterly, yearly }

**Tests:** 8 unit tests passing — int-cents arithmetic, goal progress computation (including >1.0 case), balance formula, net worth formula.

### Task 2: Repository Interfaces and Core Utilities (commit 3a370ed)

Six repository interfaces in `lib/domain/finance/`:

- **TransactionRepository** — createTransaction, getTransaction, getTransactions, getByMonth, getByLinkedGoal, updateTransaction, softDelete, watchChanges
- **TransactionCategoryRepository** — getAll, getByType, create, update, delete (non-reactive)
- **BudgetRepository** — getForCategory (nullable result), getForMonth, setLimit (upsert), delete (non-reactive)
- **GoalRepository** — createGoal, getGoal, getActiveGoals, updateGoal, addContribution, softDelete, watchChanges
- **DebtRepository** — createDebt, getDebt, getDebts, updateDebt, togglePaid, softDelete, watchChanges
- **RecurringPaymentRepository** — createPayment, getPayment, getActivePayments, updatePayment, softDelete (non-reactive)

Three core utilities:

- **`lib/core/constants/currencies.dart`** — Currency value object; Currencies.all (155 ISO 4217 entries, MZN first); Currencies.priorityCodes (11 codes)
- **`lib/core/constants/finance_colors.dart`** — FinanceColors.incomeGreen (0xFF2E7D32), expenseRed (0xFFC62828), warningAmber (0xFFF57F17)
- **`lib/core/utils/amount_formatter.dart`** — `formatAmount(int amountCents, String currencySymbol, Locale locale)` using intl NumberFormat.currency

**Tests:** 5 formatter tests passing — PT-BR comma-decimal format, EN period-decimal format, zero amount.

## Verification Results

```
flutter test test/domain/finance/ test/core/utils/amount_formatter_test.dart
13/13 tests passed

dart analyze lib/domain/finance/ lib/core/constants/ lib/core/utils/amount_formatter.dart
0 errors (13 info-level style hints — no warnings, no errors)

grep -rn "import 'package:flutter" lib/domain/finance/
(no output — zero Flutter imports)

grep -rn "isar" lib/domain/finance/
(no output — zero Isar imports)

Currencies.all first entry: MZN
Currencies.all length: 155 entries (>= 100 required)
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test used `const result = formatAmount(...)` which is invalid**
- **Found during:** Task 2, RED phase test writing
- **Issue:** `formatAmount` is not a `const` function (calls intl at runtime), so `const result = formatAmount(...)` is a compile error
- **Fix:** Changed `const result` to `final result` in test file; `Locale('pt', 'BR')` → `const Locale('pt', 'BR')` for clarity
- **Files modified:** `test/core/utils/amount_formatter_test.dart`
- **Commit:** 3a370ed

**2. [Rule 1 - Bug] Spurious `MZN_skip` placeholder entry in currencies list**
- **Found during:** Task 2 implementation review
- **Issue:** Initial draft of currencies.dart had a dummy `MZN_skip` entry to avoid duplicating MZN; removed before commit
- **Fix:** Deleted the placeholder entry
- **Files modified:** `lib/core/constants/currencies.dart`
- **Commit:** 3a370ed

## Known Stubs

None — this plan is domain-layer only (pure Dart contracts). No UI rendering, no data wiring.

## Threat Flags

No new threat surface beyond what is documented in the plan's threat model. All files are pure Dart with no network endpoints, no auth paths, no file access, and no schema changes.

## Self-Check: PASSED

Files verified:
- lib/domain/finance/transaction.dart: FOUND
- lib/domain/finance/savings_goal.dart: FOUND
- lib/domain/finance/transaction_repository.dart: FOUND
- lib/core/constants/currencies.dart: FOUND
- lib/core/constants/finance_colors.dart: FOUND
- lib/core/utils/amount_formatter.dart: FOUND
- test/domain/finance/transaction_test.dart: FOUND
- test/domain/finance/savings_goal_test.dart: FOUND
- test/core/utils/amount_formatter_test.dart: FOUND

Commits verified:
- edd5d51: Task 1 — domain entities (FOUND)
- 3a370ed: Task 2 — repository interfaces + utilities (FOUND)
