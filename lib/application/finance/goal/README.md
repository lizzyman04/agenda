# application/finance/goal

Owns **savings goals** — both the list and one goal's detail view.

## Responsibility

Load goals, record contributions, and compute a goal's progress as
`goal.contributions + tagged transaction amounts` (D-11). Progress
arithmetic on a single goal lives in
`domain/finance/goal/savings_goal.dart`; this directory supplies the
tagged-transaction half.

## Files

| File | Lines | Role |
|------|------:|------|
| `goal_list_cubit.dart` | 53 | `GoalListCubit` — all active goals; subscribes to `GoalRepository.watchChanges()` |
| `goal_list_state.dart` | 41 | Sealed state family for the list: Initial / Loading / Loaded / Error |
| `goal_cubit.dart` | 106 | `GoalCubit` — one goal; `loadGoal`, `addContribution`, `createGoal`, `updateGoal`, `softDeleteGoal`, each followed by a `_refreshGoal` that recomputes the tagged total |
| `goal_state.dart` | 51 | Sealed state family for the detail view; `GoalLoaded` carries the goal plus `taggedTransactionsCents` |

## Conventions in this slice

- **Two cubits, two lifecycles.** The list cubit is reactive (subscribes,
  cancels in `close()`); the detail cubit is on-demand and deliberately
  does *not* subscribe — it is loaded by id when the detail route opens.
- **Progress is never stored.** It is recomputed from the contributions
  plus the goal-tagged transactions on every refresh, so a transaction
  edited elsewhere cannot leave a stale percentage behind.
- **Every mutation re-reads.** `addContribution`/`updateGoal` route through
  `_refreshGoal` rather than patching the in-memory goal.

## Upstream dependencies

`domain/finance/goal/` (`SavingsGoal`, `SavingsGoalContribution`,
`GoalRepository`) · `domain/finance/transaction/` (`Transaction`, its
repository — for the tagged total) · `core/failures/result.dart`.
