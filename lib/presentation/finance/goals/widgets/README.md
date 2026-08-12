# presentation/finance/goals/widgets

Presentation-only pieces of the savings-goals slice: the detail body, the
progress header, the contribution list, and the two modals.

## Responsibility

Render goals. Nothing here owns a cubit; progress arithmetic lives in
`domain/finance/goal/savings_goal.dart` and orchestration in
`application/finance/goal/goal_cubit.dart`.

## Files

| File | Lines | Role |
|------|------:|------|
| `goal_detail_body.dart` | 55 | Loaded-state body of the detail screen |
| `goal_progress_card.dart` | 121 | Progress header — amount saved, target, percentage |
| `goal_form_fields.dart` | 115 | `GoalFormFields` — the goal form's title/target/date fields; controllers are owned by `goal_form_screen.dart` |
| `contribution_history_list.dart` | 93 | `ContributionHistoryList` and its `_ContributionTile` — newest-first list of manual contributions |
| `add_contribution_sheet.dart` | 140 | Bottom sheet that builds a `SavingsGoalContribution`; owns and disposes its own controllers |
| `delete_goal_dialog.dart` | 42 | Confirmation dialog before soft delete |

## Conventions in this slice

- **Sheets and dialogs own their controllers**, and pop a value rather
  than calling a cubit. `add_contribution_sheet.dart` is the file where
  getting this wrong crashed the app during Phase 03 UAT — see
  `../README.md` for the post-mortem and
  `test/presentation/finance/goal_contribution_sheet_test.dart` for the
  regression test.
- **Widgets take domain objects and callbacks**, so each renders in
  isolation and in a widget test.
- **Percentages are read, not recomputed.** The progress card renders what
  `SavingsGoal` and `GoalCubit` already computed.

## Upstream dependencies

`domain/finance/goal/` (`SavingsGoal`, `SavingsGoalContribution`) ·
`core/utils/amount_formatter.dart` · `generated/l10n/`.
