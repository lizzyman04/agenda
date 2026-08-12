# presentation/finance/goals/screens

Route-level widgets for savings goals — the Objetivos tab and the two
screens reachable from it.

## Responsibility

Own the `GoalCubit`/`GoalListCubit`, own the form's controllers, and wire
state to the widgets in `../widgets/`. The `SavingsGoal` to persist is
built by `../../goal_form_logic.dart`.

## Files

| File | Lines | Role |
|------|------:|------|
| `goal_list_screen.dart` | 100 | Objetivos tab — lists active goals, entry point to create/detail |
| `goal_detail_screen.dart` | 118 | One goal: progress, contributions, edit/delete actions |
| `goal_form_screen.dart` | 150 | Create/edit a goal; owns the controllers and delegates the build to `goal_form_logic.dart` |

## Conventions in this slice

- **List and detail have different cubits and different lifecycles.**
  `GoalListCubit` subscribes to `GoalRepository.watchChanges()`;
  `GoalCubit` is a detail cubit loaded on demand by id.
- **Mutations run after the sheet closes.** The caller awaits the popped
  value from a sheet or dialog, then awaits the cubit call — never
  `unawaited(...)` from inside the sheet, which emits during teardown and
  races controller disposal. See `../README.md` for the crash this
  prevents.
- **`goal_form_screen.dart` sits at the 150-line cap.** Adding a field
  means adding it to `../widgets/goal_form_fields.dart`.

## Upstream dependencies

`application/finance/goal/` (`GoalCubit`, `GoalListCubit` and their
states) · `domain/finance/goal/` (`SavingsGoal`,
`SavingsGoalContribution`) · `../../goal_form_logic.dart` · `../widgets/` ·
`core/utils/amount_formatter.dart` · `generated/l10n/` ·
`config/di/injection.dart`.
