# application/finance/debt

Owns the **debt list** — money to pay and money to receive.

## Responsibility

Load, create, update, mark paid, soft-delete and restore debts. Which
direction a debt runs is a domain concept (`DebtDirection`), not a flag
invented here.

## Files

| File | Lines | Role |
|------|------:|------|
| `debt_cubit.dart` | 127 | `DebtCubit` — subscribes to `DebtRepository.watchChanges()`; `createDebt`, `updateDebt`, `togglePaid`, `softDelete`, `restoreDebt` |
| `debt_state.dart` | 41 | Sealed state family: `DebtInitial`, `DebtLoading`, `DebtLoaded`, `DebtError` |

## Conventions in this slice

- **Reactive list.** The `watchChanges()` subscription drives reloads and
  is cancelled in `close()`; mutations re-query rather than patching.
- **`togglePaid` is a repository call, not a local flip** — the paid state
  must survive a restart, so it round-trips through Isar before the list
  reloads.
- **Restore is composed, not delegated.** `DebtRepository` has no restore
  method by design. `restoreDebt` does `getDebt` → `copyWith(deletedAt:
  null)` → `updateDebt`, exactly as `TransactionCubit.restoreTransaction`
  does. A missing record returns silently — it is already permanently gone,
  and an error state would be noise on an undo the user can no longer act on.
- **Factory, not singleton** — a fresh instance per debt screen.

## Upstream dependencies

`domain/finance/debt/` (`Debt`, `DebtDirection`, `DebtRepository`) ·
`core/failures/` (`Result`, `Failure`).
