# Deferred items — phase 03-finance-core

Out-of-scope discoveries logged during execution. Not fixed, by scope rule.

| Found in | File | Item |
|---|---|---|
| 03-10 | `lib/presentation/finance/widgets/debt/debt_card.dart:101` | The paid-status `SwitchListTile` title is a hardcoded PT-BR literal — `debt.isPaid ? 'Pago' : 'Pendente'`. It renders "Pago"/"Pendente" even under the `en` locale. Pre-existing, untouched by CR-01, and belongs to the hardcoded-string defect class rather than the undo path. Needs `paid` / `pending` keys in all three ARB files. |
| 03-10 | `lib/presentation/finance/screens/transaction_list_screen.dart:46,54` | Two analyzer infos (`discarded_futures`, `cascade_invocations`) inside `_handleDelete`, both counted in the 65-info baseline. The debt equivalent written in 03-10 avoids them via `unawaited(...)` and a `messenger` cascade; the transaction original could take the same two-line treatment and drop the baseline to 63. |
