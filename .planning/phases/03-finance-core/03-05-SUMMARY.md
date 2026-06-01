---
phase: 03-finance-core
plan: 05
subsystem: finance-dashboard
tags: [flutter, fl_chart, dashboard, charts, l10n, bloc]
requires:
  - 03-03 (HomeDashboardCubit + HomeDashboardState)
  - 03-04 (finance widgets, ARB infrastructure, finance tab shell)
provides:
  - SpendingPieChart widget (donut + legend, empty-guard)
  - SpendingBarChart widget (per-category bars, empty-guard)
  - DashboardSummaryCard widget (balance + net worth)
  - Complete Resumo tab wired to HomeDashboardCubit
affects:
  - lib/presentation/finance/screens/finance_dashboard_screen.dart
  - lib/application/finance/dashboard/home_dashboard_cubit.dart
tech-stack:
  added:
    - fl_chart 1.2.0 (MIT charts — pie + bar)
  patterns:
    - Empty-sections guard before rendering fl_chart widgets (Pitfall A2)
    - Idempotent cubit.start() to avoid watch-subscription leak on tab revisit
key-files:
  created:
    - lib/presentation/finance/widgets/spending_pie_chart.dart
    - lib/presentation/finance/widgets/spending_bar_chart.dart
    - lib/presentation/finance/widgets/dashboard_summary_card.dart
    - test/presentation/finance/spending_pie_chart_test.dart
  modified:
    - lib/presentation/finance/screens/finance_dashboard_screen.dart
    - lib/application/finance/dashboard/home_dashboard_cubit.dart
    - pubspec.yaml
    - lib/config/l10n/app_en.arb
    - lib/config/l10n/app_pt_BR.arb
    - lib/config/l10n/app_pt.arb
    - lib/generated/l10n/app_localizations*.dart
decisions:
  - "Currency symbol hardcoded to 'MT' to match all existing finance screens; plan referenced StorageKeys.userCurrency which does not exist — adding a new storage key + SharedPreferences plumbing not present elsewhere was out of scope (deviation Rule 3)."
metrics:
  duration: ~25m
  completed: 2026-06-01
  tasks: 2 of 2 code tasks (1 checkpoint pending)
---

# Phase 3 Plan 05: Finance Dashboard + Charts Summary

Completed the Finance Dashboard Resumo tab — balance + net-worth summary card, month navigation, and fl_chart-backed spending pie and bar charts driven by `HomeDashboardCubit`, with all empty states. fl_chart 1.2.0 (MIT) uncommented in pubspec.

## What Was Built

- **SpendingPieChart** — donut `PieChart` (centerSpaceRadius 48) with one section per category, plus a legend below showing colored swatch + category name + formatted amount. Guards against fl_chart's empty-sections edge case (RESEARCH Pitfall A2 / threat T-03-05-04) by rendering a centered text message instead of a `PieChart` when `categorySpend` is empty. Exposes a deterministic 8-color palette via `categoryColor(int)`, wrapping with `% palette.length`.
- **SpendingBarChart** — `BarChart` with one rod per category, sharing `SpendingPieChart.categoryColor` so slices and bars match. Bottom axis shows truncated category short-names; other axes/grid/border hidden; `maxY` scaled to 110% of the largest value. Same empty-guard.
- **DashboardSummaryCard** — `Card` with balance (D-07) in `displaySmall` as the primary anchor and net worth (D-08) in `bodyLarge` below a divider.
- **Resumo tab** (`_DashboardTab`) — now a `StatefulWidget` that calls `context.read<HomeDashboardCubit>().start()` in `initState` (no new provider — cubit is provided above MaterialApp per quick task 260601-u6q). `BlocBuilder` renders loading / error / loaded states. Loaded state shows `FinanceEmptyState` when there is no data at all, otherwise the summary card, `_MonthNavigationHeader`, and the two charts. When the selected month has no expense categories, the chart area shows centered `noExpensesInMonth` text instead of hiding the section (per UI-SPEC). The next-month arrow is disabled (`onPressed: null`) when the current calendar month is selected (D-10).
- **ARB keys** added identically to `app_en.arb`, `app_pt_BR.arb`, and `app_pt.arb`: `currentBalance`, `netWorth`, `noExpensesInMonth` (param `month`), `spendingByCategory`, `previousMonth`, `nextMonth`. `flutter gen-l10n` regenerated `AppLocalizations`.

## Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 (RED) | Failing pie chart tests | 561c273 | test/presentation/finance/spending_pie_chart_test.dart |
| 1 (GREEN) | fl_chart widgets + summary card + ARB | 6a316ec | pubspec.yaml, spending_pie_chart.dart, spending_bar_chart.dart, dashboard_summary_card.dart, 3 ARB files, generated l10n |
| 2 | Complete Resumo tab with live data | c345f06 | finance_dashboard_screen.dart, home_dashboard_cubit.dart |
| 3 | Human-verify checkpoint | — | PENDING (see below) |

## Verification

- `flutter test test/presentation/finance/ test/application/finance/home_dashboard_cubit_test.dart` — 16/16 pass (incl. empty-map pie chart renders no `PieChart`, non-empty renders one section value=100.0, legend shows name, palette wraps).
- `flutter analyze lib/presentation/finance/` — 0 errors, 0 warnings (info-level lints only, accepted by conventions).
- `pubspec.yaml`: `fl_chart: 1.2.0` uncommented (both grep counts = 1).
- `flutter gen-l10n` regenerated all six new keys across en + pt.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Made `HomeDashboardCubit.start()` idempotent**
- **Found during:** Task 2
- **Issue:** `_DashboardTab.initState` calls `start()` each time the Resumo tab is (re)built. The original `start()` assigned `_txWatchSub` unconditionally, so revisiting the tab would open a second `watchChanges()` subscription and leak the first.
- **Fix:** `start()` now returns early after a `_reload()` if `_txWatchSub != null`, opening the watch subscription only once.
- **Files modified:** lib/application/finance/dashboard/home_dashboard_cubit.dart
- **Commit:** c345f06

**2. [Rule 3 - Blocking] Currency symbol source**
- **Found during:** Task 2
- **Issue:** Plan instructed reading the currency symbol from SharedPreferences via `StorageKeys.userCurrency`, but that key does not exist in `StorageKeys`, and no finance screen reads currency from prefs.
- **Fix:** Used the existing repo convention — a hardcoded `'MT'` (MZN dev default per D-16), matching every other finance screen. Avoided introducing an unmade currency-settings architectural decision (a Rule 4 concern) into a UI plan.
- **Files modified:** lib/presentation/finance/screens/finance_dashboard_screen.dart
- **Commit:** c345f06

## Checkpoint — PENDING (Task 3, human-verify, blocking)

This plan is `autonomous: false`. The code is fully implemented and verified, but Task 3 is a blocking human-verify checkpoint that I did NOT self-approve. The user must run the app on a device/emulator and verify the dashboard end-to-end.

**What to verify (abridged from plan):**
1. `flutter run` → Finanças → Resumo.
2. Zero transactions → "Sem dados financeiros" empty state with "Adicionar transação" button that switches to Transações tab.
3. Add income + multiple expense categories → balance renders in large font (displaySmall), net worth below it.
4. Current month label appears between two arrows; pie chart renders as donut with legend; bar chart renders below.
5. Navigate to a previous month with no expenses → "Sem gastos em {month}" appears in the chart area (section not hidden).
6. Right arrow disabled on current month.
7. End-to-end: budget progress colors, goal contribution progress, debt reduces net worth.

**Resume signal:** user types "approved" or describes issues.

## Known Stubs

None. The dashboard's `_currencySymbol` is a hardcoded `'MT'` consistent with the rest of the finance module (not a stub — there is no currency-selection feature in MVP scope; documented as a decision above).

## Self-Check: PASSED

- All 5 created/modified key files present on disk.
- All 3 commits (561c273, 6a316ec, c345f06) present in git history.
