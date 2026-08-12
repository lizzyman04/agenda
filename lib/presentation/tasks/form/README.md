# presentation/tasks/form

Presentation slice for **creating and editing a task or project**, including
the GTD clarification guide reachable from it.

## Responsibility

Form rendering, field state, and the GTD decision tree. No business rules:
task validation and persistence live in `application/tasks/task_list/` and
`domain/tasks/`.

## Layout

```
form/
├── (this directory)  pure logic, the field model, pickers, feedback
├── screens/   route-level widget; owns the form state and the cubit
├── widgets/   presentation-only cards and layout primitives
└── gtd/       the GTD clarification guide — a self-contained sub-slice
    ├── screens/   the guide sheet; owns history, controllers, answers
    └── widgets/   node renderers and sheet chrome
```

Every subdirectory has its own README with a file/role table; this file
covers the top level and the slice-wide rules.

### form/ (top level)

| File | Lines | Role |
|------|------:|------|
| `task_form_logic.dart` | 99 | Pure functions: `loadFinanceLinks`, `buildFormItem`, `applyGtdResult` |
| `task_form_fields_model.dart` | 141 | `TaskFormFieldsModel` — mutable holder for every non-controller field, plus `FinanceLinksSnapshot`/`GtdFormValues`/`TaskFormFieldsMutator` and the `apply*` batch-update methods |
| `task_form_pickers.dart` | 76 | `BuildContext`-driven due-date/due-time/finance-link helpers; each applies its result through the caller's mutator rather than touching the model directly |
| `task_form_gtd_entry.dart` | 24 | Presents the GTD guide sheet and returns the raw `GtdResult` (or `null` if dismissed) — it does not apply it |
| `task_form_save_feedback.dart` | 22 | Shows the failure snackbar after a save returns `false`, reading the message from the current `TaskListError` state |

## Conventions in this slice

- **Screens own state; widgets do not.** Every widget takes plain data and
  callbacks, so each renders in isolation and in widget tests.
- **Pure logic sits at the top level, not inside the screen.** Anything
  that can be written as a plain function — building the `Item`, loading
  the finance links, applying a `GtdResult` — lives in a `task_form_*.dart`
  file here and is tested without pumping a frame.
- **Pickers mutate through the caller.** `task_form_pickers.dart` takes a
  `TaskFormFieldsMutator` and applies its result through it, preserving the
  "screens own state, widgets take data + callbacks" rule even for helpers
  that need a `BuildContext`.
- **The guide returns a value, it does not mutate.** The sheet builds a
  `GtdResult` and returns it via `Navigator.pop`; the form applies it to
  its own controllers. Nothing inside the guide touches a cubit. See
  `gtd/README.md` for the tree's own rules and for how to add a question.
- **Controllers live on the screen (and on the guide sheet), nowhere else.**

## Status

The whole `tasks/form/` slice is compliant — every file, including the GTD
sub-slice, is at or under 150 lines (`dart run tool/check_architecture.dart`
reports no LINES violations under this directory), and every directory is
under the ten-file cap.

`task_form_screen.dart` still owns every `TextEditingController` and the
cubit call, but the non-controller field state (`itemType`, `priority`,
`dueDate`, the finance-link ids, `advancedExpanded`, …) lives in one mutable
`TaskFormFieldsModel` instead of a dozen separate `State` fields.
`TaskFormFields` (`widgets/task_form_fields.dart`) receives that model
read-only plus a single `onModelChanged` callback the screen wraps in
`setState` — this is what keeps the screen's `build()` to a handful of lines
despite wiring five field-group widgets.

Coverage: `test/presentation/tasks/task_form_test.dart` covers the form,
`gtd_decision_tree_test.dart` and `gtd_test.dart` cover the guide.

## Upstream dependencies

`application/tasks/task_list/` · `domain/tasks/` (Item, Priority,
SizeCategory, ItemType) · `domain/finance/` (goal and debt linking) ·
`generated/l10n/` · `config/di/injection.dart`.
