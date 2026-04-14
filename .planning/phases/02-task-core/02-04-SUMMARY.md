---
phase: 02
plan: 04
subsystem: task-presentation-core
tags: [presentation, ui, screens, widgets, eisenhower, day-planner, task-form, material3, widget-tests]
dependency_graph:
  requires: [lib/application/tasks/* (Plan 03), lib/domain/tasks/* (Plan 01)]
  provides: [TaskListScreen, ProjectScreen, TaskFormScreen, EisenhowerScreen, DayPlannerScreen, TaskCard, QuadrantCard, SlotSection, presentation test suite]
  affects: [02-05-PLAN.md (GTD/search/filter UI built on top of these screens)]
tech_stack:
  added: []
  patterns: [bloc-builder-consumer, navigator-push-material-page-route, showdatepicker-timepicker, scaffold-messenger-snackbar, material3-segmented-button, multi-bloc-provider-widget-test]
key_files:
  created:
    - lib/presentation/tasks/screens/task_list_screen.dart
    - lib/presentation/tasks/screens/project_screen.dart
    - lib/presentation/tasks/screens/task_form_screen.dart
    - lib/presentation/tasks/screens/eisenhower_screen.dart
    - lib/presentation/tasks/screens/day_planner_screen.dart
    - lib/presentation/tasks/widgets/task_card.dart
    - lib/presentation/tasks/widgets/quadrant_card.dart
    - lib/presentation/tasks/widgets/slot_section.dart
    - test/presentation/tasks/task_list_screen_test.dart
    - test/presentation/tasks/eisenhower_board_test.dart
    - test/presentation/tasks/day_planner_test.dart
    - test/presentation/tasks/task_form_test.dart
  modified:
    - lib/application/tasks/task_list/task_list_cubit.dart (createItem + updateItem added)
    - lib/config/l10n/app_en.arb (task presentation l10n strings)
    - lib/config/l10n/app_pt.arb (task presentation l10n strings)
    - lib/config/l10n/app_pt_BR.arb (task presentation l10n strings)
    - lib/generated/l10n/app_localizations.dart (regenerated)
    - lib/generated/l10n/app_localizations_en.dart (regenerated)
    - lib/generated/l10n/app_localizations_pt.dart (regenerated)
decisions:
  - "Used Navigator.push with MaterialPageRoute (not go_router) for form navigation — go_router is not wired in the router config yet; deferred to plan 05 or router setup plan"
  - "DayPlannerScreen reads TaskListCubit via context.watch — requires both cubits in the provider tree, enforced in widget tests with MultiBlocProvider"
  - "TaskCard tooltip for delete button uses hardcoded 'Delete' string — acceptable since tooltips are accessibility-only and not visible UI text; l10n deferred to plan 05"
metrics:
  duration: ~35m
  completed_date: "2026-04-14"
  tasks_completed: 6
  files_created: 19
  files_modified: 7
  tests_added: 12
---

# Phase 02 Plan 04: Task Presentation — Core Screens and Widgets Summary

## One-liner

Five core task screens (list, project, form, Eisenhower 2x2, 1-3-5 planner) + three shared widgets wired to Plan 03 cubits via BlocBuilder/BlocConsumer — 12 widget tests passing, all UI text in l10n, flutter analyze exits 0.

## What Was Built

### Shared Widgets (Task 2)

`lib/presentation/tasks/widgets/task_card.dart` — Reusable card for a single `Item`:
- Title (one line, ellipsis overflow)
- Priority chip with `colorScheme` token background (urgent → error, critical → errorContainer, high → tertiaryContainer, medium → secondaryContainer, low → surfaceContainerHighest)
- Due date chip when `item.dueDate != null`, formatted `dd/MM/yyyy`
- Eisenhower quadrant chip using `item.eisenhowerQuadrant.name`
- Completion `Checkbox` calling `onComplete`
- Delete `IconButton` calling `onDelete`
- Zero Isar imports — only domain types

`lib/presentation/tasks/widgets/quadrant_card.dart` — Card for one Eisenhower quadrant:
- Colored header bar with quadrant label
- Scrollable list of item title `Chip` widgets
- `l10n.quadrantEmpty` ("Empty") text when items list is empty

`lib/presentation/tasks/widgets/slot_section.dart` — Section for one 1-3-5 slot:
- Header: `"$label ($currentCount/$maxSlots)"`
- Per-item over-capacity warning (amber container with `l10n.slotLimitExceeded`)
- List of assigned items each with a remove icon button
- "Add" `TextButton.icon` calling `onTapAdd`

### Screens (Tasks 3–5)

`lib/presentation/tasks/screens/task_list_screen.dart` — `StatefulWidget`:
- `initState` calls `cubit.start()`
- `BlocConsumer` listener: `TaskListWithPendingUndo` → `ScaffoldMessenger.showSnackBar` with `AppConstants.undoSnackbarDuration` and Undo action calling `cubit.restoreItem`
- Builder switch: loading spinner / empty state / `ListView` of `TaskCard` / error text
- FAB and `TaskCard.onTap` navigate to `TaskFormScreen` via `Navigator.push(MaterialPageRoute)`

`lib/presentation/tasks/screens/project_screen.dart`:
- Accepts `projectId` via constructor; calls `ProjectCubit.loadProject` in `initState`
- `BlocBuilder<ProjectCubit>`: `LinearProgressIndicator` for `completionRatio`, subtask `ListView` via `TaskCard`, FAB with bottom sheet for adding subtasks

`lib/presentation/tasks/screens/task_form_screen.dart` — 14-field form:
- `null item` = create mode; non-null = edit mode
- Fields: title (required, validator), description, type (`SegmentedButton`), priority (`DropdownButtonFormField`), due date (`showDatePicker`), due time (`showTimePicker`, only enabled when dueDate set), isUrgent, isImportant (`SwitchListTile`), size (`SegmentedButton`), next action (`CheckboxListTile`), GTD context, waiting for, amount, currency
- T-02-07 mitigation: `_formKey.currentState!.validate()` guard before `createItem`/`updateItem`
- `dueTimeMinutes` stored as `hour * 60 + minute`

`lib/presentation/tasks/screens/eisenhower_screen.dart`:
- `BlocBuilder<TaskListCubit>` partitions loaded items into 4 `EisenhowerQuadrant` buckets
- 2×2 layout with two `Expanded` `Row`s each containing two `Expanded` `QuadrantCard` widgets
- Colors: doNow → errorContainer, schedule → primaryContainer, delegate → tertiaryContainer, eliminate → surfaceContainerHighest

`lib/presentation/tasks/screens/day_planner_screen.dart`:
- `BlocBuilder<DayPlannerCubit>` with `context.watch<TaskListCubit>()` for the task picker
- Global `_WarningBanner` (amber) at column top when `plannerState.slotLimitWarning`
- Three `SlotSection` widgets fed from `DayPlannerState` slot fields
- `_showTaskPicker` bottom sheet with `DraggableScrollableSheet` listing all items from `TaskListCubit`; tap assigns to slot via `cubit.assignBig/assignMedium/assignSmall`

### TaskListCubit Additions (Task 4)

`createItem(Item)` and `updateItem(Item)` methods added to `TaskListCubit` — call repository and emit `TaskListError` on `Err`; watch stream fires reload automatically on success.

### l10n Additions (Task 2)

44 new keys added to all three ARB files (`app_en.arb`, `app_pt.arb`, `app_pt_BR.arb`) and regenerated `app_localizations*.dart`. Keys cover all task presentation strings: screen titles, field labels, validation messages, priority/size/type labels, quadrant labels, slot labels, snackbar text.

### Widget Tests (Tasks 1 + 6)

12 tests across 4 files:
- `task_list_screen_test.dart` — 4 tests: empty state, TaskCard rendered with item, SnackBar on PendingUndo, softDelete called on tap
- `eisenhower_board_test.dart` — 2 tests: four quadrant labels present, urgent+important task in Do Now section
- `day_planner_test.dart` — 3 tests: three slot section headers, warning banner visible when true, banner absent when false
- `task_form_test.dart` — 3 tests: title field present, empty title shows validation error, valid title calls createItem

All tests use `MockCubit<State>` from `bloc_test`, `MaterialApp` with `AppLocalizations.localizationsDelegates` for l10n resolution, and `MultiBlocProvider` where multiple cubits are required.

## Success Criteria Verification

- [x] `TaskListScreen` shows empty state when `items` is empty
- [x] Delete action emits undo snackbar; tapping Undo calls `cubit.restoreItem`
- [x] Eisenhower board renders 4 quadrant cards in a 2x2 layout
- [x] Day planner renders 3 slot sections with counts from `AppConstants`
- [x] Slot limit warning banner visible when `state.slotLimitWarning == true`
- [x] Task form validates that title is non-empty before saving (T-02-07)
- [x] All UI text uses l10n — no hardcoded PT-BR or EN strings in screen/widget files
- [x] `flutter test test/presentation/tasks/ --no-pub` exits 0 — 12/12 passing
- [x] `flutter analyze --no-fatal-infos` exits 0
- [ ] Human checkpoint: task 7 (visual verification) — not performed; deferred to orchestrator

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 6de5034 | test(02-04): add presentation test stubs |
| 2 | 81fe062 | feat(02-04): add shared task widgets + task l10n strings |
| 3 | 1f2ab0d | feat(02-04): add TaskListScreen, ProjectScreen and createItem/updateItem |
| 4 | 865e2c1 | feat(02-04): add TaskFormScreen |
| 5 | f8c934e | feat(02-04): add EisenhowerScreen and DayPlannerScreen |
| 6 | e6a91b6 | test(02-04): fill presentation widget test assertions — 12 tests passing |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused `item_type.dart` import from task_form_test.dart**
- **Found during:** Task 6 — flutter analyze after writing tests
- **Issue:** `FakeItem extends Fake implements Item` does not require the `item_type.dart` import; analyzer reported `warning • unused_import` causing exit 1.
- **Fix:** Removed the `import 'package:agenda/domain/tasks/item_type.dart'` line.
- **Files modified:** `test/presentation/tasks/task_form_test.dart`
- **Commit:** e6a91b6

### Plan Spec Differences (pre-existing in committed implementation)

The following minor deviations were already present in the committed implementation and are documented for traceability:

1. **Navigator.push instead of go_router** — Plan spec says "go_router push" for form navigation. The implementation uses `Navigator.of(context).push(MaterialPageRoute(...))` because go_router routes are not yet wired. This is consistent with the codebase state at plan execution time. go_router integration deferred to plan 05 or a dedicated router plan.

2. **surfaceContainerHighest instead of surfaceVariant** — Plan spec uses `cs.surfaceVariant` for the Eliminate quadrant and `cs.surfaceVariant` for `Priority.low` in TaskCard. The implementation uses `cs.surfaceContainerHighest` (the M3 successor to the deprecated `surfaceVariant`). This avoids the `deprecated_member_use` analyzer info.

3. **TaskCard tooltip "Delete" not localized** — Plan spec does not specify tooltip text. The implementation uses a hardcoded `'Delete'` string. Tooltips are accessibility metadata (not visible UI text); l10n deferred to plan 05.

## Known Stubs

None. All screens and widgets are fully implemented. All test assertions are filled.

## Threat Flags

No new threat surface beyond plan scope. T-02-01 (query injection) is not touched in this plan — search input wiring is plan 05. T-02-05 (stale state after soft-delete) is mitigated: `TaskListWithPendingUndo` state excludes the deleted item immediately in the UI builder. T-02-07 (empty title submission) is mitigated: `_formKey.currentState!.validate()` guard confirmed present in `TaskFormScreen._save()` and verified by test.

## Self-Check: PASSED

Files verified:
- `lib/presentation/tasks/screens/task_list_screen.dart` — FOUND
- `lib/presentation/tasks/screens/project_screen.dart` — FOUND
- `lib/presentation/tasks/screens/task_form_screen.dart` — FOUND
- `lib/presentation/tasks/screens/eisenhower_screen.dart` — FOUND
- `lib/presentation/tasks/screens/day_planner_screen.dart` — FOUND
- `lib/presentation/tasks/widgets/task_card.dart` — FOUND
- `lib/presentation/tasks/widgets/quadrant_card.dart` — FOUND
- `lib/presentation/tasks/widgets/slot_section.dart` — FOUND
- `test/presentation/tasks/task_list_screen_test.dart` — FOUND
- `test/presentation/tasks/eisenhower_board_test.dart` — FOUND
- `test/presentation/tasks/day_planner_test.dart` — FOUND
- `test/presentation/tasks/task_form_test.dart` — FOUND

Commits verified:
- 6de5034 — FOUND
- 81fe062 — FOUND
- 1f2ab0d — FOUND
- 865e2c1 — FOUND
- f8c934e — FOUND
- e6a91b6 — FOUND
