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
├── screens/   route-level widget; owns the form state and the cubit
├── widgets/   presentation-only cards and layout primitives
└── gtd/       the GTD clarification guide — models today, sheet in progress
```

### screens/

| File | Role |
|------|------|
| `task_form_screen.dart` | Create/edit form; owns controllers, finance links, and save |

### widgets/

| File | Role |
|------|------|
| `form_primitives.dart` | `FormCard`, `FieldRow`, `FieldDivider` — the layout set the form is built from |
| `gtd_guide_card.dart` | Entry-point card that opens the GTD guide |
| `advanced_options_card.dart` | Collapsible card holding the advanced fields |

### gtd/

| File | Role |
|------|------|
| `gtd_models.dart` | `GtdOpt`, `GtdResult`, `GtdNode` — the guide's data types |

## Conventions in this slice

- **Screens own state; widgets do not.** Every widget here takes plain data and
  callbacks, so each renders in isolation and in widget tests.
- **The GTD guide returns a value, it does not mutate.** The sheet builds a
  `GtdResult` and returns it via `Navigator.pop`; the form applies it to its own
  controllers. Nothing inside the guide touches a cubit.

## Status — incomplete

`task_form_screen.dart` is **1483 lines** and still breaches the project's
150-line limit. This slice is partially migrated:

- ✅ Layout primitives, the two cards, and the GTD data types are extracted
- ⬜ The GTD guide sheet (~730 lines, currently still inside
  `task_form_screen.dart`) needs decomposing into `gtd/screens/` +
  `gtd/widgets/`
- ⬜ The form body itself needs splitting into field-group widgets

Planned decomposition for the guide, tracked as Phase 3.1 plan `3.1-01`:

| Target file | Contents |
|-------------|----------|
| `gtd/gtd_answers.dart` | Accumulated answers value object + `toResult()` |
| `gtd/gtd_decision_tree.dart` | Node → question/icon/options mapping (pure, no widgets) |
| `gtd/screens/gtd_guide_sheet.dart` | Sheet chrome, history stack, controllers |
| `gtd/widgets/gtd_sheet_header.dart` | Handle bar, back/close, progress indicator |
| `gtd/widgets/gtd_option_node.dart` | Option-list question rendering |
| `gtd/widgets/gtd_text_node.dart` | Free-text question rendering |
| `gtd/widgets/gtd_review_node.dart` | Final review summary |
| `gtd/widgets/gtd_atoms.dart` | Icon box, review row, divider |

## Upstream dependencies

`application/tasks/task_list/` · `domain/tasks/` (Item, Priority, SizeCategory)
· `domain/finance/` (goal and debt linking) · `generated/l10n/`
