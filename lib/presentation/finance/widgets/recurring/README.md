# presentation/finance/widgets/recurring

Recurring-payment-specific pieces: the list card and the form's fields,
chrome, and pickers.

## Responsibility

Render the recurring payment list row and form. Load/save logic lives in
`../../recurring_payment_form_logic.dart`; controllers stay on the screen.

## Files

| File | Lines | Role |
|------|------:|------|
| `recurring_payment_card.dart` | 95 | One list row: title, cycle, next due date, amount, and the active-status toggle. Renders a paused payment dimmed, with the toggle left at full opacity |
| `recurring_payment_form_fields.dart` | 141 | Title/amount/category card plus the schedule half, composed from the shared `FormCard`/`FieldRow`/`FieldDivider` primitives. Does not own its controllers |
| `recurring_payment_schedule_fields.dart` | 87 | The cycle and next-due-date half, rendered as a bare `Column` of `FieldRow`s so the caller keeps ownership of the surrounding `FormCard`. Also exports the PT-BR label for a `RecurringCycle`, shared with the list card |
| `recurring_payment_form_pickers.dart` | 50 | `BuildContext`-driven category and date pickers; the category picker presents the shared `CategoryPickerSheet` and returns the selection or `null` |
| `recurring_payment_form_app_bar.dart` | 34 | The form's `AppBar`; title switches add/edit, trailing action triggers save |

## Conventions in this slice

- **The card and the form share one cycle label.** The PT-BR
  `RecurringCycle` label lives in `recurring_payment_schedule_fields.dart`
  and is imported by the card, so the list and the form can never disagree.
- **A field group that is only half a card renders a bare `Column`.**
  `RecurringPaymentScheduleFields` does not wrap itself in a `FormCard` —
  the caller owns the card, which is what lets both halves stay under the
  line-count cap without a visual seam.
- **Only expense categories.** The form loads expense categories only, and
  an empty list on failure, matching the pre-refactor behaviour verbatim.
- **A paused row dims, but its toggle does not.** The card wraps only the
  `ListTile` in `Opacity`, leaving the `SwitchListTile` at full strength.
  That switch is the sole control that can resume a paused payment (CR-02),
  so dimming it along with the row would make the recovery path look
  disabled. The paused/active label goes through `AppLocalizations`.

## Upstream dependencies

`domain/finance/recurring/` (`RecurringPayment`, `RecurringCycle`) ·
`domain/finance/category/` (`TransactionCategory`) ·
`../finance_form_primitives.dart` · `../category_picker_sheet.dart` ·
`core/utils/` · `generated/l10n/`.
