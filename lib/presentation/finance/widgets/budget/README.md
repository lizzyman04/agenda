# presentation/finance/widgets/budget

Budget-specific pieces. One file today: the sheet that sets a category's
monthly limit.

## Responsibility

Collect a limit amount and pop it. The merge of limits with actual spend
happens in `application/finance/budget/budget_aggregator.dart`; the bar
that renders the result is `../budget_progress_bar.dart`, shared with the
dashboard.

## Files

| File | Lines | Role |
|------|------:|------|
| `budget_limit_sheet.dart` | 126 | `BudgetLimitSheet` — bottom-sheet body for setting a category budget limit; owns and disposes its own `TextEditingController` |

## Conventions in this slice

- **The sheet owns its controller.** This is not stylistic. A controller
  created in the caller's method scope and disposed right after
  `await showModalBottomSheet` returns is disposed while the dismiss
  transition is still animating, producing "TextEditingController used
  after being disposed" and cascading into the
  `InheritedElement._dependents.isEmpty` assertion — a full red-screen
  crash. It shipped here first (fixed in `ae397ae`) and again in the goal
  contribution sheet. Regression test:
  `test/presentation/finance/budget_limit_sheet_test.dart`.
- **The sheet pops a value; the caller persists it.** `BudgetCubit.setLimit`
  is called by the screen after the sheet closes, never from inside it.

## Upstream dependencies

`domain/finance/category/transaction_category.dart` ·
`core/utils/` (amount parser/formatter) · `generated/l10n/`.
