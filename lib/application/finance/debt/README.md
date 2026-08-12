# application/finance/debt

Owns the **debt list** — money to pay and money to receive.

## Responsibility

Load, create, update, mark paid, and soft-delete debts. Which direction a
debt runs is a domain concept (`DebtDirection`), not a flag invented here.

## Files

| File | Lines | Role |
|------|------:|------|
| `debt_cubit.dart` | 93 | `DebtCubit` — subscribes to `DebtRepository.watchChanges()`; `createDebt`, `updateDebt`, `togglePaid`, `softDelete` |
| `debt_state.dart` | 41 | Sealed state family: `DebtInitial`, `DebtLoading`, `DebtLoaded`, `DebtError` |

## Conventions in this slice

- **Reactive list.** The `watchChanges()` subscription drives reloads and
  is cancelled in `close()`; mutations re-query rather than patching.
- **`togglePaid` is a repository call, not a local flip** — the paid state
  must survive a restart, so it round-trips through Isar before the list
  reloads.
- **Factory, not singleton** — a fresh instance per debt screen.

## Upstream dependencies

`domain/finance/debt/` (`Debt`, `DebtDirection`, `DebtRepository`) ·
`core/failures/` (`Result`, `Failure`).
