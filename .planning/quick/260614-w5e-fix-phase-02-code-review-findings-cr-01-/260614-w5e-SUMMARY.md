---
phase: quick-260614-w5e
plan: 01
subsystem: tasks
tags: [bug-fix, data-integrity, memory-leak, error-surfacing, tdd]
dependency_graph:
  requires: [phase-02-task-core]
  provides: [CR-01-fix, WR-03-fix, WR-04-fix]
  affects: [task_form_screen, project_screen, item_repository_impl]
tech_stack:
  added: []
  patterns:
    - StatefulWidget owning TextEditingController (mirrors _BudgetLimitSheet pattern, commit ae397ae)
    - Guard-before-try-body pattern for input validation in repository layer
    - State-check-after-await pattern for error surfacing in _save/_submit
key_files:
  created: []
  modified:
    - lib/infrastructure/tasks/item_repository_impl.dart
    - lib/presentation/tasks/screens/task_form_screen.dart
    - lib/presentation/tasks/screens/project_screen.dart
    - test/infrastructure/tasks/item_repository_impl_test.dart
decisions:
  - updateItem guard fires outside try/catch (returns Err not throws) so ValidationFailure is returned, not wrapped in DatabaseFailure
  - _save error-check uses separate updateState/createState variables per branch to avoid Dart type-narrowing issues
metrics:
  duration: ~25min
  completed: 2026-06-14
  tasks_completed: 2
  files_modified: 4
---

# Phase quick-260614-w5e Plan 01: Fix Phase 02 Code Review Findings (CR-01, WR-03, WR-04) Summary

**One-liner:** Prevent silent subtask type corruption on edit (CR-01), fix controller leak in add-subtask sheet (WR-03), and surface save errors via SnackBar instead of silently closing (WR-04).

## What Was Built

Three code-review findings from Phase 02 Task Core were fixed:

**CR-01 (BLOCKER) — Subtask type corruption:**
- `ItemRepositoryImpl.updateItem` now guards: if `type != subtask && parentId != null` → returns `Err(ValidationFailure)` before touching the DAO
- `TaskFormScreen.initState` changed from `item?.type == ItemType.project ? project : task` to `item?.type ?? ItemType.task` — preserves `ItemType.subtask` for subtask edits
- `TaskFormScreen._save` edit branch now uses `widget.item!.type == ItemType.subtask ? widget.item!.type : _itemType` — locks type for subtask saves

**WR-03 — Controller memory leak:**
- Replaced the inline `showModalBottomSheet` builder (which created a `TextEditingController` in method scope, never disposing it) with `_AddSubtaskSheet`, a private `StatefulWidget` that owns and disposes its controller in `initState`/`dispose`
- Pattern mirrors `_BudgetLimitSheet` from `budget_overview_screen.dart` (commit ae397ae)

**WR-04 — Silent error swallowing on save:**
- `TaskFormScreen._save`: both edit and create branches now read cubit state after `await`; if `state is TaskListError`, show SnackBar with the failure message and return (form stays open)
- `ProjectScreen._AddSubtaskSheet._submit`: reads `widget.cubit.state` after `await addSubtask`; if `state is ProjectError`, show SnackBar and return (sheet stays open for retry)
- Added `import 'package:agenda/application/tasks/task_list/task_list_state.dart'` to `task_form_screen.dart` for `TaskListError` access

## TDD Gate Compliance

Task 1 followed RED/GREEN/REFACTOR:
- **RED commit** `7f8cd3d`: three failing tests in `updateItem` group (guard not yet implemented)
- **GREEN commit** `c2a407b`: guard implemented; all 8 tests pass
- No refactor step needed

## Test Results

```
flutter test test/infrastructure/tasks/item_repository_impl_test.dart --no-pub
00:00 +8: All tests passed!
```

Full task-domain suite:
```
flutter test test/infrastructure/tasks/ test/application/tasks/ test/domain/tasks/ --no-pub
00:10 +74: All tests passed!
```

## Static Analysis

```
flutter analyze lib/presentation/tasks/screens/ lib/infrastructure/tasks/item_repository_impl.dart
36 issues found (all info/style — 0 errors, 0 warnings)
```

The 36 info items are pre-existing line-length lint issues in `task_form_screen.dart` and `task_list_screen.dart`. None were introduced by this fix.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| RED | 7f8cd3d | test: add failing updateItem parentId guard tests |
| Task 1 (GREEN) | c2a407b | feat: fix CR-01 subtask type corruption and WR-04 error surfacing in TaskFormScreen |
| Task 2 | e333cd7 | fix: WR-03 controller leak and WR-04 error surfacing in ProjectScreen |

## Deviations from Plan

None — plan executed exactly as written. The `.dart_tool` and `build` symlinks from the main repo to the worktree were needed to allow `flutter test` to run from the worktree directory (the main repo's dart tooling infrastructure is not automatically available in the sparse worktree), but this is a GSD worktree setup detail, not a plan deviation.

## Known Stubs

None.

## Threat Flags

No new security-relevant surface introduced. The fixes close T-w5e-01 (parentId/type tamper guard) and T-w5e-02 (error state disclosure) as planned.

## Self-Check: PASSED

- `lib/infrastructure/tasks/item_repository_impl.dart`: contains `ValidationFailure('parentId must be null for type task or project')`
- `lib/presentation/tasks/screens/task_form_screen.dart`: contains `item?.type ?? ItemType.task` and `task_list_state.dart` import
- `lib/presentation/tasks/screens/project_screen.dart`: contains `_AddSubtaskSheet` StatefulWidget with `_controller.dispose()`
- `test/infrastructure/tasks/item_repository_impl_test.dart`: contains `group('updateItem', ...)` with 3 tests
- Commits 7f8cd3d, c2a407b, e333cd7 exist on branch `worktree-agent-a81c791942e8353e8`
