# application/finance/dashboard

Owns the **Resumo figures** — the cross-entity numbers no single finance
entity can produce on its own.

## Responsibility

Fetch transactions, goals, debts and categories once, then compute
balance, net worth and per-category spend from that one set of reads
(D-07, D-08, D-09). Deliberately avoids N+1 Isar queries (T-03-03-01).

## Files

| File | Lines | Role |
|------|------:|------|
| `home_dashboard_cubit.dart` | 139 | `HomeDashboardCubit` — fetches the repository data, delegates the maths, handles `selectMonth`; subscribes to `TransactionRepository.watchChanges()` |
| `dashboard_aggregator.dart` | 85 | Pure functions: `computeBalance`, `computeTaggedByGoal`, `computeGoalsSavedTotal`, `computeDebtTotal`, `computeNetWorth`, `computeCategorySpend` |
| `home_dashboard_state.dart` | 74 | Sealed state family; `HomeDashboardLoaded` carries the balance, net worth, selected month, category spend map and category list |

## Conventions in this slice

- **Fetch once, compute many.** Every figure is derived from the same set
  of repository reads, in one pass per collection. Adding a figure means
  adding a function to `dashboard_aggregator.dart`, not a new query.
- **The aggregator is cubit-free and repository-free**, so each figure is
  independently unit-testable — which matters because these are the
  numbers a user checks first.
- **Month selection is state, not a new cubit.** `selectMonth` re-runs the
  same reload against a different window.
- **Aggregate from the uncapped read, always.** The cubit calls
  `TransactionRepository.getAllTransactionsForAggregates()`, never the
  capped `getTransactions()`. A capped read makes a total silently wrong
  past 500 transactions instead of visibly incomplete — that was CR-04,
  and it is the reason the two reads are separate methods.

## Upstream dependencies

`domain/finance/transaction/`, `domain/finance/goal/`,
`domain/finance/debt/`, `domain/finance/category/` (entities and
repositories) · `core/failures/result.dart`.
