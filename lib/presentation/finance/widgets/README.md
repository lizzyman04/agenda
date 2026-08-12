# presentation/finance/widgets

Finance widgets. The files directly in this directory are the ones shared
across two or more entities; anything used by exactly one entity lives in
that entity's subdirectory.

## Responsibility

Render what they are given. Nothing here constructs a cubit — the one
deliberate exception is `transaction/transaction_form_submit.dart`, which
takes the screen's cubit as a parameter and is documented in its own
README.

## Layout

```
widgets/
├── (this directory)  widgets shared across entities
├── transaction/  transaction form + list pieces
├── recurring/    recurring payment form + list pieces
├── debt/         debt form + list pieces
├── budget/       the budget limit sheet
└── dashboard/    the Resumo tab and its month header
```

### widgets/ (top level)

| File | Lines | Role |
|------|------:|------|
| `finance_form_primitives.dart` | 63 | `FormCard`, `FieldRow`, `FieldDivider` — the layout atoms shared by all four finance forms |
| `category_picker_sheet.dart` | 97 | `CategoryPickerSheet` — one picker shared by the transaction and recurring payment forms, replacing the near-identical `_pickCategory()` sheets each used to have |
| `finance_empty_state.dart` | 70 | Empty state for every finance list — body text plus a CTA `FilledButton` (extends the Phase 2 UX-04 pattern) |
| `transaction_card.dart` | 114 | One transaction row: swipe-to-delete via `Dismissible`, tap to edit, income/expense colours from `FinanceColors` |
| `budget_progress_bar.dart` | 114 | Spend-vs-limit bar for one category, with a three-state colour ramp |
| `dashboard_summary_card.dart` | 84 | The Resumo anchor: lifetime balance (D-07) in `displaySmall`, net worth (D-08) below |
| `spending_pie_chart.dart` | 135 | Donut chart of expense spend by category, with a legend |
| `spending_bar_chart.dart` | 127 | Bar chart of the same data, same colour palette |

## Conventions in this slice

- **Shared here, entity-specific in a subdirectory.** A widget moves up
  into this directory the moment a second entity uses it — that is exactly
  how `category_picker_sheet.dart` and the form primitives got here.
- **Charts take an already-aggregated `Map<int, int>`** (categoryId →
  cents). They never sum transactions themselves; that is the dashboard
  aggregator's job.
- **Colour is semantic, not literal.** Income/expense colours come from
  `core/constants/finance_colors.dart`, and both charts share one palette
  so the pie and the bar agree.
- **Eight files against a ten-file cap.** The next shared widget is fine;
  the one after that means splitting by entity rather than growing this
  directory past the guard's limit.

## Upstream dependencies

`domain/finance/` (`Transaction`, `TransactionCategory`,
`TransactionType`) · `core/constants/finance_colors.dart` ·
`core/utils/amount_formatter.dart` · `fl_chart` · `generated/l10n/`.
