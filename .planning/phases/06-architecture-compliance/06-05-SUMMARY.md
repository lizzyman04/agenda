---
phase: 06-architecture-compliance
plan: 05
subsystem: data/infrastructure (tasks)
tags: [isar, querybuilder, dependency-injection, mixin, part-of, refactor, architecture-compliance]

# Dependency graph
requires:
  - phase: 06-architecture-compliance
    provides: tool/check_architecture.dart guard script (line-count/dir-size/README checks) already on main
provides:
  - lib/data/tasks/item_query_builder.dart — top-level buildItemFilterQuery() extracted from ItemDao.filterItems (Pattern 3)
  - lib/infrastructure/tasks/item_repository_impl_queries.dart — query methods of ItemRepositoryImpl split via part/part-of + mixin (Pattern 4, adapted)
  - item_dao.dart and item_repository_impl.dart both under the 150-line cap
affects: [06-18 (CI enforcement of the architecture guard, once all phase plans land)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure QueryBuilder composition extracted to a top-level function taking the Isar collection as a parameter (Pattern 3)"
    - "part/part-of + private mixin for splitting a single DI-registered class across files when methods need shared private state (Pattern 4, corrected from the research doc's literal description)"

key-files:
  created:
    - lib/data/tasks/item_query_builder.dart
    - lib/infrastructure/tasks/item_repository_impl_queries.dart
  modified:
    - lib/data/tasks/item_dao.dart
    - lib/infrastructure/tasks/item_repository_impl.dart

key-decisions:
  - "Pattern 4 as literally described in 06-RESEARCH.md (continuing a class's method set across part/part-of files) is not valid Dart — Dart has no partial-class syntax; a class body must be complete in one file. Verified by a minimal compile test before implementing."
  - "Used a private mixin (_ItemRepositoryImplQueries) declared in the part file, with abstract _dao/_mapper getters, applied via `with` on ItemRepositoryImpl. This achieves every property Pattern 4 was meant to deliver (same-library private field access, single class, single DI registration, zero public interface change) using a construct Dart actually supports."
  - "@override annotations removed from the mixin's methods — the mixin itself has no `on`/`implements` clause pointing at ItemRepository, so the analyzer flags them as override_on_non_overriding_member; interface satisfaction is checked at the composing class (ItemRepositoryImpl implements ItemRepository), not at the mixin."

patterns-established:
  - "Pattern 4 (corrected): part/part-of + mixin with abstract getters for shared private fields, rather than literal class-body continuation."

requirements-completed: []

# Metrics
duration: 25min
completed: 2026-08-11
---

# Phase 06 Plan 05: Split item_dao.dart and item_repository_impl.dart Summary

**Extracted ItemDao's Isar filter-query chain to a top-level function and split ItemRepositoryImpl's CRUD/query methods across two files via part/part-of plus a private mixin — both target files now under 150 lines with zero public interface or DI change.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-08-11T15:23:00Z
- **Completed:** 2026-08-11T15:48:24Z
- **Tasks:** 2/2 completed
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments
- `item_dao.dart` (178 → 136 lines) and `item_repository_impl.dart` (227 → 139 lines) both now comply with the 150-line house rule.
- `buildItemFilterQuery(...)` is now an independently testable top-level function operating on the public Isar `QueryBuilder`/`IsarCollection` types.
- `ItemRepositoryImpl` remains a single class with a single `@LazySingleton(as: ItemRepository)` DI registration — confirmed by rerunning `build_runner` (no `injection.config.dart` diff) and the DI smoke test.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extract the Isar query builder from item_dao.dart** - `a69619f` (refactor)
2. **Task 2: Split item_repository_impl.dart into CRUD and query parts** - `fb83f8e` (refactor)

**Plan metadata:** (this commit, docs: complete plan)

## Files Created/Modified
- `lib/data/tasks/item_query_builder.dart` - New file; top-level `buildItemFilterQuery(IsarCollection<ItemModel>, {...})` holding the `.optional()` filter chain moved verbatim from `ItemDao.filterItems`, including the nullable-to-local-promotion comment.
- `lib/data/tasks/item_dao.dart` - `filterItems()` now delegates to `buildItemFilterQuery(...).limit(500).findAll()`. 136 lines.
- `lib/infrastructure/tasks/item_repository_impl.dart` - Retains constructor, fields (`_dao`, `_mapper`, `_recurrenceEngine`), and the five CRUD methods (`createItem`, `getItem`, `updateItem`, `softDelete`, `restoreItem`). Now declares `class ItemRepositoryImpl extends Object with _ItemRepositoryImplQueries implements ItemRepository` and `part 'item_repository_impl_queries.dart';`. 139 lines.
- `lib/infrastructure/tasks/item_repository_impl_queries.dart` - New file; `part of 'item_repository_impl.dart';`, declares `mixin _ItemRepositoryImplQueries` with abstract `ItemDao get _dao;` / `ItemMapper get _mapper;` getters plus the seven query methods (`getItemsByType`, `getSubtasks`, `searchByTitle`, `filterItems`, `getSubtaskCounts`, `watchChanges`, `getDistinctGtdContexts`) and the private `_toModelType` helper, moved verbatim from the original file. 112 lines.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Pattern 4 as literally specified in 06-RESEARCH.md is not valid Dart**
- **Found during:** Task 2, before writing any code
- **Issue:** The plan's action text and research's Pattern 4 describe moving methods "verbatim" into a `part of` file so they "retain direct access to `_dao`/`_mapper`" as if the class body itself continues across files. Dart has no C#-style partial-class syntax — a class's `{ ... }` body must be complete within a single file/part-of unit. Verified this before implementing by writing a minimal two-file `part`/`part of` reproduction attempting literal class-body continuation; confirmed the correct Dart mechanism is a **mixin** declared in the part file (same library scope via `part of`, so private field names resolve), applied to the class via `with`.
- **Fix:** `item_repository_impl_queries.dart` declares `mixin _ItemRepositoryImplQueries` with abstract `_dao`/`_mapper` getters and the seven query methods. `item_repository_impl.dart`'s class declaration becomes `class ItemRepositoryImpl extends Object with _ItemRepositoryImplQueries implements ItemRepository`. This delivers every property the plan required — same-library private field sharing, one class, one DI registration, zero public interface change, zero call-site changes — through a construct Dart actually supports. Also removed `@override` annotations from the mixin's methods (the mixin has no `on`/`implements` clause naming `ItemRepository`, so the analyzer flags `@override` there as `override_on_non_overriding_member`; interface satisfaction is checked at the composing class).
- **Files modified:** `lib/infrastructure/tasks/item_repository_impl.dart`, `lib/infrastructure/tasks/item_repository_impl_queries.dart`
- **Commit:** `fb83f8e`

## Known Stubs

None — this is a pure structural refactor; no data source, UI, or behavior was stubbed.

## Threat Flags

None — no new attack surface introduced. Query semantics and error handling are byte-for-byte identical to before the split (confirmed by unchanged test suites and `flutter analyze`/`flutter test` results).

## Self-Check: PASSED

- FOUND: lib/data/tasks/item_query_builder.dart
- FOUND: lib/infrastructure/tasks/item_repository_impl_queries.dart
- FOUND: commit a69619f
- FOUND: commit fb83f8e
- item_dao.dart: 136 lines (<=150)
- item_query_builder.dart: 71 lines (<=150)
- item_repository_impl.dart: 139 lines (<=150)
- item_repository_impl_queries.dart: 112 lines (<=150)
- `flutter test test/data/tasks/ test/infrastructure/tasks/ test/config/di/` — 44/44 passing
- `dart run build_runner build --delete-conflicting-outputs` — succeeded, `injection.config.dart` unchanged (no diff)
- `dart run tool/check_architecture.dart` — neither file appears in the violation list
