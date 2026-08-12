# application/finance

Finance-side cubits — one directory per entity, mirroring the same six-way
split used by `domain/finance/` and `data/finance/`.

## Responsibility

Orchestration for money: load from the finance repositories, aggregate,
emit state. Money arithmetic that belongs to a single entity lives in
`domain/finance/` (goal progress, debt direction); cross-entity arithmetic
lives in the aggregator files here.

## Layout

```
finance/
├── transaction/  the transaction list
├── budget/       per-category budget vs. actual spend
├── goal/         savings goals — one list cubit, one detail cubit
├── debt/         debts to pay and to receive
├── recurring/    recurring payments
└── dashboard/    the cross-entity Resumo figures (balance, net worth)
```

Each leaf directory has its own README with the file/role table.

## Conventions across the slice

- **One directory per entity**, named for the domain entity, not the
  screen — `recurring/`, not `recurring_screen/`.
- **List cubits subscribe; detail cubits do not.** Every list cubit
  subscribes to its repository's `watchChanges()` and cancels in `close()`.
  `GoalCubit` is a detail cubit and loads on demand via `loadGoal`.
  `RecurringPaymentCubit` is the documented exception on the list side —
  `RecurringPaymentRepository` exposes no stream, so it reloads via
  `start()`.
- **Cross-entity maths is extracted.** `dashboard_aggregator.dart` and
  `budget_aggregator.dart` are plain function files with no cubit state and
  no repository access, so each figure is unit-testable on its own.
- **Amounts are integer cents everywhere.** No `double` crosses this layer.

## Upstream dependencies

`domain/finance/` (all six entity folders and their repository interfaces)
· `core/failures/` (`Result`, `Failure`).
