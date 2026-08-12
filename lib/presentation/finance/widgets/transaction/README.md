# presentation/finance/widgets/transaction

Transaction-specific pieces: the form's fields, chrome, pickers, and
submit path.

## Responsibility

Render and assist the transaction form. Pure construction logic lives in
`../../transaction_form_logic.dart`; the mutable field state lives in
`../../transaction_form_model.dart`; the controllers stay on the screen.

## Files

| File | Lines | Role |
|------|------:|------|
| `transaction_form_scaffold.dart` | 43 | Chrome: surface colour, app bar, and the scrolling `Form` that hosts the fields. Owns no state |
| `transaction_form_app_bar.dart` | 35 | The form's `AppBar`; title switches add/edit, trailing action triggers save |
| `transaction_form_fields.dart` | 67 | Composes the body from the two field groups below |
| `transaction_type_amount_fields.dart` | 86 | Income/expense toggle plus the amount input; `amountController` is owned by the caller |
| `transaction_category_date_note_fields.dart` | 137 | Category, date, note, and the conditional goal-link field; every value arrives pre-resolved and every interaction routes through an `onPick*` callback |
| `transaction_form_pickers.dart` | 85 | `BuildContext`-driven category/date/goal picker helpers, extracted from the screen's `_showSheet`/`_pickCategory`/`_pickDate`/`_pickGoal`. Mirrors `../recurring/recurring_payment_form_pickers.dart` |
| `transaction_form_submit.dart` | 60 | Validates, builds the `Transaction`, and persists it through the cubit passed in |
| `goal_link_picker_sheet.dart` | 80 | Bottom sheet for linking (or clearing the link to) a `SavingsGoal` on an expense; resolves via `Navigator.pop(int?)` where `null` means "no link" |

## Conventions in this slice

- **Widgets own no state.** Controllers belong to the screen; the field
  widgets take values and callbacks.
- **`transaction_form_submit.dart` lives here, not in the logic file.** It
  needs a cubit and a `BuildContext`, so it cannot go in
  `../../transaction_form_logic.dart`, which is deliberately widget-free.
  This is the documented boundary between the two.
- **Sheets pop a value.** `goal_link_picker_sheet.dart` never calls a
  cubit; the caller applies the popped goal id via `setState`.
- **Eight files against a ten-file cap.** A further extraction here means
  merging two field groups first; the directory has two files of headroom,
  not more.

## Upstream dependencies

`application/finance/transaction/` (`TransactionCubit`) ·
`domain/finance/transaction/`, `domain/finance/category/`,
`domain/finance/goal/` · `../finance_form_primitives.dart` ·
`../category_picker_sheet.dart` · `../../transaction_form_logic.dart` ·
`core/utils/` · `generated/l10n/`.
