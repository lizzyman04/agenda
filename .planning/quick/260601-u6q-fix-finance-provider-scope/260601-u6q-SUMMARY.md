---
quick_id: 260601-u6q
slug: fix-finance-provider-scope
status: complete
date: 2026-06-01
commit: d8dc04c
---

# Summary — Fix `_dependents.isEmpty` crash on finance form open

## What was wrong

Opening any finance form (Transaction/Debt/Recurring) threw
`framework.dart line 6268: _dependents.isEmpty: is not true`.

**Root cause:** the 6 finance cubits were hosted by `FinanceDashboardScreen`'s
`MultiBlocProvider`, which `IndexedStack` keeps permanently mounted. The list
screens pushed their form routes wrapped in `BlocProvider.value`, re-providing the
*same* cubit instance a second time at the root Navigator. One bloc was then owned by
two live `InheritedProvider` elements; during the route push/pop transition the
framework deactivated an `InheritedElement` while `BlocBuilder` dependents in the
still-mounted dashboard remained registered → assertion.

The earlier attempt (hoisting the provider *inside* the finance screen) failed because
the dual-provision across the route boundary was untouched.

## What changed

1. **`lib/app.dart`** — the 6 finance cubits (`TransactionCubit`, `BudgetCubit`,
   `GoalListCubit`, `DebtCubit`, `RecurringPaymentCubit`, `HomeDashboardCubit`) plus
   `LocaleCubit` are now provided in a top-level `MultiBlocProvider` **above
   `MaterialApp`** — i.e. above the Navigator. Every route (home tabs + pushed forms)
   inherits the same instances. (Key insight: `MaterialApp.home` sits *below* the
   Navigator, so providers there are invisible to pushed routes.)
2. **`finance_dashboard_screen.dart`** — removed the local `MultiBlocProvider` and the
   `_FinanceDashboardView` split; the screen now returns its `DefaultTabController` +
   `Scaffold` directly. Dropped now-unused cubit / injection / flutter_bloc imports.
3. **`transaction_list` / `debt_list` / `recurring_payment` screens** — dropped
   `BlocProvider.value`; forms are pushed directly and read their cubit via the
   inherited `context.read`.
4. **`goal_list` screen** — dropped the `BlocProvider.value` wrapper (it was dead
   weight: `GoalFormScreen` self-provides via `getIt<GoalCubit>`; the list refreshes
   through `GoalListCubit`'s watch stream).

## close() hygiene (requirement #4) — verified, no change needed

All 5 stream-backed app-scoped cubits already cancel their subscription in `close()`:
`TransactionCubit`, `BudgetCubit`, `GoalListCubit`, `DebtCubit`, `HomeDashboardCubit`.
`RecurringPaymentCubit` holds no subscription. App-scoped `BlocProvider`s close these
on app teardown.

## Verification

- `flutter analyze lib/app.dart lib/presentation/finance/` → 0 errors / 0 warnings
  (37 pre-existing `info` style lints only: line length, `discarded_futures`).
- No `BlocProvider.value` remains in `lib/presentation/finance/` (code).

## Noted follow-up (out of scope, not a regression)

`goal_form_screen.dart` calls `getIt<GoalCubit>()` (a factory) at two separate sites
without `close()` — a minor leak in the goal CRUD cubit, unrelated to this crash and
not one of the 6 dashboard cubits. Flagged for a future cleanup.

## Device re-test (still required) — MUST be a COLD RESTART

This fix relocates the 6 `BlocProvider`s across the `MaterialApp` boundary (from inside
`FinanceDashboardScreen` to above `MaterialApp`). That is a structural element-tree
change. **Hot reload (`r`) cannot relocate an existing Element** — it keeps the stale
tree and re-runs `build()`, during which the old finance `InheritedProvider`s deactivate
while their tab `BlocBuilder` dependents are still attached → the same
`InheritedElement.debugDeactivated()` → `assert(_dependents.isEmpty)` (framework.dart:6268)
fires on tab switch (observed on the Orçamentos tab).

Re-test procedure:
1. Fully stop the app (do NOT hot reload). Then:
   `flutter run` (or press `R` for hot RESTART, capital R, not `r`).
2. Open Finance, switch through all 6 tabs (Resumo → Recorrências), including Orçamentos.
3. Open the Transações, Dívidas, and Recorrências forms via FAB; save one of each.

No `_dependents.isEmpty` assertion should occur after a cold restart.

If it STILL crashes after a genuine cold restart, capture the FULL stack trace (the
widget frames directly above the assertion identify which InheritedElement deactivated)
— that would indicate a real residual bug rather than stale hot-reload state.

## Confirmed clean (no budgets code bug)

`budget_overview_screen.dart` uses `context.read<BudgetCubit>()` + `BlocBuilder` only —
no `BlocProvider`, no `BlocProvider.value`, no route push. There is no `budget_form_screen`.
Budgets cannot itself trigger this assertion; the prior fix covers it.
