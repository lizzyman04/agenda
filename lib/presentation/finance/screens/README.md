# presentation/finance/screens

Route-level widgets for the finance side, excluding savings goals (which
live in `../goals/screens/`).

## Responsibility

Own the cubit, own the form controllers, and wire state to the widgets in
`../widgets/`. Load/save logic is delegated to the `*_form_logic.dart`
files in `../`.

## Files

| File | Lines | Role |
|------|------:|------|
| `finance_dashboard_screen.dart` | 56 | `TabBar`/`TabBarView` shell for the whole finance section: Resumo (`../widgets/dashboard/dashboard_tab.dart`), transactions, budgets, debts, recurring payments, and goals |
| `transaction_list_screen.dart` | 148 | The transaction list — resolves each `categoryId` to a localized name via `resolveCategoryDisplay`; swipe-to-delete (via `TransactionCard`'s `Dismissible`) with an `AppConstants.undoSnackbarDuration` undo snackbar that hides the previous one before showing itself, tap to edit |
| `transaction_form_screen.dart` | 149 | Create/edit a transaction; owns the controllers and `TransactionFormModel`, delegates loading, submission and pickers |
| `budget_overview_screen.dart` | 126 | Per-category budget vs. spend, with the limit sheet |
| `debt_list_screen.dart` | 130 | Debts to pay and to receive, with the paid toggle; swipe-to-delete (via `DebtCard`'s `Dismissible`) with the same hide-then-show undo snackbar the transaction list uses |
| `debt_form_screen.dart` | 150 | Create/edit a debt |
| `recurring_payment_screen.dart` | 98 | The recurring payments list, paused rows included |
| `recurring_payment_form_screen.dart` | 147 | Create/edit a recurring payment |

## Conventions in this slice

- **The screen owns the controllers and the `GlobalKey<FormState>`**, and
  disposes them. Everything else about a form — the fields, the app bar,
  the pickers, the submit — is a helper under `../widgets/<entity>/` or a
  pure function in `../`.
- **Awaited pop, then cubit.** A picker or sheet returns a value; the
  screen applies it in `setState` and only then calls the cubit. Never
  `unawaited(...)` from inside a sheet — that emits during teardown and
  races controller disposal.
- **An undo SnackBar hides the current one before showing itself.**
  `ScaffoldMessenger` queues SnackBars FIFO, so a destructive action must
  capture the messenger once, call `hideCurrentSnackBar()` and only then
  `showSnackBar(...)`. Without it a second delete inside the undo window
  queues behind the first, and the SnackBar the user sees carries the
  earlier delete's action closure — undo restores the wrong record. The
  visible undo must always belong to the most recent action.
- **Form screens sit close to the 150-line cap by design.** Four of the
  eight are at 126–150 lines after Phase 3.1's extractions; adding a field
  means adding it to the corresponding `*_form_fields.dart`, not here.

## Upstream dependencies

`application/finance/` (`TransactionCubit`, `BudgetCubit`, `DebtCubit`,
`RecurringPaymentCubit`, `HomeDashboardCubit` and their states) ·
`domain/finance/` · `../` (form logic and the transaction form model) ·
`../widgets/` · `core/utils/` · `generated/l10n/` ·
`config/di/injection.dart`.
