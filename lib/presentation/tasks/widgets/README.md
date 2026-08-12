# presentation/tasks/widgets

Presentation-only pieces shared across the task screens: cards, list
chrome, and the two bottom sheets.

## Responsibility

Render what they are given. Nothing here reads a repository or constructs a
cubit; `TaskListView` is the single exception and only in the sense that it
forwards user actions to the `TaskListCubit` the screen already provided.

## Layout

```
widgets/
├── (this directory)  cards, list chrome, sheets shared by several screens
└── detail/           the task detail screen's own cards and chips
```

## Files

| File | Lines | Role |
|------|------:|------|
| `task_card.dart` | 122 | Reusable card for one `Item`: title, priority chip, due date, quadrant label, completion checkbox, delete button |
| `task_list_view.dart` | 86 | `TaskListEmptyState`, `TaskSearchBar` (an `AppBar`-sized search field), and `TaskListView` — the list of `TaskCard`s wired to `TaskListCubit` |
| `quadrant_card.dart` | 80 | One Eisenhower quadrant: coloured header plus a scrollable list of title chips, with an empty label when the quadrant has none |
| `slot_section.dart` | 108 | One 1-3-5 slot: header with current-vs-max count, optional over-capacity banner, assigned items with remove buttons |
| `task_picker_sheet.dart` | 88 | `SlotSize` enum, `WarningBanner`, and `TaskPickerSheet` — picks a task to assign to a planner slot |
| `add_subtask_sheet.dart` | 90 | Bottom sheet for adding a subtask to a project; owns and disposes its own `TextEditingController` (WR-03) |
| `gtd_chip.dart` | 27 | A single GTD context tag as a selectable `FilterChip` (TASK-09) |

## Conventions in this slice

- **Sheets own their controllers.** `AddSubtaskSheet` is the reference
  implementation of the correct controller lifecycle: created in the
  `State`, disposed by the framework after the field unmounts.
- **Small related widgets share a file.** `task_list_view.dart` and
  `task_picker_sheet.dart` each hold two or three types that are never
  useful apart — grouping keeps the directory under the ten-file cap
  without inventing single-widget files.
- **Colour and label decisions read from the domain**, not from local
  conditionals — quadrant labels come from `EisenhowerQuadrant`.

## Upstream dependencies

`application/tasks/task_list/` (`TaskListCubit`) · `domain/tasks/`
(`Item`, `ItemType`, `EisenhowerQuadrant`) · `generated/l10n/`.
