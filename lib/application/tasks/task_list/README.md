# application/tasks/task_list

Owns the **task list** — its filter, its search, its undo window, and the
next occurrence produced when a recurring task is completed.

## Responsibility

Query selection, result mapping, and the soft-delete/undo state machine
(TASK-11, TASK-12, T-02-05). Persistence lives behind `ItemRepository`;
recurrence date maths lives in `domain/tasks/recurrence_engine.dart`.

## Files

| File | Lines | Role |
|------|------:|------|
| `task_list_cubit.dart` | 150 | `TaskListCubit` — subscribes to `watchChanges()`, applies filters/search, handles complete/delete/undo. Factory, one per screen open |
| `task_list_state.dart` | 70 | Sealed state family: `TaskListInitial`, `TaskListLoading`, `TaskListLoaded`, `TaskListWithPendingUndo` (carries the deleted id plus the list minus that item), `TaskListError` |
| `task_list_filter.dart` | 45 | `TaskListFilter` — multi-criteria filter; every field optional, `null` meaning "no filter on this axis" |
| `task_list_reload.dart` | 47 | `reloadTaskListState` (picks search-vs-filter query and maps the result to a state) and `currentItemsFromState` |
| `recurring_completion.dart` | 31 | `buildNextOccurrence` — pure; builds the follow-up `Item` with `id: 0` so Isar assigns a fresh auto-increment id (TASK-10) |

## Conventions in this slice

- **The cubit orchestrates; the helpers decide.** `_reload()` handles
  subscription and `emit`; the query choice and result mapping live in
  `task_list_reload.dart` so they can be tested without a cubit.
- **Undo is a state, not a timer side effect.**
  `TaskListWithPendingUndo` carries everything the snackbar needs, and the
  cubit transitions back to `TaskListLoaded` after
  `AppConstants.undoSnackbarDuration`.
- **Recurrence roll-forward is pure.** Completing a recurring item calls
  `buildNextOccurrence` and persists the result; no date maths inline.

## Upstream dependencies

`domain/tasks/` (`Item`, `ItemRepository`, `ItemType`, `RecurrenceEngine`)
· `core/failures/` (`Result`, `Failure`) · `core/constants/app_constants.dart`.
