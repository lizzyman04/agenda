# presentation/tasks/screens

Route-level widgets for the task side — the six destinations a user can
navigate to.

## Responsibility

Own the cubit (or read the one provided above them), wire state to the
widgets in `../widgets/`, and handle navigation. No layout primitives and
no business rules live here.

## Files

| File | Lines | Role |
|------|------:|------|
| `task_list_screen.dart` | 143 | Primary entry point. `BlocConsumer` over `TaskListCubit`: rebuilds the list and reacts to `TaskListWithPendingUndo` by showing the 5-second undo `SnackBar` |
| `task_detail_screen.dart` | 107 | One task, read-only, composed from `../widgets/detail/` |
| `project_screen.dart` | 115 | A project's subtasks with a completion progress bar and an add-subtask FAB; `projectId` comes from the route path parameter |
| `day_planner_screen.dart` | 121 | 1-3-5 planner: three `SlotSection`s driven by `DayPlannerCubit`, plus the over-capacity warning banner |
| `eisenhower_screen.dart` | 93 | 2x2 matrix board; partitions `TaskListCubit`'s items by `Item.eisenhowerQuadrant` |
| `gtd_filter_screen.dart` | 139 | Lists the distinct GTD context tags from `ItemRepository` and filters the task list by one (TASK-09) |

## Conventions in this slice

- **The screen owns the cubit, the widget owns nothing.** Every file in
  `../widgets/` receives data and callbacks from here.
- **Snackbars are driven by state, not by the tap handler.** The undo
  snackbar is raised from the `TaskListWithPendingUndo` state so it
  survives a rebuild and cannot be shown twice for one delete.
- **Quadrant partitioning is a read of the domain, not a rule.**
  `EisenhowerScreen` reads `Item.eisenhowerQuadrant`; it never recomputes
  urgency/importance itself.

## Upstream dependencies

`application/tasks/` (all three cubits and their states) ·
`domain/tasks/` (`Item`, `ItemType`, `EisenhowerQuadrant`,
`ItemRepository`) · `../widgets/` · `../form/` (navigation target) ·
`generated/l10n/` · `config/di/injection.dart`.
