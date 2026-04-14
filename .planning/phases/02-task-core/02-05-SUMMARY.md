---
phase: 02
plan: 05
subsystem: task-gtd-search-filter-di
tags: [gtd, search, filter, recurring, di-wiring, tasks-module, presentation]
dependency_graph:
  requires: [lib/application/tasks/* (Plan 03), lib/presentation/tasks/screens/* (Plan 04), lib/infrastructure/tasks/* (Plan 02)]
  provides: [GTD filter screen, GTD chip widget, search bar integration, recurrence picker UI, recurring task completion flow, complete DI wiring in tasks_module.dart, injection.config.dart regenerated]
  affects: [Phase 3 (DI graph fully populated for task domain — finance builds on same pattern)]
tech_stack:
  added: []
  patterns: [gtd-chip-filter, search-textfield, rrule-picker, injectable-lazy-singleton, tasks-module-wiring, get-it-test-registration]
key_files:
  created:
    - lib/presentation/tasks/widgets/gtd_chip.dart
    - lib/presentation/tasks/screens/gtd_filter_screen.dart
    - test/presentation/tasks/gtd_test.dart
  modified:
    - lib/config/di/tasks_module.dart
    - lib/config/di/injection.config.dart
    - lib/application/tasks/task_list/task_list_cubit.dart
    - lib/presentation/tasks/screens/task_list_screen.dart
    - lib/presentation/tasks/screens/task_form_screen.dart
    - lib/infrastructure/tasks/item_repository_impl.dart
    - lib/domain/tasks/item_repository.dart
    - lib/config/l10n/app_en.arb
    - lib/config/l10n/app_pt_BR.arb
    - test/application/tasks/task_list_cubit_test.dart
decisions:
  - "TaskListCubit constructor now takes RecurrenceEngine as second param — injectable_generator picks this up automatically and wires it from the DI graph"
  - "completeItem creates next-occurrence Item with id=0 (Isar auto-increment) rather than using copyWith, avoiding nullable field issues with copyWith semantics"
  - "GtdFilterScreen uses GetIt.instance<ItemRepository>() directly so it can be used without being inside a provider tree — tests register a MockItemRepository in GetIt before each test and reset in tearDown"
  - "Recurrence picker uses RadioListTile group inside if (_dueDate != null) spread to avoid showing irrelevant UI when no due date is set"
metrics:
  duration: ~40m
  completed_date: "2026-04-15"
  tasks_completed: 6
  files_created: 3
  files_modified: 10
  tests_added: 6
---

# Phase 02 Plan 05: GTD + Search + Filter + Recurring Task UI + DI Wiring Summary

## One-liner

Complete DI graph for task domain (ItemDao, ItemMapper, ItemRepositoryImpl, RecurrenceEngineImpl, TaskListCubit with RecurrenceEngine) + search bar + GTD filter screen + recurrence picker + recurring completion flow — 109 tests passing, flutter analyze exits 0.

## What Was Built

### DI Wiring — TasksModule (committed in prior agent, e9da2c5 / 695a65f)

`lib/config/di/tasks_module.dart` — `@module` abstract class:
- `itemDao(IsarService)` → `@lazySingleton ItemDao`
- `itemMapper` → `@lazySingleton ItemMapper`

`lib/config/di/injection.config.dart` — regenerated after TaskListCubit constructor update:
- `ItemDao`, `ItemMapper` (from TasksModule)
- `RecurrenceEngineImpl` as `RecurrenceEngine` (from `@LazySingleton` annotation)
- `ItemRepositoryImpl` as `ItemRepository` (from `@LazySingleton` annotation)
- `TaskListCubit` factory — now wired with `(ItemRepository, RecurrenceEngine)`
- `ProjectCubit` and `DayPlannerCubit` factories

### GTD Chip Widget (committed in prior agent, d452cd5)

`lib/presentation/tasks/widgets/gtd_chip.dart`:
- `FilterChip` with `selectedColor: colorScheme.secondaryContainer`
- `checkmarkColor: colorScheme.onSecondaryContainer`
- Props: `label`, `isSelected`, `onSelected`

### GTD Filter Screen (committed in prior agent, d452cd5)

`lib/presentation/tasks/screens/gtd_filter_screen.dart`:
- `StatefulWidget` — fetches distinct contexts via `GetIt.instance<ItemRepository>().getDistinctGtdContexts()` in `initState`
- `Wrap` of `GtdChip` widgets, one per distinct context
- "Apply" (`FilledButton`) → `cubit.applyFilter(TaskListFilter(gtdContext: _selectedContext))` + pop
- "Clear" (`OutlinedButton`) → `cubit.applyFilter(TaskListFilter.empty)` + pop
- Loading spinner during async fetch; empty state text when no contexts exist

### getDistinctGtdContexts (committed in prior agent, d452cd5)

Added to `ItemRepository` interface and implemented in `ItemRepositoryImpl`:
- Calls `filterItems()`, extracts non-null `gtdContext` values, deduplicates, sorts alphabetically
- Returns `AsyncResult<List<String>>`

### l10n Keys (committed in prior agent, d452cd5)

All required ARB keys added to `app_en.arb` and `app_pt_BR.arb`:
- `searchTasks`, `recurrence`, `noRecurrence`, `daily`, `weekly`, `monthly`, `yearly`
- `gtdFilterTitle`, `noGtdContexts`, `applyFilter`, `clearFilter`
- `bigTask`, `mediumTasks`, `smallTasks`, `eisenhowerDoNow/Schedule/Delegate/Eliminate`, `titleRequired`

### Search Bar + GTD Filter Icon (this agent, ffd86b2)

`lib/presentation/tasks/screens/task_list_screen.dart`:
- `SearchBar` in `AppBar.bottom` (`PreferredSize(56px)`) with `hintText: l10n.searchTasks`
- `onChanged` calls `context.read<TaskListCubit>().search(query)` directly (no debounce needed)
- `IconButton(Icons.filter_list)` in `AppBar.actions` navigates to `GtdFilterScreen` via `Navigator.push(MaterialPageRoute)`

### Recurrence Picker + Recurring Completion Flow (this agent, 69ad03e)

`lib/presentation/tasks/screens/task_form_screen.dart`:
- New `String? _recurrenceRule` state field initialized from `item?.recurrenceRule`
- Recurrence section shown only when `_dueDate != null` (spread inside `if (_dueDate != null) ...`)
- 5 `RadioListTile<String?>`: null / `FREQ=DAILY` / `FREQ=WEEKLY` / `FREQ=MONTHLY;BYMONTHDAY=N` / `FREQ=YEARLY`
- `_recurrenceRule` persisted in both create and edit paths via `Item(recurrenceRule: ...)` / `copyWith(recurrenceRule: ...)`

`lib/application/tasks/task_list/task_list_cubit.dart`:
- `RecurrenceEngine _recurrenceEngine` added as second constructor parameter (`@injectable` annotation unchanged — injectable_generator resolves via type)
- `completeItem()` extended: after marking item complete, if `recurrenceRule != null && dueDate != null`, parses the rule with `_recurrenceEngine.parse()`, computes `nextDate` with `_recurrenceEngine.nextOccurrence()`, creates a fresh `Item(id: 0, ...)` with `nextDate` as `dueDate`, calls `_repository.createItem()`
- `watchChanges()` stream fires on both writes, triggering `_reload()` automatically

### GTD Tests (this agent, df1c096)

`test/presentation/tasks/gtd_test.dart` — 6 tests:
- `GtdChip`: renders label text, `selected` prop true when `isSelected`, `onSelected(true)` called on tap
- `GtdFilterScreen`: chips rendered for each context returned by `getDistinctGtdContexts()`, tap + Apply calls `cubit.applyFilter(TaskListFilter(gtdContext: ...))`, empty state text when list is empty
- Uses `GetIt.instance.registerSingleton<ItemRepository>(mock)` in `setUp` + `GetIt.instance.reset()` in `tearDown`

## Success Criteria Verification

- [x] `injection.config.dart` contains registrations for `ItemRepository`, `RecurrenceEngine`, `TaskListCubit`, `ProjectCubit`, `DayPlannerCubit`, `ItemDao`, `ItemMapper`
- [x] `TaskListScreen` has a functional search bar that calls `cubit.search()`
- [x] `TaskListScreen` has a GTD filter icon button that navigates to `GtdFilterScreen`
- [x] `TaskFormScreen` has radio buttons for DAILY/WEEKLY/MONTHLY/YEARLY recurrence (shown when dueDate is set)
- [x] `completeItem` in `TaskListCubit` creates a new Item with `nextOccurrence` dueDate for recurring tasks
- [x] ARB files have all new keys and `flutter gen-l10n` exits 0
- [x] `flutter test test/domain/tasks/ test/data/tasks/ test/infrastructure/tasks/ test/application/tasks/ test/presentation/tasks/ --no-pub` exits 0 — 109/109 passing
- [x] `flutter analyze --no-fatal-infos` exits 0 (81 info-level issues, 0 errors, 0 warnings)
- [x] `grep -r "findSync|putSync|deleteSync" lib/` — zero actual occurrences (one comment-only match)
- [x] `grep -r "package:isar" lib/domain/ lib/application/` — no output

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Test stub | e9da2c5 | test(02-05): add GTD presentation test stub |
| DI wiring | 695a65f | feat(02-05): wire tasks_module DI and regenerate injection.config.dart |
| GTD UI + l10n | d452cd5 | feat(02-05): add GtdChip widget, GtdFilterScreen, getDistinctGtdContexts, and GTD l10n keys |
| Search + filter icon | ffd86b2 | feat(02-05): add search bar and GTD filter icon button to TaskListScreen |
| Recurrence picker + cubit | 69ad03e | feat(02-05): add recurrence picker to TaskFormScreen and recurring flow to TaskListCubit |
| GTD tests | df1c096 | test(02-05): fill GTD test assertions — 6 tests passing |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] TaskListCubit constructor required RecurrenceEngine — test needed MockRecurrenceEngine**
- **Found during:** Task 4 — running flutter analyze after updating TaskListCubit
- **Issue:** `task_list_cubit_test.dart` constructed `TaskListCubit(repository)` with 1 arg; updated constructor requires 2.
- **Fix:** Added `MockRecurrenceEngine extends Mock implements RecurrenceEngine` and updated all `TaskListCubit(repository)` calls to `TaskListCubit(repository, recurrenceEngine)`.
- **Files modified:** `test/application/tasks/task_list_cubit_test.dart`
- **Commit:** 69ad03e

**2. [Rule 1 - Bug] Missing `registerFallbackValue(TaskListFilter.empty)` in gtd_test.dart**
- **Found during:** Task 5 — flutter test run
- **Issue:** `whenListen(cubit, ..., initialState: ...)` and `when(() => cubit.applyFilter(any()))` use `any()` on `TaskListFilter` type; mocktail requires a registered fallback value.
- **Fix:** Added `setUpAll(() { registerFallbackValue(TaskListFilter.empty); });` before the test groups.
- **Files modified:** `test/presentation/tasks/gtd_test.dart`
- **Commit:** df1c096

**3. [Rule 1 - Bug] Used explicit Item() constructor instead of copyWith for recurring next-occurrence**
- **Found during:** Task 4 — implementation
- **Issue:** `Item.copyWith` uses `param ?? this.value` semantics, so nullable fields (deletedAt, completedAt) cannot be explicitly set to null via copyWith. A new recurring occurrence must start with `deletedAt: null` and `completedAt: null`. Using `copyWith(deletedAt: null)` would silently retain the old value.
- **Fix:** Used explicit `Item(id: 0, ...)` constructor with all required fields set, omitting nullable fields to default to null.
- **Files modified:** `lib/application/tasks/task_list/task_list_cubit.dart`
- **Commit:** 69ad03e

## Known Stubs

None. All widgets and cubits are fully implemented. All test assertions are filled.

## Threat Flags

No new threat surface beyond plan scope. T-02-01 (search query injection) is mitigated: `SearchBar.onChanged` calls `cubit.search(query)` which delegates to `ItemRepository.searchByTitle()` — uses typed Isar `.titleContains()` API, never string interpolation. T-02-02 (unbounded result sets) is mitigated: `getDistinctGtdContexts()` calls `filterItems()` which applies `.limit(500)` in `ItemDao`.

## Self-Check: PASSED

Files verified:
- `lib/presentation/tasks/widgets/gtd_chip.dart` — FOUND
- `lib/presentation/tasks/screens/gtd_filter_screen.dart` — FOUND
- `lib/presentation/tasks/screens/task_list_screen.dart` — FOUND (search bar + filter icon)
- `lib/presentation/tasks/screens/task_form_screen.dart` — FOUND (recurrence picker)
- `lib/application/tasks/task_list/task_list_cubit.dart` — FOUND (RecurrenceEngine dep + completeItem flow)
- `lib/config/di/injection.config.dart` — FOUND (all 7+ registrations)
- `test/presentation/tasks/gtd_test.dart` — FOUND (6 real tests)

Commits verified:
- e9da2c5 — FOUND
- 695a65f — FOUND
- d452cd5 — FOUND
- ffd86b2 — FOUND
- 69ad03e — FOUND
- df1c096 — FOUND
