---
quick_id: 260811-97x
slug: fix-goal-contribution-sheet-crash
date: 2026-08-11
mode: quick
---

# Fix savings-goal contribution sheet crash (Phase 03 UAT test 5 blocker)

## Problem

Submitting a contribution on the savings-goal detail screen throws:

```
'package:flutter/src/widgets/framework.dart':
Failed assertion: line 6268 pos 12: '_dependents.isEmpty': is not true.
```

The red error screen replaces the app and the contribution is never persisted.
Reproduced 2/2 on a physical Infinix X6831 during the Phase 03 UAT device
session; recorded in `.planning/phases/03-finance-core/03-UAT.md` (test 5,
severity blocker).

## Root cause

`lib/presentation/finance/screens/goal_detail_screen.dart` `_addContribution`
repeats the exact anti-pattern already fixed for the budget sheet in commit
`ae397ae`:

- `amountCtrl` / `noteCtrl` are created in method scope (lines 41-42) and
  disposed immediately after `await showModalBottomSheet` returns (lines
  152-153) — while the dismiss transition is still animating and the
  `TextField`s are still mounted. That produces "TextEditingController used
  after being disposed", which cascades into the
  `InheritedElement._dependents.isEmpty` assertion on the overlay.
- The sheet body is a `StatefulBuilder`, so nothing owns the controllers.
- `unawaited(cubit.addContribution(...))` (line 137) fires a cubit emit during
  sheet teardown, so a rebuild races the disposal.

A sweep of all 7 `showModalBottomSheet` call sites confirmed this is the only
remaining instance — the other six own their controllers in `State`.

## Approach

Mirror the working `_BudgetLimitSheet` pattern in
`budget_overview_screen.dart`:

1. Extract the sheet body into a private `_AddContributionSheet`
   `StatefulWidget` that owns `amountCtrl`, `noteCtrl` and `selectedDate`, and
   disposes the controllers in its own `State.dispose()`.
2. Return the built `SavingsGoalContribution` (or `null`) via `Navigator.pop`
   instead of calling the cubit from inside the sheet.
3. `await cubit.addContribution(...)` in the caller, after the sheet has fully
   closed. Drop the `unawaited()` call and the now-unused `dart:async` import
   if nothing else needs it.

## Tasks

- [ ] T1 — Refactor `_addContribution` + add `_AddContributionSheet` in
      `goal_detail_screen.dart`
- [ ] T2 — Add `test/presentation/finance/goal_contribution_sheet_test.dart`
      mirroring `budget_limit_sheet_test.dart`
- [ ] T3 — Run analyzer + full test suite
- [ ] T4 — Re-verify on device over adb (the original repro)

## Success criteria

- Adding a contribution does not throw; no red error screen.
- The contribution persists and the goal progress card advances
  (MT 0,00 → MT 250,00 on a MT 1.000,00 goal = 25%).
- New widget test fails against the old code and passes against the new.
- `flutter analyze` clean; existing suite still green.
- Phase 03 UAT test 5 flips from `issue` to `pass`.

## Out of scope

The other three Phase 03 UAT issues (category-name stub, SnackBar queueing,
task-link chip id) and the app-wide undo-timer defect. Tracked separately in
`03-UAT.md`.
