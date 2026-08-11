---
quick_id: 260811-97x
slug: fix-goal-contribution-sheet-crash
date: 2026-08-11
status: complete
commits:
  - a2f8e7d  # infrastructure: rebuild contributions list
  - f5347ba  # presentation: sheet owns controllers + goals slice restructure
---

# Summary — savings-goal contribution crash (Phase 03 UAT test 5)

## Outcome

Test 5 flips from **blocker** to **pass**, verified on the original device.

## What it actually was: two stacked defects

The reported crash was only the outer layer. Fixing it exposed a second,
independent bug that had been masked all along — the contribution would not
have persisted even without the crash.

### 1. Presentation — the crash

`goal_detail_screen.dart` `_addContribution` created both
`TextEditingController`s in method scope and disposed them right after
`await showModalBottomSheet` returned, while the dismiss transition was still
animating and the `TextField`s were still mounted → "TextEditingController
used after being disposed" → `InheritedElement._dependents.isEmpty` assertion
→ red screen. `unawaited(cubit.addContribution(...))` compounded it by
emitting during teardown.

Identical to the budget-limit sheet defect fixed in `ae397ae`. A sweep of all
seven `showModalBottomSheet` sites confirmed this was the last instance.

**Fix:** `AddContributionSheet` — a StatefulWidget owning the controllers,
disposing them in `State.dispose()`, returning the built contribution via
`Navigator.pop`. The caller awaits the cubit only after the sheet has closed.

### 2. Infrastructure — the persistence bug underneath

With the crash gone, the app showed a clean error state instead:

```
addContribution failed: Unsupported operation: Cannot add to a fixed-length list
```

`GoalRepositoryImpl.addContribution` called `model.contributions.add()`,
trusting `SavingsGoalModel`'s `List.empty(growable: true)` initializer. That
initializer only applies to freshly constructed models — Isar's generated
deserializer **assigns** the fixed-length list from `readObjectList` over the
field, so every model from `findById` has a non-growable list. The in-code
comment asserted the opposite and was wrong.

**Fix:** rebuild the list (`model.contributions = [...model.contributions, x]`)
and correct the model doc comment. `contributions` is the only mutable list
field on an Isar model in this codebase, so this was the sole instance.

## Architecture

Applied the new house rules to the slice touched:

```
presentation/finance/goals/
├── README.md          rules + rationale for this slice
├── screens/           detail (118), form (286*), list (100)  — own the cubit
└── widgets/           body (55), progress card (112), history (93),
                       sheet (140), dialog (42)               — cubit-free
```

`goal_detail_screen.dart`: 331 → 118 lines. The README documents the
sheet-ownership rule so this class of defect does not ship a third time.

`*` `goal_form_screen.dart` is still 286 lines — pre-existing, out of scope
here, part of the 21 remaining files over the 150-line limit.

## Verification

- `flutter test` — 211 pass (206 before; +5 new)
- `flutter analyze` — no new errors or warnings
- 5 new regression tests, **all confirmed failing against the pre-fix code**
  (checked by reverting each file and re-running)
- On device (Infinix X6831): contribution of 250 on a MT 1.000,00 goal →
  `MT 250,00 de MT 1.000,00`, 25%, progress bar advanced, entry in
  Histórico de contribuições, no crash

## Follow-ups not done here

- 21 other files exceed the 150-line limit (`task_form_screen.dart` is 1713)
- 4 folders exceed the 10-file limit; only this slice has a README
- Phase 03 UAT issues still open: tests 2, 3, 9, plus the app-wide undo-timer
  defect
