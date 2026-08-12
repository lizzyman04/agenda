# presentation/tasks/form/screens

The route-level widget of the task form sub-slice.

## Responsibility

Own the form's state — every `TextEditingController`, the
`TaskFormFieldsModel`, and the `GlobalKey<FormState>` — and make the one
cubit call that saves. Field layout lives in `../widgets/`, pure
construction logic in `../task_form_logic.dart`.

## Files

| File | Lines | Role |
|------|------:|------|
| `task_form_screen.dart` | 144 | `TaskFormScreen` — create/edit a task or project; owns the controllers and the field model, wires save, the GTD guide, and the finance link |

## Conventions in this slice

- **This is the only stateful file in the sub-slice.** Everything under
  `../widgets/` is presentational; everything under `../` at the top level
  is a plain function or a data holder.
- **Controllers live here, non-controller field state lives in the model.**
  `TaskFormFieldsModel` holds `itemType`, `priority`, `dueDate`, the
  finance-link ids and the expansion flag; `TaskFormFields` receives it
  read-only plus a single `onModelChanged` callback the screen wraps in
  `setState`. That split is what keeps `build()` short despite five field
  groups.
- **Helpers do the work off-screen.** The app bar
  (`../widgets/task_form_app_bar.dart`), the GTD entry point
  (`../task_form_gtd_entry.dart`) and the failure snackbar
  (`../task_form_save_feedback.dart`) were extracted so this file stays
  under the 150-line cap; the state itself never left.

## Upstream dependencies

`application/tasks/task_list/` (`TaskListCubit`, `TaskListState`) ·
`domain/tasks/` (`Item`, `Priority`, `SizeCategory`, `ItemType`) ·
`../` (logic, model, pickers, GTD entry, save feedback) · `../widgets/` ·
`generated/l10n/` · `config/di/injection.dart`.
