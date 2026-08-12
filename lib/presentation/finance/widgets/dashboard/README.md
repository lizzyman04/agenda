# presentation/finance/widgets/dashboard

The **Resumo tab** and its month navigation chrome.

## Responsibility

Render the dashboard figures produced by `HomeDashboardCubit`. Every
number arrives already computed — nothing here sums a transaction list.

## Files

| File | Lines | Role |
|------|------:|------|
| `dashboard_tab.dart` | 143 | `DashboardTab` — balance and net-worth summary, month navigation, and the spending pie + bar charts, driven by `HomeDashboardCubit`. Also holds the dev-default currency symbol (MZN, D-16) |
| `dashboard_month_header.dart` | 78 | `MonthNavigationHeader` (previous/next month; the forward arrow is disabled when the current calendar month is selected, D-10) and `EmptyChartMessage` (centred "no expenses this month" text) |

## Conventions in this slice

- **The chart section stays visible when empty.** Per UI-SPEC, a month with
  no expense categories renders `EmptyChartMessage` inside the chart area
  rather than hiding the section — the layout must not jump between months.
- **No forward navigation past today.** `onNext` is `null` for the current
  month, which disables the arrow rather than hiding it.
- **Currency symbol is a documented dev default.** MZN is hardcoded here
  and in every other finance screen until a currency setting exists (D-16);
  it is a placeholder with a decision behind it, not an oversight.

## Upstream dependencies

`application/finance/dashboard/` (`HomeDashboardCubit`,
`HomeDashboardState`) · `domain/finance/category/` ·
`../dashboard_summary_card.dart`, `../spending_pie_chart.dart`,
`../spending_bar_chart.dart` · `core/utils/amount_formatter.dart` ·
`generated/l10n/`.
