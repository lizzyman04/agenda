# application/tasks/project

Owns **one project** — its own record plus the subtask rollup shown on the
project screen (TASK-01, TASK-02).

## Responsibility

Load a project by id, keep its subtask list and completed/total counts in
sync after every mutation, and surface repository failures as state. The
parent/child relationship itself is modelled in `domain/tasks/item.dart`.

## Files

| File | Lines | Role |
|------|------:|------|
| `project_cubit.dart` | 119 | `ProjectCubit` — `loadProject`, `addSubtask`, `completeSubtask`, `deleteSubtask`; every mutation re-runs `_refreshSubtasks` so counts never drift |
| `project_state.dart` | 48 | Sealed state family: `ProjectInitial`, `ProjectLoading`, `ProjectLoaded` (project + subtasks + rollup counts), `ProjectError` |

## Conventions in this slice

- **Factory, not singleton** — one cubit per project screen, so two open
  projects never share state.
- **Refresh after every write.** Mutations do not patch the in-memory list;
  they re-query, which keeps the completion counts authoritative.
- **A failed count query is a failure of the whole load**, not a partial
  state — `_refreshSubtasks` emits `ProjectError` rather than showing a
  project with stale numbers.

## Upstream dependencies

`domain/tasks/` (`Item`, `ItemRepository`, `ItemType`) ·
`core/failures/` (`Result`, `Failure`).
