# presentation/finance

Presentation slice for the **money half** of the app: the Resumo
dashboard, transactions, budgets, debts, recurring payments, and savings
goals.

## Responsibility

Rendering and interaction for finance. No money rules: entity arithmetic
lives in `domain/finance/`, orchestration in `application/finance/`, and
cent parsing/formatting in `core/utils/`.

This directory is **not** a pure umbrella — it holds the form-logic files
listed below, which is the convention this slice establishes: *load and
save logic for a finance form lives beside the slice as a plain function
file, not inside the screen.*

## Layout

```
finance/
├── (this directory)  per-form load/save logic + the transaction form model
├── screens/   route-level widgets for transactions, budgets, debts,
│               recurring payments, and the dashboard
├── widgets/   shared finance widgets, plus one subdirectory per entity
│               for that entity's form/list pieces
└── goals/     the savings-goals sub-slice (its own screens/ and widgets/)
```

Every subdirectory has its own README with a file/role table.

### finance/ (top level)

| File | Lines | Role |
|------|------:|------|
| `transaction_form_logic.dart` | 128 | `TransactionFormData` plus `loadTransactionFormData` (categories + active goals in one awaited call), the `Transaction` builder, and the category/goal label resolvers |
| `transaction_form_model.dart` | 46 | `TransactionFormModel` — mutable non-controller field state for the transaction form; mirrors `tasks/form/task_form_fields_model.dart` |
| `recurring_payment_form_logic.dart` | 75 | `loadExpenseCategories` (empty list on failure, matching the previous inline behaviour), the preselect lookup, and the `RecurringPayment` builder |
| `debt_form_logic.dart` | 41 | Builds the `Debt` to persist from validated field values, including the `isPaid: false` create-default |
| `goal_form_logic.dart` | 36 | Builds the `SavingsGoal` to persist — a brand-new goal on create, a `copyWith` of the original on edit |

## Conventions in this slice

- **Form logic is a plain function file, not a method on the screen.**
  Each `*_form_logic.dart` is widget-free and `BuildContext`-free, so the
  create/edit branching can be reasoned about — and tested — without
  pumping a frame. Where a helper genuinely needs a `BuildContext` or a
  cubit, it lives under `widgets/<entity>/` instead (see
  `widgets/transaction/transaction_form_submit.dart`).
- **Mutable field state is one model object.** Screens hold controllers;
  everything else (`selected*`, `all*`, `loading*`) collapses into a form
  model, which is what keeps each screen under the 150-line cap.
- **Amounts are integer cents.** Parsing and formatting go through
  `core/utils/amount_parser.dart` and `amount_formatter.dart`; no screen
  does its own arithmetic on a string.
- **Screens own cubits; widgets never do.**

## Upstream dependencies

`application/finance/` (all six cubit families and their states) ·
`domain/finance/` (all six entity folders) · `core/utils/`
(amount parser/formatter) · `core/constants/finance_colors.dart` ·
`generated/l10n/` · `config/di/injection.dart`.
