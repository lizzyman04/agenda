# application/finance/transaction

Owns the **transaction list** — every income and expense entry.

## Responsibility

Load, create, update, soft-delete and restore transactions, and keep the
list live as the Isar collection changes (T-03-03-05).

## Files

| File | Lines | Role |
|------|------:|------|
| `transaction_cubit.dart` | 128 | `TransactionCubit` — subscribes to `TransactionRepository.watchChanges()`; `createTransaction`, `updateTransaction`, `softDelete`, `restoreTransaction`; also loads the category list once in `start()` so the list screen can resolve `categoryId` to a label |
| `transaction_state.dart` | 52 | Sealed state family: `TransactionInitial`, `TransactionLoading`, `TransactionLoaded` (carries `transactions` + `categories`), `TransactionError` |

## Conventions in this slice

- **Reactive by subscription, not by manual refresh.** Mutations do not
  patch the list; the `watchChanges()` stream drives the reload, which is
  why a transaction created from any screen appears everywhere at once.
- **Soft delete plus restore.** `softDelete` sets `deletedAt`;
  `restoreTransaction` is what the undo snackbar calls.
- **Categories load once per cubit lifetime.**
  `TransactionCategoryRepository` is explicitly non-reactive, so `start()`
  fetches the list once and `_reload()` reuses it. A category-lookup
  failure leaves the list empty and degrades to the `#<id>` label
  fallback — it never emits `TransactionError`.
- **Factory, not singleton** — a fresh instance per screen. The stream
  subscription is cancelled in `close()`.

## Upstream dependencies

`domain/finance/transaction/` (`Transaction`, `TransactionRepository`,
`TransactionType`) · `domain/finance/category/` (`TransactionCategory`,
`TransactionCategoryRepository`) · `core/failures/` (`Result`, `Failure`).
