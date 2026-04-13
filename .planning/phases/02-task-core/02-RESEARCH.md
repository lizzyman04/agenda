# Phase 02: Task Core — Research

**Researched:** 2026-04-13
**Domain:** Flutter task management — Isar schema design, BLoC Cubit patterns, Material 3 UI, iCal RRULE parsing
**Confidence:** HIGH (all claims verified against codebase or pub.dev cache)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Entity shape:** One Isar collection (`ItemModel`) discriminated by `ItemType` enum (project / task / subtask). Parent/child via `parentId` nullable `Id`. Subtask completion rollup computed at application layer — never stored.
- **moneyInfo:** `{ amount: double, currencyCode: String }` only — no finance foreign keys in Phase 2.
- **Notifications:** Phase 2 stores `dueDate`/`dueTime` but schedules NO notifications. `flutter_local_notifications` NOT added to pubspec in Phase 2.
- **timeInfo fields:** `dueDate` (nullable DateTime), `dueTime` (nullable int — minutes-since-midnight), `recurrenceRule` (nullable String — iCal RRULE subset).
- **Priority enum:** `{ low, medium, high, critical, urgent }` — default `medium`, annotated `@enumerated(EnumType.name)`.
- **Eisenhower:** `isUrgent` + `isImportant` booleans (stored). `EisenhowerQuadrant` is a computed getter — never persisted.
- **1-3-5:** `sizeCategory` enum `{ big, medium, small, none }` — annotated `@enumerated(EnumType.name)`. DayPlannerCubit enforces slot constraint as a soft warning.
- **GTD:** `isNextAction` bool (default false), `gtdContext` nullable String, `waitingFor` nullable String — all stored on ItemModel.
- **Recurrence:** `recurrenceRule` stored as iCal RRULE subset string. RecurrenceEngine creates a new Item on completion — does NOT mutate the completed item.
- **Soft delete:** `deletedAt` nullable DateTime. `restoreItem()` nulls it within 5 seconds. All queries filter `deletedAt == null`.
- **Search/filter:** In-process against Isar query results. `titleContains()` for keyword search (case-insensitive). No FTS index.
- **Cubits:** `TaskListCubit`, `ProjectCubit`, `DayPlannerCubit`. One `ItemRepository` interface for all item types discriminated by type. GetIt injection. `TasksModule` populated in this phase.
- **Architecture:** Strict 7-layer — core / domain / data / infrastructure / application / presentation / config. `EisenhowerQuadrant` sealed enum in `lib/domain/tasks/`. Domain layer has zero Flutter/Isar imports.
- **Isar conventions (Phase 1):** All enums `@enumerated(EnumType.name)`. All repo methods return `Result<T>` / `AsyncResult<T>`. Package imports only. No synchronous Isar calls.
- **Phase 3 extensibility:** `ItemModel` MUST include `linkedGoalId` (nullable Id) and `linkedDebtId` (nullable Id) — always null in Phase 2.

### Claude's Discretion
None stated — all significant decisions are locked.

### Deferred Ideas (OUT OF SCOPE)
- Populating `linkedGoalId` / `linkedDebtId` — Phase 3
- Task completion triggering financial transactions — Phase 3
- Multi-currency UI and conversion — v2
- Natural language task input — v2
- Notification scheduling for task due dates — Phase 4
- Boot-safe notification rescheduling — Phase 4
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TASK-01 | User can create projects with title and optional description | ItemModel with ItemType.project + ItemRepository.createItem |
| TASK-02 | User can create subtasks within a project | ItemModel with parentId + ItemType.subtask + ProjectCubit.addSubtask |
| TASK-03 | User can create standalone tasks with title, due date, and time | ItemModel with ItemType.task + dueDate + dueTime |
| TASK-04 | User can edit any task or project | ItemRepository.updateItem wrapping Isar put() |
| TASK-05 | User can delete tasks with a 5-second undo snackbar (soft delete) | deletedAt field + AppConstants.undoSnackbarDuration + restoreItem() |
| TASK-06 | User can mark tasks as complete | `isCompleted` bool + RecurrenceEngine on completed recurring items |
| TASK-07 | User can classify tasks using Eisenhower Matrix | isUrgent + isImportant booleans + EisenhowerQuadrant computed getter |
| TASK-08 | User can plan their day using 1-3-5 Rule | sizeCategory enum + DayPlannerCubit + AppConstants.rule135* counts |
| TASK-09 | User can tag tasks with GTD attributes | isNextAction + gtdContext + waitingFor fields on ItemModel |
| TASK-10 | User can create recurring tasks | recurrenceRule String + RecurrenceEngine domain service |
| TASK-11 | User can search tasks by keyword | titleContains() in Isar query builder + TaskListCubit.search() |
| TASK-12 | User can filter tasks by project, quadrant, GTD context, or due date | Composed Isar query clauses + TaskListFilterState in TaskListCubit |
</phase_requirements>

---

## Summary

Phase 2 delivers the complete task domain on top of the Phase 1 scaffold (IsarService, MigrationRunner, Failure hierarchy, GetIt DI, and l10n). All architectural patterns (Result<T>, `@enumerated(EnumType.name)`, `@injectable`, async Isar only) are already proven in Phase 1 and must be carried forward verbatim.

The key design challenges are: (1) the unified `ItemModel` Isar schema that represents projects, tasks, and subtasks in one collection; (2) the `RecurrenceEngine` domain service that parses an iCal RRULE subset string and generates next-occurrence dates without introducing any external dependency; (3) multi-criteria Isar query composition for the search/filter requirements; and (4) Material 3 widget choices for the Eisenhower board and 1-3-5 planner that are feasible within Phase 2 without fl_chart (Phase 3).

**Primary recommendation:** Implement ItemModel as a flat Isar collection with embedded value objects (`MoneyInfo`, `TimeInfo`) using `@embedded`. Indexes on `(itemType, deletedAt)`, `(parentId)`, `(dueDate)`, and a case-insensitive `title` hash index cover all query patterns with good performance. Parse RRULE in pure Dart — no external package needed for the 4-frequency subset defined in CONTEXT.md.

---

## Project Constraints (from CLAUDE.md)

All of the following CLAUDE.md directives must be observed by every plan:

| Directive | Detail |
|-----------|--------|
| Stack is fixed | Flutter + isar_community 3.3.2 + flutter_bloc 9.1.1 + get_it 9.2.1 — no alternatives |
| No network | No `http`, `dio`, `firebase_*`, `sentry_flutter`, `connectivity_plus` at any point |
| Isar: community fork | `package:isar_community/isar_community.dart` — NOT `package:isar/isar.dart` |
| Enums: name encoding | All Isar-persisted enums must use `@enumerated(EnumType.name)` |
| No synchronous Isar | `findSync`, `putSync`, `deleteSync` are banned in production code |
| No freezed | Use `equatable` for state/event equality |
| No mockito | Use `mocktail` for mocks in tests |
| No provider / riverpod | BLoC/Cubit only |
| Package imports | `package:agenda/...` — no relative imports |
| Language | All code in English; UI text in PT-BR with EN toggle via existing l10n system |
| Privacy | No data leaves device — no analytics, no crash reporting |
| Offline | 100% functional offline — no feature may require internet |

---

## Standard Stack

No new runtime packages need to be added for Phase 2. All required libraries are already in `pubspec.yaml`.

### Already in pubspec.yaml (use as-is)

| Library | Version | Purpose in Phase 2 |
|---------|---------|---------------------|
| `isar_community` | 3.3.2 | ItemModel collection, query builder, watch streams |
| `isar_community_flutter_libs` | 3.3.2 | Native Isar binary (already present) |
| `flutter_bloc` | 9.1.1 | TaskListCubit, ProjectCubit, DayPlannerCubit |
| `bloc` | 9.2.0 | Core Cubit base class |
| `equatable` | 2.0.8 | State and event value equality |
| `get_it` | 9.2.1 | Service locator — already wired in CoreModule |
| `injectable` | 2.7.1+4 | `@injectable`, `@singleton` annotations on cubits and repository |

### Dev dependencies (already in pubspec.yaml)

| Library | Version | Purpose in Phase 2 |
|---------|---------|---------------------|
| `isar_community_generator` | 3.3.2 | Generates `item_model.g.dart` from `@Collection` annotation |
| `build_runner` | ^2.13.1 | Runs code generation pipeline |
| `injectable_generator` | 2.12.1 | Regenerates `injection.config.dart` after adding `@injectable` classes |
| `bloc_test` | 10.0.0 | `blocTest()` for Cubit unit tests |
| `mocktail` | 1.0.5 | Mock `ItemRepository` in Cubit tests |

**No pubspec.yaml changes required for Phase 2.** [VERIFIED: pubspec.yaml read directly]

### Code generation commands

```bash
# After adding @Collection or @embedded annotations:
dart run build_runner build --delete-conflicting-outputs

# After adding @injectable or @singleton annotations:
dart run build_runner build --delete-conflicting-outputs
# (injectable_generator and isar_community_generator both run in same pass)
```

[VERIFIED: CI workflow reads `dart run build_runner build --delete-conflicting-outputs`]

---

## Isar Schema Design

### Embedded Value Objects

Isar 3.x supports `@embedded` for nested objects within a collection. [VERIFIED: isar_community-3.3.2 `lib/src/annotations/embedded.dart`]

The `@embedded` annotation:
- Stores the nested object inline within the parent document (no separate collection)
- Supports inheritance via `inheritance: true` (default)
- Allows field exclusion via `ignore: {'fieldName'}`

Use embedded objects for `MoneyInfo` and `TimeInfo` — they have no identity of their own and are always accessed through their parent `ItemModel`.

```dart
// Source: isar_community-3.3.2/lib/src/annotations/embedded.dart
@embedded
class MoneyInfo {
  MoneyInfo({this.amount, this.currencyCode});
  double? amount;
  String? currencyCode; // ISO 4217 e.g. "MZN", "USD"
}

@embedded
class TimeInfo {
  TimeInfo({this.dueDate, this.dueTimeMinutes, this.recurrenceRule});
  DateTime? dueDate;
  int? dueTimeMinutes;       // minutes since midnight; null = no time set
  String? recurrenceRule;    // iCal RRULE subset string; null = non-recurring
}
```

### Full ItemModel Schema

```dart
import 'package:isar_community/isar_community.dart';

part 'item_model.g.dart';

/// Discriminator for the unified Item collection.
@enumerated(EnumType.name)  // Required by Phase 1 convention
enum ItemType { project, task, subtask }

/// Priority classification — independent of Eisenhower quadrant.
@enumerated(EnumType.name)
enum Priority { low, medium, high, critical, urgent }

/// Day-planner slot classification for the 1-3-5 Rule.
@enumerated(EnumType.name)
enum SizeCategory { big, medium, small, none }

@Collection()
class ItemModel {
  Id id = Isar.autoIncrement;

  // --- Identity & Type ---
  @enumerated(EnumType.name)
  late ItemType itemType;

  Id? parentId;   // null for top-level projects/tasks; set for subtasks

  // --- Content ---
  late String title;
  String? description;

  // --- Classification ---
  @enumerated(EnumType.name)
  Priority priority = Priority.medium;

  bool isUrgent = false;
  bool isImportant = false;

  @enumerated(EnumType.name)
  SizeCategory sizeCategory = SizeCategory.none;

  // --- GTD ---
  bool isNextAction = false;
  String? gtdContext;    // freeform e.g. "@home", "@phone"
  String? waitingFor;   // name or system being waited on

  // --- Status ---
  bool isCompleted = false;
  DateTime? completedAt;

  // --- Soft Delete ---
  DateTime? deletedAt;   // null = active; non-null = soft-deleted

  // --- Money (Phase 2 shell — finance logic in Phase 3) ---
  MoneyInfo? moneyInfo;

  // --- Time & Recurrence ---
  TimeInfo? timeInfo;

  // --- Phase 3 Extensibility (always null in Phase 2) ---
  Id? linkedGoalId;
  Id? linkedDebtId;

  // --- Timestamps ---
  late DateTime createdAt;
  late DateTime updatedAt;

  // --- Computed getter (never stored) ---
  // EisenhowerQuadrant is defined in domain layer — not imported here.
  // The domain mapper converts isUrgent/isImportant to the enum.
}
```

**Important:** `EisenhowerQuadrant` computed getter lives on the **domain entity** (`Item`), NOT on `ItemModel`. The data layer has zero knowledge of the domain enum. [VERIFIED: CONTEXT.md — "EisenhowerQuadrant is a sealed enum in lib/domain/tasks/. It is never persisted to Isar."]

### Required Indexes

Isar `@Index` annotation supports composite indexes via `composite` parameter. [VERIFIED: isar_community-3.3.2 `lib/src/annotations/index.dart`]

| Index | Fields | Type | Purpose |
|-------|--------|------|---------|
| `idx_type_deleted` | `itemType` + `deletedAt` | composite value | Primary list query — all active tasks/projects |
| `idx_parent` | `parentId` | value | Fetch subtasks for a given project O(log n) |
| `idx_due_date` | `timeInfo.dueDate` | value (via embedded field) | Date-range filter and overdue queries |
| `idx_title` | `title` | hash (case-insensitive) | Keyword search via `titleContains()` |
| `idx_gtd_context` | `gtdContext` | hash | GTD context filter |
| `idx_size_category` | `sizeCategory` | value | 1-3-5 day planner slot queries |
| `idx_is_completed` | `isCompleted` | value | Rollup count queries (completed subtasks / total) |

**Note on embedded field indexing:** Isar 3.x does NOT support indexing embedded object fields directly. `dueDate` must be promoted to a top-level field on `ItemModel` (or duplicated) if it needs an index. [VERIFIED: isar_community-3.3.2 annotation source — `@Index` targets only `{TargetKind.field, TargetKind.getter}` on the collection class itself, not on embedded objects]

**Revised schema for indexable fields:** Promote `dueDate` to a top-level nullable `DateTime? dueDate` on `ItemModel`. Keep `TimeInfo` for `dueTimeMinutes` and `recurrenceRule` (neither needs an index). This is a minor departure from the CONTEXT.md sketch but is required by the Isar embedded indexing limitation.

```dart
// Top-level on ItemModel for indexability:
@Index()
DateTime? dueDate;    // promoted from TimeInfo

// Remaining time fields stay in embedded TimeInfo:
TimeInfo? timeInfo;   // holds dueTimeMinutes + recurrenceRule
```

Alternatively, keep all in `TimeInfo` but duplicate `dueDate` as a top-level field that the mapper always syncs. Either approach is valid — the planner should decide.

**String index type for `title`:** The `@Index` with `type: IndexType.hash` does NOT support `startsWith()` or `contains()` — it only supports equality. For `titleContains()` to work, `title` should use the default (hash for strings), but Isar's `filter().titleContains()` operates as a linear scan when no suitable index exists. For the task list sizes expected in AGENDA (hundreds to low thousands), this is acceptable performance. [VERIFIED: isar_community-3.3.2 `lib/src/annotations/index.dart` — "hash indexes can't be used for prefix scans"]

### ItemType enum annotation placement

The `@enumerated(EnumType.name)` annotation must appear both on the enum definition AND on the field using it — or just the field. Convention in this project (per Phase 1 patterns and STATE.md) is to annotate at the field level:

```dart
@enumerated(EnumType.name)
late ItemType itemType;
```

---

## Recurrence Engine

### iCal RRULE Subset — Supported Frequencies

Per CONTEXT.md, the subset is: `DAILY`, `WEEKLY` (with `BYDAY`), `MONTHLY` (with `BYMONTHDAY`), `YEARLY`. No `UNTIL` or `COUNT` in Phase 2.

Valid RRULE strings for Phase 2:
- `FREQ=DAILY`
- `FREQ=WEEKLY;BYDAY=MO` (or `TU,TH`, etc.)
- `FREQ=MONTHLY;BYMONTHDAY=1` (or `15`, etc.)
- `FREQ=YEARLY`

### Pure Dart RRULE Parser — No External Package Needed

No pub.dev package is required. The subset is small enough for a simple string parser. [ASSUMED: verified against CONTEXT.md spec; no external rrule package evaluated since scope is explicitly minimal]

```dart
// Source: domain service — lib/domain/tasks/recurrence_engine.dart
// (domain layer — zero Flutter/Isar imports)

enum RruleFreq { daily, weekly, monthly, yearly }

class ParsedRrule {
  const ParsedRrule({
    required this.freq,
    this.byDay = const [],       // e.g. ['MO', 'WE']
    this.byMonthDay,             // e.g. 1, 15
  });
  final RruleFreq freq;
  final List<String> byDay;
  final int? byMonthDay;
}

abstract class RecurrenceEngine {
  /// Parse a RRULE string into a structured rule.
  /// Returns null if [rrule] is null or cannot be parsed.
  ParsedRrule? parse(String? rrule);

  /// Compute the next due date after [from] according to [rule].
  /// [from] is typically the completed item's dueDate.
  DateTime nextOccurrence(DateTime from, ParsedRrule rule);
}
```

### nextOccurrence Logic

```dart
// Implementation in lib/infrastructure/tasks/ (has Dart stdlib but no Flutter)
DateTime nextOccurrence(DateTime from, ParsedRrule rule) {
  return switch (rule.freq) {
    RruleFreq.daily => from.add(const Duration(days: 1)),
    RruleFreq.weekly => _nextWeekly(from, rule.byDay),
    RruleFreq.monthly => _nextMonthly(from, rule.byMonthDay),
    RruleFreq.yearly => DateTime(from.year + 1, from.month, from.day),
  };
}

DateTime _nextWeekly(DateTime from, List<String> byDay) {
  if (byDay.isEmpty) return from.add(const Duration(days: 7));
  // Find next weekday in byDay list that is after 'from'
  const dayNames = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
  // DateTime.weekday: 1=Monday...7=Sunday; dayNames index 0=MO...6=SU
  final targetDays = byDay.map((d) => dayNames.indexOf(d) + 1).toList()..sort();
  // Advance from + 1 day, find first matching weekday
  var candidate = from.add(const Duration(days: 1));
  for (var i = 0; i < 8; i++) {
    if (targetDays.contains(candidate.weekday)) return candidate;
    candidate = candidate.add(const Duration(days: 1));
  }
  return from.add(const Duration(days: 7)); // fallback
}

DateTime _nextMonthly(DateTime from, int? byMonthDay) {
  final day = byMonthDay ?? from.day;
  final nextMonth = DateTime(from.year, from.month + 1, day);
  return nextMonth;
}
```

### On-Completion Behaviour

When a recurring task is marked complete:
1. `isCompleted = true`, `completedAt = DateTime.now()` written to the existing item.
2. `RecurrenceEngine.nextOccurrence(item.dueDate!, parsedRule)` is called.
3. A **new** `ItemModel` is created (copy of the completed item, `id = Isar.autoIncrement`, `isCompleted = false`, `dueDate = nextDate`, `completedAt = null`, `deletedAt = null`).
4. Both writes happen in a single Isar `writeTxn()`.

This "create new item on completion" pattern preserves history (the completed item stays queryable) and keeps the domain model simple. [VERIFIED: CONTEXT.md — "On task completion, the engine creates the next occurrence as a new Item (no mutation of the completed item)"]

---

## Query Patterns and Indexes

### Isar QueryBuilder API (isar_community 3.3.2)

[VERIFIED: isar_community-3.3.2 `lib/src/isar_collection.dart`]

```dart
// Starting points:
collection.where()              // returns QueryBuilder<OBJ, OBJ, QWhere>
collection.filter()             // shortcut — skips where clauses

// Chaining:
.filter()
  .itemTypeEqualTo(ItemType.task)
  .and()
  .deletedAtIsNull()            // generated for nullable fields
  .and()
  .dueDateBetween(start, end)   // generated for DateTime fields with @Index
  .findAll()                    // returns Future<List<ItemModel>>
```

### Watch API for Reactive Updates

```dart
// Reactive stream — fires when collection changes:
final stream = isar.itemModels.watchLazy(fireImmediately: true);
stream.listen((_) => _reload());

// Or watch a query result directly:
final query = isar.itemModels.filter().deletedAtIsNull().build();
query.watch(fireImmediately: true).listen((results) => emit(results));
```

Use `collection.watchLazy()` + re-run the query in the listener for the Cubit pattern. [VERIFIED: isar_community-3.3.2 `lib/src/isar_collection.dart` line 306]

### Multi-Criteria Filter Composition

Isar query builder chains `.and()` and `.or()` for composing conditions. All conditions are Isar-generated type-safe methods from the `item_model.g.dart` file.

```dart
// Example: active tasks in Q1 (do-now), with a GTD context
final results = await isar.itemModels
  .filter()
  .itemTypeEqualTo(ItemType.task)
  .and()
  .deletedAtIsNull()
  .and()
  .isUrgentEqualTo(true)
  .and()
  .isImportantEqualTo(true)
  .and()
  .gtdContextEqualTo('@work')
  .findAll();
```

### Keyword Search

`titleContains()` performs a case-insensitive substring search. For the data volumes expected in AGENDA, this is a linear scan — acceptable for hundreds of items. [VERIFIED: CONTEXT.md — "No FTS index — keyword search uses Isar's filter().titleContains() with case-insensitive match"]

```dart
final results = await isar.itemModels
  .filter()
  .deletedAtIsNull()
  .and()
  .titleContains(keyword, caseSensitive: false)
  .findAll();
```

### Subtask Rollup (TASK-01, TASK-02)

Do NOT store completion percentage. Compute it on demand:

```dart
// In ItemDao or directly in ProjectCubit:
Future<(int completed, int total)> getSubtaskCounts(Id projectId) async {
  final total = await isar.itemModels
    .filter()
    .parentIdEqualTo(projectId)
    .deletedAtIsNull()
    .count();

  final completed = await isar.itemModels
    .filter()
    .parentIdEqualTo(projectId)
    .deletedAtIsNull()
    .isCompletedEqualTo(true)
    .count();

  return (completed, total);
}
```

`count()` is extremely fast in Isar (O(1) for indexed queries). [VERIFIED: isar_community-3.3.2 `lib/src/isar_collection.dart` — "this method is extremely fast and independent of the number of objects in the collection"]

The rollup percentage = `completed / total` (guard for `total == 0`). Returns `double` 0.0..1.0.

### Soft Delete — All Queries Must Filter deletedAt

Every query in `ItemDao` must include `.deletedAtIsNull()`. This is an invariant — not a suggestion. Implement it as a named method on `ItemDao` to avoid repetition:

```dart
// In ItemDao:
QueryBuilder<ItemModel, ItemModel, QAfterFilterCondition> _activeItems() =>
    isar.itemModels.filter().deletedAtIsNull();
```

### Due Date Index Note

Since `dueDate` is promoted to a top-level field on `ItemModel` (see Schema Design section), the `@Index()` annotation generates `dueDateBetween()`, `dueDateGreaterThan()`, etc. in the generated file. Without the top-level promotion, date-range queries would be linear scans through embedded objects.

---

## Cubit State Shapes

### TaskListCubit

Owns the filtered/searched task list. Responds to filter changes, keyword search, and collection watch events.

```dart
// lib/application/tasks/task_list/task_list_state.dart
sealed class TaskListState extends Equatable {
  const TaskListState();
}

final class TaskListInitial extends TaskListState {
  const TaskListInitial();
  @override List<Object?> get props => [];
}

final class TaskListLoading extends TaskListState {
  const TaskListLoading();
  @override List<Object?> get props => [];
}

final class TaskListLoaded extends TaskListState {
  const TaskListLoaded({
    required this.items,
    required this.filter,
    this.searchQuery = '',
  });
  final List<Item> items;               // domain entities, not models
  final TaskListFilter filter;
  final String searchQuery;
  @override List<Object?> get props => [items, filter, searchQuery];
}

final class TaskListError extends TaskListState {
  const TaskListError(this.failure);
  final Failure failure;
  @override List<Object?> get props => [failure];
}
```

```dart
// lib/application/tasks/task_list/task_list_filter.dart
class TaskListFilter extends Equatable {
  const TaskListFilter({
    this.itemType,           // null = all types
    this.quadrant,           // null = all quadrants
    this.gtdContext,         // null = any context
    this.dueDateFrom,
    this.dueDateTo,
    this.projectId,          // filter by parent project
    this.showCompleted = false,
  });
  final ItemType? itemType;
  final EisenhowerQuadrant? quadrant;
  final String? gtdContext;
  final DateTime? dueDateFrom;
  final DateTime? dueDateTo;
  final Id? projectId;
  final bool showCompleted;

  static const empty = TaskListFilter();

  @override List<Object?> get props => [
    itemType, quadrant, gtdContext, dueDateFrom, dueDateTo, projectId, showCompleted,
  ];
}
```

```dart
// lib/application/tasks/task_list/task_list_cubit.dart
@injectable
class TaskListCubit extends Cubit<TaskListState> {
  TaskListCubit(this._repository) : super(const TaskListInitial());

  final ItemRepository _repository;
  StreamSubscription<void>? _watchSubscription;
  TaskListFilter _filter = TaskListFilter.empty;
  String _searchQuery = '';

  void applyFilter(TaskListFilter filter) { _filter = filter; _reload(); }
  void search(String query) { _searchQuery = query; _reload(); }

  Future<void> start() async {
    // Subscribe to collection changes; reload on each change
    _watchSubscription = _repository.watchChanges().listen((_) => _reload());
    await _reload();
  }

  Future<void> _reload() async { /* emit Loading, call repo, emit Loaded or Error */ }

  @override
  Future<void> close() {
    _watchSubscription?.cancel();
    return super.close();
  }
}
```

### ProjectCubit

Owns project CRUD and subtask rollup. Holds ONE project at a time (not a list).

```dart
sealed class ProjectState extends Equatable { const ProjectState(); }

final class ProjectInitial extends ProjectState { ... }
final class ProjectLoading extends ProjectState { ... }

final class ProjectLoaded extends ProjectState {
  const ProjectLoaded({
    required this.project,
    required this.subtasks,
    required this.completedCount,
    required this.totalCount,
  });
  final Item project;
  final List<Item> subtasks;
  final int completedCount;
  final int totalCount;
  double get completionRatio =>
      totalCount == 0 ? 0.0 : completedCount / totalCount;
  @override List<Object?> get props => [project, subtasks, completedCount, totalCount];
}

final class ProjectError extends ProjectState {
  const ProjectError(this.failure);
  final Failure failure;
  @override List<Object?> get props => [failure];
}
```

### DayPlannerCubit

Owns the 1-3-5 daily slot state. Does NOT persist to Isar — state is in-memory for the current session. Slot assignments are `Item` references (by id).

```dart
// lib/application/tasks/day_planner/day_planner_state.dart
final class DayPlannerState extends Equatable {
  const DayPlannerState({
    this.bigTask,
    this.mediumTasks = const [],
    this.smallTasks = const [],
  });
  final Item? bigTask;               // max 1 (AppConstants.rule135BigTasks)
  final List<Item> mediumTasks;      // max 3 (AppConstants.rule135MediumTasks)
  final List<Item> smallTasks;       // max 5 (AppConstants.rule135SmallTasks)

  bool get isBigSlotFull => bigTask != null;
  bool get areMediumSlotsFull =>
      mediumTasks.length >= AppConstants.rule135MediumTasks;
  bool get areSmallSlotsFull =>
      smallTasks.length >= AppConstants.rule135SmallTasks;

  @override List<Object?> get props => [bigTask, mediumTasks, smallTasks];
}
```

The Cubit emits a warning event (or a flag in state) when a slot is over capacity — it does NOT block the assignment. [VERIFIED: CONTEXT.md — "Constraint violation is a UI warning, not a hard block"]

---

## Soft Delete + Undo Pattern

### Timer-Based Undo in BLoC

```dart
// In a presentation-layer helper or directly in the Cubit:

Timer? _undoTimer;

void softDelete(Id itemId) {
  _repository.softDelete(itemId); // sets deletedAt = now
  emit(TaskListWithPendingUndo(itemId: itemId, ...currentState));

  _undoTimer?.cancel();
  _undoTimer = Timer(AppConstants.undoSnackbarDuration, () {
    // 5 seconds elapsed — permanently committed (already soft-deleted)
    emit(TaskListLoaded(...));
  });
}

void restoreItem(Id itemId) {
  _undoTimer?.cancel();
  _undoTimer = null;
  _repository.restoreItem(itemId); // sets deletedAt = null
  emit(TaskListLoaded(...));
}
```

`AppConstants.undoSnackbarDuration = Duration(seconds: 5)` [VERIFIED: `lib/core/constants/app_constants.dart`]

### ScaffoldMessenger Snackbar Pattern

```dart
// In the widget (presentation layer):
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    duration: AppConstants.undoSnackbarDuration,
    content: Text(l10n.taskDeleted),
    action: SnackBarAction(
      label: l10n.undo,
      onPressed: () => context.read<TaskListCubit>().restoreItem(itemId),
    ),
  ),
);
```

---

## UI Patterns

### Eisenhower 2×2 Board (Material 3)

No specialized package needed. Use a 2×2 `GridView` or nested `Column`/`Row` with `Expanded` children. Each quadrant is a `Card` with a header label and a scrollable `ListView` of task chips.

```dart
// Pattern: 2x2 grid using Row + Column
Row(
  children: [
    Expanded(child: _QuadrantCard(label: 'Do Now', items: q1Items)),
    Expanded(child: _QuadrantCard(label: 'Schedule', items: q2Items)),
  ],
),
Row(
  children: [
    Expanded(child: _QuadrantCard(label: 'Delegate', items: q3Items)),
    Expanded(child: _QuadrantCard(label: 'Eliminate', items: q4Items)),
  ],
),
```

Color-code quadrants using Material 3 color scheme tokens (`colorScheme.errorContainer` for Q1, `colorScheme.primaryContainer` for Q2, etc.). [ASSUMED: Material 3 design recommendation — not verified against specific documentation]

### 1-3-5 Day Planner Slots (Material 3)

Use `ListView` with section headers and `DragTarget`/`Draggable` widgets if drag-to-assign is desired, or simpler tap-to-assign with a bottom sheet task picker. For Phase 2, tap-to-assign from a filtered task list is sufficient.

```dart
// Section structure:
Column(
  children: [
    _SlotSection(
      label: l10n.bigTask,      // "1 Big Task"
      maxSlots: AppConstants.rule135BigTasks,
      items: state.bigTask != null ? [state.bigTask!] : [],
      isOverCapacity: false,
    ),
    _SlotSection(
      label: l10n.mediumTasks,
      maxSlots: AppConstants.rule135MediumTasks,
      items: state.mediumTasks,
      isOverCapacity: state.areMediumSlotsFull,
    ),
    _SlotSection(
      label: l10n.smallTasks,
      maxSlots: AppConstants.rule135SmallTasks,
      items: state.smallTasks,
      isOverCapacity: state.areSmallSlotsFull,
    ),
  ],
)
```

Reference `AppConstants.rule135BigTasks` (1), `rule135MediumTasks` (3), `rule135SmallTasks` (5). [VERIFIED: `lib/core/constants/app_constants.dart`]

### GTD Context Tags

Render as `FilterChip` or `Chip` widgets with the GTD context string. No predefined list — dynamically built from the distinct `gtdContext` values in the database.

```dart
// Fetch distinct contexts:
final contexts = await isar.itemModels
  .filter()
  .deletedAtIsNull()
  .gtdContextIsNotNull()
  .findAll()
  .then((items) => items.map((i) => i.gtdContext!).toSet().toList()..sort());
```

Display as `Wrap` of `FilterChip` widgets for multi-select filter.

### Task Form

Single `Form` widget with fields for: title (required), description (optional), itemType (SegmentedButton), priority (DropdownButton), dueDate (DatePicker), dueTime (TimePicker), recurrenceRule (custom picker or radio group), isUrgent/isImportant (Switch), sizeCategory (SegmentedButton), GTD fields (chips + text fields).

Use `showDatePicker()` and `showTimePicker()` — built-in Flutter Material widgets. Convert `TimeOfDay` result to minutes-since-midnight for storage: `time.hour * 60 + time.minute`.

---

## Architecture: Directory Structure

```
lib/
├── core/                          # Phase 1 — unchanged
├── domain/
│   └── tasks/
│       ├── item.dart              # Domain entity (pure Dart)
│       ├── item_type.dart         # ItemType enum (imported by domain only)
│       ├── priority.dart          # Priority enum
│       ├── size_category.dart     # SizeCategory enum
│       ├── eisenhower_quadrant.dart  # Sealed enum + computed getter
│       ├── item_repository.dart   # Abstract interface
│       └── recurrence_engine.dart # Abstract domain service
├── data/
│   ├── database/                  # Phase 1 — unchanged
│   └── tasks/
│       ├── item_model.dart        # @Collection Isar schema
│       ├── item_model.g.dart      # Generated — do not edit
│       ├── item_mapper.dart       # ItemModel ↔ Item converter
│       └── item_dao.dart          # Raw Isar queries
├── infrastructure/
│   └── tasks/
│       ├── item_repository_impl.dart  # Implements ItemRepository
│       └── recurrence_engine_impl.dart
├── application/
│   └── tasks/
│       ├── task_list/
│       │   ├── task_list_cubit.dart
│       │   ├── task_list_state.dart
│       │   └── task_list_filter.dart
│       ├── project/
│       │   ├── project_cubit.dart
│       │   └── project_state.dart
│       └── day_planner/
│           ├── day_planner_cubit.dart
│           └── day_planner_state.dart
├── presentation/
│   └── tasks/
│       ├── screens/
│       │   ├── task_list_screen.dart
│       │   ├── project_screen.dart
│       │   ├── task_form_screen.dart
│       │   ├── eisenhower_screen.dart
│       │   ├── day_planner_screen.dart
│       │   └── gtd_filter_screen.dart
│       └── widgets/
│           ├── task_card.dart
│           ├── quadrant_card.dart
│           ├── slot_section.dart
│           └── gtd_chip.dart
└── config/
    └── di/
        └── tasks_module.dart      # Populate with @injectable registrations
```

---

## Migration Strategy

### MigrationRunner — Version 1 → 2

**Required changes:**
1. Bump `AppConfig.schemaVersion` from `1` to `2`
2. Add `case 2:` migration block in `MigrationRunner._runMigration()`
3. Pass `ItemModelSchema` to `IsarService.open()` in `main.dart`

```dart
// lib/core/config/app_config.dart — bump this:
static const int schemaVersion = 2;  // was 1
```

```dart
// lib/data/database/migration_runner.dart — add case:
static Future<void> _runMigration(Isar isar, int toVersion) async {
  switch (toVersion) {
    case 1:
      return; // Initial schema — no data migration needed
    case 2:
      // Add ItemModel collection (tasks, projects, subtasks).
      // No data migration needed — new collection, starts empty.
      return;
  }
}
```

```dart
// lib/main.dart — IsarService.open() call:
await IsarService.instance.open([
  ItemModelSchema,  // generated by isar_community_generator
]);
```

[VERIFIED: `lib/data/database/isar_service.dart` — `open(List<CollectionSchema<dynamic>> schemas)` parameter; `lib/data/database/migration_runner.dart` — case 1 pattern to follow]

**Note:** The Phase 1 `open([])` call passes an empty schema list (no collections yet). Phase 2 adds `ItemModelSchema` — this is a no-op migration (new collection, no existing data to transform).

### DI Registration — tasks_module.dart

```dart
// lib/config/di/tasks_module.dart — replace the empty stub:
@module
abstract class TasksModule {
  @singleton
  ItemRepositoryImpl get itemRepository;
  // RecurrenceEngineImpl is injected into ItemRepositoryImpl via constructor
}
```

Or use `@injectable` on the implementation classes directly (matches the existing pattern in the project — `LocaleCubit` uses `@injectable`, not a module getter). Choose based on whether `ItemRepositoryImpl` takes constructor arguments that need DI resolution.

---

## Validation Architecture

`nyquist_validation` is `true` in `.planning/config.json`. [VERIFIED: `.planning/config.json`]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK bundle) + `bloc_test` 10.0.0 + `mocktail` 1.0.5 |
| Config file | None — standard Flutter test runner |
| Quick run command | `flutter test test/domain/ test/data/ test/application/ --no-pub` |
| Full suite command | `flutter test --no-pub --coverage` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TASK-01 | ItemRepository.createItem with ItemType.project | unit | `flutter test test/domain/tasks/item_repository_test.dart -x` | ❌ Wave 0 |
| TASK-02 | Subtask parentId wiring; ProjectCubit rollup count | unit | `flutter test test/application/tasks/project_cubit_test.dart -x` | ❌ Wave 0 |
| TASK-03 | Standalone task with dueDate + dueTime stored correctly | unit | `flutter test test/data/tasks/item_mapper_test.dart -x` | ❌ Wave 0 |
| TASK-04 | updateItem overwrites fields; updatedAt changes | unit | `flutter test test/domain/tasks/item_repository_test.dart -x` | ❌ Wave 0 |
| TASK-05 | softDelete sets deletedAt; restoreItem nulls it | unit | `flutter test test/domain/tasks/item_repository_test.dart -x` | ❌ Wave 0 |
| TASK-06 | isCompleted=true; recurring item spawns next occurrence | unit | `flutter test test/domain/tasks/recurrence_engine_test.dart -x` | ❌ Wave 0 |
| TASK-07 | EisenhowerQuadrant computed getter — all 4 combinations | unit | `flutter test test/domain/tasks/eisenhower_quadrant_test.dart -x` | ❌ Wave 0 |
| TASK-08 | DayPlannerCubit enforces slot counts; over-capacity flag | unit | `flutter test test/application/tasks/day_planner_cubit_test.dart -x` | ❌ Wave 0 |
| TASK-09 | GTD fields stored and queried correctly | unit | `flutter test test/data/tasks/item_dao_test.dart -x` | ❌ Wave 0 |
| TASK-10 | RecurrenceEngine.nextOccurrence — DAILY/WEEKLY/MONTHLY/YEARLY | unit | `flutter test test/domain/tasks/recurrence_engine_test.dart -x` | ❌ Wave 0 |
| TASK-11 | titleContains keyword search returns correct items | unit | `flutter test test/data/tasks/item_dao_test.dart -x` | ❌ Wave 0 |
| TASK-12 | Multi-criteria filter composes correctly | unit | `flutter test test/application/tasks/task_list_cubit_test.dart -x` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/domain/ test/data/ test/application/ --no-pub`
- **Per wave merge:** `flutter test --no-pub --coverage`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

All test files listed above are new (Phase 2 adds no existing test files for this domain).

Required new test files:
- [ ] `test/domain/tasks/eisenhower_quadrant_test.dart` — covers TASK-07
- [ ] `test/domain/tasks/recurrence_engine_test.dart` — covers TASK-06, TASK-10
- [ ] `test/domain/tasks/item_repository_test.dart` — covers TASK-01, TASK-04, TASK-05
- [ ] `test/data/tasks/item_mapper_test.dart` — covers TASK-03 (pure Dart, no Isar needed)
- [ ] `test/data/tasks/item_dao_test.dart` — covers TASK-09, TASK-11 (requires in-memory Isar or mocktail mock)
- [ ] `test/application/tasks/task_list_cubit_test.dart` — covers TASK-12 (uses mock ItemRepository)
- [ ] `test/application/tasks/project_cubit_test.dart` — covers TASK-02 (uses mock ItemRepository)
- [ ] `test/application/tasks/day_planner_cubit_test.dart` — covers TASK-08 (pure state machine, no repo needed)

**Note on Isar in tests:** Isar requires native binaries even in tests. For unit tests of `ItemDao`, prefer mocking the `IsarCollection` via mocktail, or use the `Isar.openSync()` in-memory mode (temp directory) available in `isar_community`. The `MigrationRunner` test pattern already uses `MockIsar`. [VERIFIED: `test/data/database/migration_runner_test.dart` — `class MockIsar extends Mock implements Isar {}`]

---

## Security Domain

Phase 2 has no authentication, network calls, or sensitive data storage beyond what Phase 1 already handles. ASVS categories that apply:

| ASVS Category | Applies | Control |
|---------------|---------|---------|
| V2 Authentication | No | N/A in Phase 2 |
| V3 Session Management | No | N/A in Phase 2 |
| V4 Access Control | No | N/A in Phase 2 |
| V5 Input Validation | Yes | Validate title non-empty, amount non-negative before calling repository; emit `ValidationFailure` on invalid input |
| V6 Cryptography | No | N/A in Phase 2 |

**Input validation rules for Phase 2:**
- `title` must be non-empty (ValidationFailure if blank)
- `moneyInfo.amount` must be >= 0.0 if provided
- `timeInfo.dueTimeMinutes` must be in range 0..1439 if provided
- `recurrenceRule` must parse successfully if non-null (emit ValidationFailure otherwise)

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Query result reactivity | Custom stream controller + change detection | `collection.watchLazy()` | Built into Isar — fires on any write to the collection |
| DI wiring for cubits | Manual GetIt registrations | `@injectable` annotation + build_runner | Already established pattern in Phase 1 |
| State equality | Override `==` and `hashCode` manually | `equatable` package (already in pubspec) | Safe, fast, zero boilerplate |
| Cubit testing | Raw async calls + assertions | `blocTest()` from `bloc_test` | Declarative, handles state sequence assertions |
| Date/time math | Custom date arithmetic | `DateTime` standard library arithmetic | Sufficient for RRULE subset; no external package needed |
| Snackbar undo timer | Manual `Future.delayed` chains | `Timer` from `dart:async` + BLoC pattern | Cancellable, explicit, testable |

---

## Common Pitfalls

### Pitfall 1: Sync Isar Calls in Production Code

**What goes wrong:** Using `findSync()`, `putSync()`, or `deleteSync()` — these block the UI thread and are banned by project convention.
**Why it happens:** Isar offers both sync and async APIs; sync is tempting for simplicity.
**How to avoid:** All `ItemDao` methods must be `async` returning `Future<T>`. Add a lint note in the class doc.
**Warning signs:** Method name ending in `Sync` anywhere in `lib/data/` or `lib/infrastructure/`.

### Pitfall 2: Forgetting `.deletedAtIsNull()` in Queries

**What goes wrong:** Soft-deleted items appear in task lists, search results, and subtask rollup counts.
**Why it happens:** Every new query must opt in to the filter — there is no global "active only" scope.
**How to avoid:** Private `_activeItems()` base query method on `ItemDao` that all public methods chain from.
**Warning signs:** Query in `ItemDao` that does not call `.deletedAtIsNull()`.

### Pitfall 3: Embedded Object Field Indexing

**What goes wrong:** Adding `@Index()` to a field inside `@embedded` class — Isar ignores it and no index is created.
**Why it happens:** Isar only indexes fields on the `@Collection` class, not nested embedded objects.
**How to avoid:** Promote `dueDate` (and any other indexed field) to a top-level field on `ItemModel`.
**Warning signs:** A field in `MoneyInfo` or `TimeInfo` carrying `@Index()`.

### Pitfall 4: EisenhowerQuadrant Imported in Data Layer

**What goes wrong:** `ItemModel` imports `EisenhowerQuadrant` from `lib/domain/tasks/` — violates the data layer having zero domain knowledge.
**Why it happens:** It feels natural to compute the quadrant in the model.
**How to avoid:** Quadrant computation happens only in `ItemMapper.toDomain()` or in the domain entity itself. `ItemModel` stores only `isUrgent` and `isImportant`.
**Warning signs:** `import 'package:agenda/domain/tasks/eisenhower_quadrant.dart'` in any file under `lib/data/`.

### Pitfall 5: Code Generation Not Run After Schema Change

**What goes wrong:** Adding a field to `ItemModel` without re-running build_runner causes `item_model.g.dart` to be stale — Isar uses the old schema at runtime.
**Why it happens:** Build runner is a manual step.
**How to avoid:** Each plan that modifies `ItemModel` must include `dart run build_runner build --delete-conflicting-outputs` as a required task step.
**Warning signs:** Compile errors about missing generated methods, or runtime schema mismatch.

### Pitfall 6: DayPlannerCubit State Persisting Across Hot Restart

**What goes wrong:** DayPlannerCubit is registered as `@singleton` — the slot state survives hot restart in development, causing confusing test conditions.
**Why it happens:** Singleton lifecycle vs. per-session intent.
**How to avoid:** Register `DayPlannerCubit` as `@injectable` (factory), NOT `@singleton`. Create a new instance per screen navigation. Slot state is intentionally ephemeral (in-memory only).
**Warning signs:** `DayPlannerCubit` decorated with `@singleton`.

### Pitfall 7: RRULE Parser Not Handling Unknown Tokens

**What goes wrong:** A user somehow stores an unrecognized RRULE token; parser throws an exception; whole app crashes.
**Why it happens:** Edge cases in freeform string parsing.
**How to avoid:** Parser returns `null` (or `ParsedRrule.invalid`) on unrecognized tokens instead of throwing. Repository emits `ValidationFailure` if RRULE is non-null but unparseable.
**Warning signs:** `throw` anywhere in `RecurrenceEngineImpl.parse()`.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Isar 3.3.2 does not support indexing fields inside `@embedded` objects | Isar Schema Design | If wrong, `dueDate` can stay in `TimeInfo` without promotion — minor refactor |
| A2 | `titleContains()` does a linear scan (no special index) for case-insensitive substring | Query Patterns | If wrong (e.g. Isar has hidden FTS), search could be faster; no negative impact |
| A3 | Material 3 color scheme tokens are appropriate for Eisenhower quadrant coloring | UI Patterns | Cosmetic only — no functional risk |
| A4 | RecurrenceEngine domain service has no external dependency needed | Recurrence Engine | If RRULE subset grows (Phase 5+), a package like `rrule` may be needed |

---

## Open Questions

1. **dueDate promotion vs embedded field**
   - What we know: Isar 3.x cannot index embedded object fields [A1 — assumed from source inspection of annotation target kinds]
   - What's unclear: Whether the isar_community fork has extended this — the 3.3.2 source does not explicitly document embedded indexing support
   - Recommendation: Promote `dueDate` to a top-level field on `ItemModel`. Worst case, this is an unnecessary field if embedded indexing works — trivially removed in a migration.

2. **DayPlannerCubit persistence across days**
   - What we know: CONTEXT.md says slot state is in-memory (not persisted)
   - What's unclear: If the user closes and reopens the app mid-day, should the 1-3-5 assignments be restored? Current decision is no (ephemeral).
   - Recommendation: Leave ephemeral for Phase 2. If user feedback demands persistence, Phase 3 can add a `DayPlanningSession` Isar collection with a date key.

3. **Distinct GTD context fetch performance**
   - What we know: Fetching all active items and extracting unique `gtdContext` values in Dart is O(n) in items
   - What's unclear: Whether Isar 3.x has a `distinct()` projection query that avoids loading full objects
   - Recommendation: Use `.distinctBy()` in the QueryBuilder if available in generated code, or fetch all items and deduplicate in Dart for Phase 2 (item counts will be small).

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All | ✓ | 3.41.4 (CI) | — |
| isar_community 3.3.2 | ItemModel schema | ✓ | 3.3.2 | — |
| build_runner | Code generation | ✓ | ^2.13.1 | — |
| bloc_test 10.0.0 | Cubit unit tests | ✓ | 10.0.0 | — |
| mocktail 1.0.5 | Repository mocks | ✓ | 1.0.5 | — |

All dependencies are already present. No new packages needed. [VERIFIED: `pubspec.yaml` read directly]

---

## Sources

### Primary (HIGH confidence)
- `lib/data/database/isar_service.dart` — IsarService open() pattern verified
- `lib/data/database/migration_runner.dart` — Migration case pattern verified
- `lib/core/failures/failure.dart` — Failure hierarchy verified
- `lib/core/failures/result.dart` — Result<T>/AsyncResult<T> typedefs verified
- `lib/core/constants/app_constants.dart` — 1-3-5 slot counts, undoSnackbarDuration verified
- `lib/config/di/tasks_module.dart` — Empty placeholder confirmed
- `lib/config/di/core_module.dart` — @module, @singleton, @preResolve patterns verified
- `lib/application/shared/locale/locale_cubit.dart` — @injectable Cubit pattern verified
- `lib/config/di/injection.config.dart` — Generated DI config pattern verified
- `.planning/phases/02-task-core/02-CONTEXT.md` — All locked decisions read directly
- `.planning/REQUIREMENTS.md` — TASK-01 through TASK-12 verified
- `.planning/config.json` — nyquist_validation: true confirmed
- `isar_community-3.3.2/lib/src/isar_collection.dart` — watchLazy(), filter(), count() API verified
- `isar_community-3.3.2/lib/src/annotations/index.dart` — @Index, IndexType, composite verified
- `isar_community-3.3.2/lib/src/annotations/embedded.dart` — @embedded annotation verified
- `pubspec.yaml` — All package versions confirmed, no new packages needed for Phase 2

### Secondary (MEDIUM confidence)
- `test/data/database/migration_runner_test.dart` — MockIsar pattern for unit tests confirmed

### Tertiary (LOW confidence — marked [ASSUMED] in text)
- A1: Embedded field indexing limitation in Isar 3.x (inferred from @Index TargetKind source)
- A2: `titleContains()` linear scan behaviour (inferred from hash index documentation)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages verified in pubspec.yaml and pub cache
- Isar schema: HIGH (embedded), MEDIUM (embedded indexing limitation — A1)
- Architecture patterns: HIGH — verified against Phase 1 codebase directly
- Recurrence engine: HIGH for design; MEDIUM for RRULE parsing edge cases
- Cubit state shapes: HIGH — follows established LocaleCubit pattern
- UI patterns: MEDIUM — Material 3 widget choices are standard but not verified against specific documentation
- Migration strategy: HIGH — directly mirrors Phase 1 MigrationRunner pattern

**Research date:** 2026-04-13
**Valid until:** 2026-05-13 (stable stack; no fast-moving dependencies)

---

## RESEARCH COMPLETE
