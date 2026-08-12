# presentation/finance/goals

Presentation slice for **savings goals** — the Objetivos tab and everything
reachable from it.

## Responsibility

Rendering and user interaction for savings goals only. This slice holds no
business rules: progress arithmetic lives in `domain/finance/goal/savings_goal.dart`,
and orchestration lives in `application/finance/goal/goal_cubit.dart`.

## Layout

```
goals/
├── screens/   route-level widgets; own the GoalCubit
└── widgets/   presentation-only pieces; no cubit, no persistence
```

Both subdirectories have their own README. The goal's save-time
construction logic lives one level up, in
`presentation/finance/goal_form_logic.dart`, alongside the other finance
forms' logic files.

### screens/

| File | Role |
|------|------|
| `goal_list_screen.dart` | Objetivos tab — lists active goals, entry point to create/detail |
| `goal_detail_screen.dart` | One goal: progress, contributions, edit/delete actions |
| `goal_form_screen.dart` | Create/edit a goal |

### widgets/

| File | Role |
|------|------|
| `goal_detail_body.dart` | Loaded-state body of the detail screen |
| `goal_progress_card.dart` | Progress header — amount saved, target, percentage |
| `goal_form_fields.dart` | The goal form's title/target/date fields; controllers stay on `goal_form_screen.dart` |
| `contribution_history_list.dart` | Newest-first list of manual contributions |
| `add_contribution_sheet.dart` | Bottom sheet that builds a `SavingsGoalContribution` |
| `delete_goal_dialog.dart` | Confirmation dialog before soft delete |

## Conventions in this slice

- **Screens own cubits; widgets never do.** Widgets take domain objects and
  callbacks, so each is renderable in isolation and in widget tests.
- **Sheets and dialogs own their controllers.** A sheet body is a
  `StatefulWidget` that creates its `TextEditingController`s in the State and
  disposes them in `State.dispose()`. It returns a value via `Navigator.pop`
  and never calls a cubit itself.

  This is not stylistic. Controllers created in a caller's method scope and
  disposed right after `await showModalBottomSheet` returns are disposed while
  the dismiss transition is still animating, producing "TextEditingController
  used after being disposed" and cascading into the
  `InheritedElement._dependents.isEmpty` assertion — a full red-screen crash.
  It shipped twice: once in the budget limit sheet (fixed in `ae397ae`) and
  again in the contribution sheet (Phase 03 UAT test 5). Regression tests:
  `test/presentation/finance/budget_limit_sheet_test.dart` and
  `goal_contribution_sheet_test.dart`.

- **Mutations run after the sheet closes.** The caller awaits the popped value,
  then awaits the cubit call — never `unawaited(...)` from inside the sheet,
  which emits during teardown and races disposal.

## Upstream dependencies

`application/finance/goal/` (GoalCubit, GoalState) · `domain/finance/`
(SavingsGoal, SavingsGoalContribution) · `core/utils/amount_formatter.dart`
