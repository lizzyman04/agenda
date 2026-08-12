# presentation/finance/widgets/debt

Debt-specific pieces: the list card and the form's two field groups.

## Responsibility

Render the debt list row and form fields. The `Debt` to persist is built by
`../../debt_form_logic.dart`; controllers stay on the screen.

## Files

| File | Lines | Role |
|------|------:|------|
| `debt_card.dart` | 115 | One list row: swipe-to-delete, tap to edit, paid-status toggle |
| `debt_form_fields.dart` | 125 | Title, amount, counterparty and due-date card. Controllers are owned by the caller, not created or disposed here |
| `debt_direction_toggle.dart` | 42 | The "to pay" / "to receive" direction card |

## Conventions in this slice

- **Direction is a domain enum, not a bool.** The toggle reads and writes
  `DebtDirection`; nothing here invents an `isOwed`-style flag.
- **The direction toggle is its own card**, separate from the field card,
  because it is the one choice that changes the meaning of every other
  field on the form.
- **No controller ownership.** Both field widgets take controllers created
  and disposed by `debt_form_screen.dart`.

## Upstream dependencies

`domain/finance/debt/` (`Debt`, `DebtDirection`) ·
`../finance_form_primitives.dart` · `core/utils/amount_formatter.dart` ·
`core/constants/finance_colors.dart` · `generated/l10n/`.
