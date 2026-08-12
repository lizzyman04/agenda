# application/finance/budget

Owns **budget vs. actual spend** per expense category for the selected
month.

## Responsibility

Combine configured budget limits with the month's actual spending into one
per-category view, and persist a new limit. The merge arithmetic is pure
and lives in its own file.

## Files

| File | Lines | Role |
|------|------:|------|
| `budget_cubit.dart` | 132 | `BudgetCubit` — loads categories, limits and transactions, delegates the merge, and exposes `setLimit`. Subscribes to `TransactionRepository.watchChanges()` so budgets recompute when a transaction changes (T-03-03-03) |
| `budget_aggregator.dart` | 47 | Pure merge of transactions + budgets into a per-category spend/limit map, including a backfill pass for categories with a limit but no transactions this month (`spentCents` defaults to 0) |
| `budget_state.dart` | 51 | Sealed state family: `BudgetInitial`, `BudgetLoading`, `BudgetLoaded` (merged budgets + categories), `BudgetError` |

## Conventions in this slice

- **The cubit fetches; the aggregator decides.** `budget_aggregator.dart`
  has no cubit state and no repository access, so every merge rule —
  including the zero-spend backfill — is unit-testable directly.
- **A category with a limit but no spend must still appear.** Dropping it
  would silently hide a budget the user configured; the backfill pass
  exists specifically to prevent that.
- **Transactions drive budgets.** The subscription is on the *transaction*
  repository, not the budget repository, because spend changes far more
  often than limits do.

## Upstream dependencies

`domain/finance/budget/` (`Budget`, `BudgetRepository`) ·
`domain/finance/category/` (`TransactionCategory`, its repository) ·
`domain/finance/transaction/` (`Transaction`, its repository,
`TransactionType`) · `core/failures/result.dart`.
