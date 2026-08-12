# presentation/tasks/form/widgets

Presentation-only pieces of the task form: layout primitives, the field
groups, and the finance-link sheet.

## Responsibility

Render fields and route every change back to the screen. Nothing here owns
a controller or calls a cubit — `TaskFormScreen` owns both.

## Files

| File | Lines | Role |
|------|------:|------|
| `form_primitives.dart` | 56 | `FormCard`, `FieldRow`, `FieldDivider` — the shared layout atoms of this form |
| `task_form_app_bar.dart` | 32 | Builds the form's `AppBar`; title switches create/edit, trailing action triggers save |
| `task_form_fields.dart` | 141 | Assembles the field groups below into the scrollable body: title/type, GTD entry, advanced options, finance-link summary |
| `title_type_card.dart` | 81 | Title field plus the task/project type toggle at the top of the form |
| `advanced_options_card.dart` | 76 | Collapsible card holding the advanced fields; the caller owns `expanded` |
| `schedule_fields.dart` | 150 | Priority, due date/time, and recurrence fields inside the advanced card |
| `flags_size_notes_fields.dart` | 115 | Urgent/important switches, size selector, description, and waiting-for notes |
| `gtd_guide_card.dart` | 74 | Entry-point card that opens the GTD clarification guide |
| `finance_link_card.dart` | 59 | Summary row for the linked goal or debt; opens the finance-link sheet on tap |
| `finance_link_sheet.dart` | 126 | `FinanceLinkSheet` + `FinanceLinkSelection` — pop-returning goal/debt picker with a "no link" option |

## Conventions in this slice

- **No controllers, no cubits, no `Navigator` state.** Every widget takes
  data plus callbacks; `finance_link_sheet.dart` resolves purely through
  `Navigator.pop(FinanceLinkSelection?)`.
- **Changes are routed through one callback.** Field groups mutate nothing
  directly — they hand a mutation to `onModelChanged`, which the screen
  wraps in `setState`. This is why the model can stay a plain mutable class.
- **This directory is at the ten-file cap.** A new field group belongs
  inside an existing file's group (schedule, flags/size/notes) unless it is
  genuinely a new *kind* of field.

## Upstream dependencies

`domain/tasks/` (`Priority`, `SizeCategory`, `ItemType`) ·
`domain/finance/` (`SavingsGoal`, `Debt` for the link sheet) ·
`../task_form_fields_model.dart` · `../task_form_pickers.dart` ·
`generated/l10n/`.
