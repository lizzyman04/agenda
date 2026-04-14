---
phase: 02
plan: 03
subsystem: task-application
tags: [application, cubit, bloc, state-management, task-list, project, day-planner]
dependency_graph:
  requires: [lib/domain/tasks/* (Plan 01), lib/infrastructure/tasks/item_repository_impl.dart (Plan 02)]
  provides: [TaskListCubit, TaskListState, TaskListFilter, ProjectCubit, ProjectState, DayPlannerCubit, DayPlannerState, application test suite]
  affects: [02-04-PLAN.md (presentation consumes these cubits), 02-05-PLAN.md (GTD/search/filter wired via TaskListCubit)]
tech_stack:
  added: []
  patterns: [bloc-cubit-factory, equatable-state, watch-stream-listener, timer-undo, mocktail-bloc-test, sealed-state-class, typed-result-is-check]
key_files:
  created:
    - lib/application/tasks/task_list/task_list_state.dart
    - lib/application/tasks/task_list/task_list_filter.dart
    - lib/application/tasks/task_list/task_list_cubit.dart
    - lib/application/tasks/project/project_state.dart
    - lib/application/tasks/project/project_cubit.dart
    - lib/application/tasks/day_planner/day_planner_state.dart
    - lib/application/tasks/day_planner/day_planner_cubit.dart
    - test/application/tasks/task_list_cubit_test.dart
    - test/application/tasks/project_cubit_test.dart
    - test/application/tasks/day_planner_cubit_test.dart
  modified: []
decisions:
  - "Used typed is-check pattern (result is Err<T>) instead of untyped (result is Err) + cast to avoid unnecessary_cast warnings — matches item_repository_impl.dart convention"
  - "applyFilter() and search() changed to async Future<void> to satisfy discarded_futures lint — plan spec had void but analyzer requires async for _reload() callers"
  - "DayPlannerCubit.remove() omits slotLimitWarning: false (default) — avoid_redundant_argument_values lint compliance"
  - "ProjectCubit uses Dart 3 if-case pattern (if (state case ProjectLoaded(:final project))) instead of is-check + cast — eliminates unnecessary_cast warnings"
  - "_WhenMultiple extension in project_cubit_test provides sequential mock answers for completeSubtask rollup test (counts change between calls)"
metrics:
  duration: ~25m
  completed_date: "2026-04-14"
  tasks_completed: 5
  files_created: 10
  files_modified: 0
  tests_added: 27
---

# Phase 02 Plan 03: Task Application Layer Summary

## One-liner

TaskListCubit with watchChanges subscription + undo timer, ProjectCubit with subtask rollup, DayPlannerCubit as ephemeral 1-3-5 Rule state machine — 27 tests passing, zero Isar imports in application layer.

## What Was Built

### TaskListFilter (Task 2)

`lib/application/tasks/task_list/task_list_filter.dart` — Equatable multi-criteria filter value object:

- Optional fields: `itemType`, `quadrant`, `gtdContext`, `dueDateFrom`, `dueDateTo`, `projectId`, `showCompleted`
- `TaskListFilter.empty` convenience constant — no active filters
- Passed directly to `ItemRepository.filterItems()` by `TaskListCubit._reload()`

### TaskListState (Task 2)

`lib/application/tasks/task_list/task_list_state.dart` — sealed class hierarchy:

- `TaskListInitial` — pre-load
- `TaskListLoading` — in-flight (reserved for future use; _reload() emits directly to Loaded/Error)
- `TaskListLoaded` — items, active filter, search query
- `TaskListWithPendingUndo` — carries `deletedItemId` + item list with item removed; transitions to Loaded after 5s timer
- `TaskListError` — wraps domain `Failure`
- All extend `Equatable` with correct `props`

### TaskListCubit (Task 2)

`lib/application/tasks/task_list/task_list_cubit.dart` — `@injectable` factory cubit:

- `start()` — subscribes to `watchChanges()` stream, calls `_reload()` on every change
- `applyFilter()` / `search()` — update filter/query state and reload (async to satisfy lint)
- `softDelete()` — calls repository, emits `TaskListWithPendingUndo`, starts 5s `Timer`
- `restoreItem()` — cancels timer, calls repository, reloads
- `completeItem()` — updates item with `isCompleted: true`, watch stream handles reload
- `close()` — cancels both `_undoTimer` and `_watchSubscription` (T-02-06 mitigation)
- `_reload()` — routes to `searchByTitle` or `filterItems` based on `_searchQuery`

### ProjectState and ProjectCubit (Task 3)

`lib/application/tasks/project/project_state.dart` — sealed states: `ProjectInitial`, `ProjectLoading`, `ProjectLoaded` (with `completionRatio` getter), `ProjectError`

`lib/application/tasks/project/project_cubit.dart` — `@injectable` factory cubit:

- `loadProject(id)` — emits Loading → Loaded with subtask list and (completed, total) rollup
- `addSubtask()` — creates `ItemType.subtask` with `parentId`, refreshes rollup
- `completeSubtask()` — updates item with `isCompleted: true`, refreshes rollup
- `deleteSubtask()` — soft-deletes, refreshes rollup
- `_refreshSubtasks()` — calls `getSubtaskCounts` and `getSubtasks` in parallel, emits `ProjectLoaded`

### DayPlannerState and DayPlannerCubit (Task 3)

`lib/application/tasks/day_planner/day_planner_state.dart` — single Equatable state class:

- `bigTask`, `mediumTasks`, `smallTasks` — slot contents
- `slotLimitWarning` — true when last assignment exceeded capacity (soft warning)
- `isBigSlotFull`, `areMediumSlotsFull`, `areSmallSlotsFull` — computed from `AppConstants`

`lib/application/tasks/day_planner/day_planner_cubit.dart` — `@injectable` factory cubit:

- `assignBig()` / `assignMedium()` / `assignSmall()` — add to respective slots with overflow warning
- `remove(id)` — removes from whichever slot holds the item
- `clearAll()` — resets to `DayPlannerState()`
- No Isar, no repository — pure in-memory state machine

### Tests (Tasks 1 + 4)

27 tests across 3 files:

- `task_list_cubit_test.dart` — 8 tests: initial state, start/load, search, applyFilter, softDelete+undo, restoreItem, completeItem, error path
- `project_cubit_test.dart` — 5 tests: initial state, loadProject rollup, addSubtask type/parentId, completeSubtask count update, deleteSubtask refresh
- `day_planner_cubit_test.dart` — 14 tests: initial state, assignBig, slot-full warning, x3/x4 medium, x5/x6 small, remove from each slot, clearAll, isBigSlotFull, areMediumSlotsFull, areSmallSlotsFull

## Success Criteria Verification

- [x] `TaskListCubit` subscribes to `watchChanges()` in `start()`
- [x] `DayPlannerCubit` class has `@injectable` annotation (factory, not `@LazySingleton`)
- [x] `DayPlannerCubit` uses `AppConstants.rule135MediumTasks` and `AppConstants.rule135SmallTasks` — no hardcoded 1, 3, or 5
- [x] All states extend `Equatable` with non-empty `props`
- [x] `softDelete` emits `TaskListWithPendingUndo` then transitions to `TaskListLoaded` after timer
- [x] `restoreItem` cancels the undo timer before restoring
- [x] `flutter test test/application/tasks/ --no-pub` exits 0 — 27/27 passing
- [x] `flutter analyze --no-fatal-infos` exits 0
- [x] No Isar imports in `lib/application/tasks/`

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1+2+3 | 14ea76a | test(02-03): add application test stubs + all application layer implementation files |
| 4+5 | 1b3b17f | test(02-03): fill application test assertions — 27 tests passing |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Used typed is-check pattern to eliminate unnecessary_cast warnings**
- **Found during:** Task 2 — flutter analyze
- **Issue:** Plan spec used `if (result is Err) { emit(...(result as Err).failure); }` pattern. Since `Result<T>` is `typedef Object`, the `as Err` cast after `is Err` check triggers `unnecessary_cast` warning. Same applied to plan's use of `(result as Success<T>).value`.
- **Fix:** Changed all result checks to typed pattern: `if (result is Err<T>) { emit(...result.failure); }`. For `Success<T>` extraction after an `is Err<T>` guard, used `(result as Success<T>).value` only where no alternative — or used `is Success<T>` check directly.
- **Files modified:** `lib/application/tasks/task_list/task_list_cubit.dart`, `lib/application/tasks/project/project_cubit.dart`
- **Commit:** 14ea76a

**2. [Rule 1 - Bug] Changed applyFilter() and search() to async Future<void>**
- **Found during:** Task 2 — flutter analyze
- **Issue:** Plan spec declared both methods as `void` with `_reload()` called without await. The `discarded_futures` lint flags non-async functions that call Future-returning methods without awaiting.
- **Fix:** Changed return type to `Future<void>` and added `async`/`await` on both methods.
- **Files modified:** `lib/application/tasks/task_list/task_list_cubit.dart`
- **Commit:** 14ea76a

**3. [Rule 1 - Bug] Used Dart 3 if-case pattern in ProjectCubit to eliminate unnecessary_cast**
- **Found during:** Task 3 — flutter analyze
- **Issue:** Plan spec used `if (state is ProjectLoaded) { final loaded = state as ProjectLoaded; }` which triggers `unnecessary_cast` since the `is` check promotes the type.
- **Fix:** Changed to `if (state case ProjectLoaded(:final project)) { ... }` using Dart 3 pattern matching to avoid both the explicit `as` cast and the separate `loaded` variable.
- **Files modified:** `lib/application/tasks/project/project_cubit.dart`
- **Commit:** 14ea76a

**4. [Rule 1 - Bug] Changed cubit.close() calls to await in test bodies**
- **Found during:** Task 4 — flutter analyze
- **Issue:** `DayPlannerCubit.close()` returns `Future<void>`. Calling it without `await` in non-async test callbacks triggers `discarded_futures`.
- **Fix:** Made affected test callbacks `async` and awaited `cubit.close()`.
- **Files modified:** `test/application/tasks/day_planner_cubit_test.dart`, `test/application/tasks/task_list_cubit_test.dart`
- **Commit:** 1b3b17f

**5. [Rule 1 - Bug] Removed unused imports from initial test stubs**
- **Found during:** Task 1 — flutter analyze
- **Issue:** Plan's stub template included `package:bloc_test/bloc_test.dart` and cubit imports that are unused in empty group bodies, causing `unused_import` warnings (exit 1).
- **Fix:** Removed unused imports from stub files; they are re-added in Task 4 when the actual tests are written.
- **Files modified:** `test/application/tasks/task_list_cubit_test.dart`, `test/application/tasks/project_cubit_test.dart`, `test/application/tasks/day_planner_cubit_test.dart`
- **Commit:** 14ea76a

## Known Stubs

None. All cubits are fully implemented and all test assertions are filled.

## Threat Flags

No new threat surface introduced. All application layer files use only domain types and Flutter/BLoC framework imports. T-02-05 (stale cubit state after soft-delete) is mitigated: `TaskListCubit` immediately removes the item from state in `softDelete()` before the watch stream fires, and `watchChanges()` subscription ensures state is rebuilt from a fresh query on every collection change.

## Self-Check: PASSED

Files verified:
- `lib/application/tasks/task_list/task_list_state.dart` — FOUND
- `lib/application/tasks/task_list/task_list_filter.dart` — FOUND
- `lib/application/tasks/task_list/task_list_cubit.dart` — FOUND
- `lib/application/tasks/project/project_state.dart` — FOUND
- `lib/application/tasks/project/project_cubit.dart` — FOUND
- `lib/application/tasks/day_planner/day_planner_state.dart` — FOUND
- `lib/application/tasks/day_planner/day_planner_cubit.dart` — FOUND
- `test/application/tasks/task_list_cubit_test.dart` — FOUND
- `test/application/tasks/project_cubit_test.dart` — FOUND
- `test/application/tasks/day_planner_cubit_test.dart` — FOUND

Commits verified:
- 14ea76a — FOUND
- 1b3b17f — FOUND
