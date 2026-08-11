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
├── task_form_logic.dart         pure functions: build/load/apply
├── task_form_fields_model.dart  mutable non-controller field state
├── screens/   route-level widget; owns the form state and the cubit
├── widgets/   presentation-only cards and layout primitives
└── gtd/       the GTD clarification guide — a self-contained sub-slice
    ├── screens/   the guide sheet; owns history, controllers, answers
    └── widgets/   node renderers and sheet chrome
```

### form/ (top level)

| File | Lines | Role |
|------|------:|------|
| `task_form_logic.dart` | 99 | Pure functions: `loadFinanceLinks`, `buildFormItem`, `applyGtdResult` |
| `task_form_fields_model.dart` | 116 | `TaskFormFieldsModel` — mutable holder for every non-controller field, plus `FinanceLinksSnapshot`/`GtdFormValues` and the `apply*` batch-update methods |

### screens/

| File | Lines | Role |
|------|------:|------|
| `task_form_screen.dart` | 148 | Create/edit form; owns controllers and `TaskFormFieldsModel`, wires save/GTD-guide/finance-link flows |

### widgets/

| File | Lines | Role |
|------|------:|------|
| `form_primitives.dart` | 56 | `FormCard`, `FieldRow`, `FieldDivider` |
| `gtd_guide_card.dart` | 74 | Entry-point card that opens the guide |
| `advanced_options_card.dart` | 69 | Collapsible card for the advanced fields |
| `title_type_card.dart` | 81 | Title field + task/project type toggle |
| `schedule_fields.dart` | 150 | Priority, due date/time, and recurrence fields |
| `flags_size_notes_fields.dart` | 115 | Urgent/important, size, description, waiting-for fields |
| `finance_link_sheet.dart` | 126 | `FinanceLinkSheet` + `FinanceLinkSelection` — pop-returning goal/debt picker |
| `task_form_fields.dart` | 150 | Assembles the field-group widgets above; owns date/time/finance-link picker mechanics (model-only, no controllers) |

### gtd/

The guide is split three ways: **data**, **decisions**, and **rendering**.

| File | Lines | Role |
|------|------:|------|
| `gtd_models.dart` | 120 | `GtdNode`, `GtdResult`, the `GtdNodeSpec` union, main-path progress |
| `gtd_answers.dart` | 69 | Mutable answers accumulated while walking the tree |
| `gtd_tree_actions.dart` | 41 | `GtdTreeContext` — the callbacks the tree may invoke |
| `gtd_tree_clarify.dart` | 142 | Questions q1–q4b: is it actionable, delegable, quick |
| `gtd_tree_prioritize.dart` | 98 | Questions q5–review: importance, impact |
| `gtd_tree_scheduling.dart` | 92 | Deadline and impact specs, whose options are computed |
| `screens/gtd_guide_sheet.dart` | 139 | History stack, controllers, navigation, result |
| `widgets/gtd_option_node.dart` | 80 | Renders a `GtdOptionSpec` |
| `widgets/gtd_text_node.dart` | 62 | Renders a `GtdTextSpec` |
| `widgets/gtd_review_node.dart` | 143 | Terminal summary step |
| `widgets/gtd_sheet_header.dart` | 83 | Drag handle, back/close, progress bar |
| `widgets/gtd_sheet_scaffold.dart` | 61 | Sheet sizing and the inter-node transition |
| `widgets/gtd_atoms.dart` | 88 | Icon box, review row, divider |
| `widgets/gtd_cancel_dialog.dart` | 30 | Discard-confirmation dialog |

## Conventions in this slice

- **Screens own state; widgets do not.** Every widget takes plain data and
  callbacks, so each renders in isolation and in widget tests.
- **The decision tree contains no widgets.** `clarifySpec` and
  `prioritizeSpec` are pure functions from `(GtdNode, GtdTreeContext)` to a
  `GtdNodeSpec` — data describing what to ask. The sheet turns specs into
  widgets. This is what makes the whole flow unit-testable: see
  `test/presentation/tasks/gtd_decision_tree_test.dart`, which walks every
  node and asserts on state transitions without pumping a single frame.
- **The tree never navigates.** It calls `push`, `endWithSnackbar`, or
  `abandon` on the context; only the sheet touches `Navigator`.
- **The guide returns a value, it does not mutate.** The sheet builds a
  `GtdResult` and returns it via `Navigator.pop`; the form applies it to its
  own controllers. Nothing inside the guide touches a cubit.
- **Controllers live on the sheet, not on nodes.** The sheet outlives
  individual nodes, so text typed at q1 survives navigating back and forth.

## Adding a question

1. Add the node to `GtdNode` in `gtd_models.dart`.
2. Add its case to whichever half owns it — `clarify` or `prioritize`.
3. If it belongs on the happy path, add it to `gtdMainPath` so the progress
   bar counts it.
4. No rendering changes are needed unless the question needs a new *kind* of
   input, in which case add a `GtdNodeSpec` subtype and a matching widget.

The `every node resolves` test will fail if a node is added without a spec, or
if both halves claim it.

## Status

The whole `tasks/form/` slice is compliant — every file, including the GTD
sub-slice, is at or under 150 lines (`dart run tool/check_architecture.dart`
reports no LINES violations under this directory).

`task_form_screen.dart` still owns every `TextEditingController` and the
cubit call, but the non-controller field state (`itemType`, `priority`,
`dueDate`, the finance-link ids, `advancedExpanded`, …) lives in one mutable
`TaskFormFieldsModel` (`task_form_fields_model.dart`) instead of a dozen
separate `State` fields. `TaskFormFields` (`widgets/task_form_fields.dart`)
receives that model read-only plus a single `onModelChanged` callback the
screen wraps in `setState` — this is what keeps the screen's `build()` to a
handful of lines despite wiring five field-group widgets. Date/time pickers
and the finance-link sheet only ever touch the model, so `TaskFormFields`
implements them directly rather than bouncing back to the screen; the GTD
guide also updates text controllers, so it stays screen-owned.

## Upstream dependencies

`application/tasks/task_list/` · `domain/tasks/` (Item, Priority, SizeCategory)
· `domain/finance/` (goal and debt linking) · `generated/l10n/`
