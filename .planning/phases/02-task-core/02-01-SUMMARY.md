---
phase: 02
plan: 01
subsystem: task-domain
tags: [domain, entities, enums, repository-interface, recurrence-engine]
dependency_graph:
  requires: []
  provides: [Item entity, EisenhowerQuadrant enum, Priority enum, SizeCategory enum, ItemType enum, ItemRepository interface, RecurrenceEngine interface, domain test stubs]
  affects: [02-02-PLAN.md (schema mirrors domain entity), 02-03-PLAN.md (cubits depend on repository interface), 02-04-PLAN.md (presentation uses domain types)]
tech_stack:
  added: []
  patterns: [pure-dart-domain, sealed-enum-exhaustive-switch, async-result-return]
key_files:
  created:
    - lib/domain/tasks/item_type.dart
    - lib/domain/tasks/priority.dart
    - lib/domain/tasks/size_category.dart
    - lib/domain/tasks/eisenhower_quadrant.dart
    - lib/domain/tasks/item.dart
    - lib/domain/tasks/item_repository.dart
    - lib/domain/tasks/recurrence_engine.dart
    - test/domain/tasks/item_test.dart
    - test/domain/tasks/eisenhower_quadrant_test.dart
    - test/domain/tasks/recurrence_engine_test.dart
  modified: []
decisions:
  - "Item constructor parameter order: required params (id, type, title, createdAt, updatedAt) placed before optional params to satisfy always_put_required_named_parameters_first lint rule"
  - "item.dart does not import result.dart — AsyncResult is only needed by ItemRepository, not by the entity itself"
  - "recurrence_engine_test uses a concrete _TestRecurrenceEngine stub to exercise parse() contract since RecurrenceEngine is abstract; nextOccurrence() tests deferred to Plan 02 implementation"
metrics:
  duration: 8m 12s
  completed_date: "2026-04-14"
  tasks_completed: 5
  files_created: 10
  files_modified: 0
  tests_added: 26
---

# Phase 02 Plan 01: Task Domain Layer Summary

## One-liner

Pure-Dart task domain layer with Item entity, EisenhowerQuadrant computed getter, ItemRepository/RecurrenceEngine abstract interfaces, and 26 passing tests — zero Flutter or Isar imports.

## What Was Built

### Domain Enums (Task 2)

Four pure-Dart enum files in `lib/domain/tasks/`:

- `item_type.dart` — `ItemType { project, task, subtask }` — discriminates the unified Isar collection
- `priority.dart` — `Priority { low, medium, high, critical, urgent }` — five-level priority independent of Eisenhower
- `size_category.dart` — `SizeCategory { big, medium, small, none }` — 1-3-5 Rule day-planner slots
- `eisenhower_quadrant.dart` — `EisenhowerQuadrant { doNow, schedule, delegate, eliminate }` — computed only, never persisted

### Core Domain Files (Task 3)

- `item.dart` — `Item` entity with all task/project/subtask fields, `eisenhowerQuadrant` computed getter (switch on `(isUrgent, isImportant)`), `copyWith()` with nullable-limitation comment
- `item_repository.dart` — `ItemRepository` abstract interface with CRUD, `softDelete`, `restoreItem`, `searchByTitle`, `filterItems`, `getSubtaskCounts`, `watchChanges` — all returning `AsyncResult<T>`
- `recurrence_engine.dart` — `RecurrenceEngine` abstract domain service with `parse(String?)` returning `ParsedRrule?` and `nextOccurrence(DateTime, ParsedRrule)`; also defines `RruleFreq` enum and `ParsedRrule` value class

### Tests (Tasks 1 + 4)

26 tests across three files:

- `item_test.dart` — 13 tests: default field values, all four `eisenhowerQuadrant` getter cases, subtask/parentId validity
- `eisenhower_quadrant_test.dart` — 5 tests: all four enum values exist, count is exactly 4
- `recurrence_engine_test.dart` — 8 tests: parse null, parse invalid, DAILY, WEEKLY single day, WEEKLY multi-day, MONTHLY with BYMONTHDAY, YEARLY

## Success Criteria Verification

- [x] `lib/domain/tasks/` contains 7 files, all pure Dart with zero Flutter or Isar imports
- [x] `Item.eisenhowerQuadrant` is a computed getter — not a stored field
- [x] `ItemRepository` methods all return `AsyncResult<T>`
- [x] `RecurrenceEngine.parse()` returns null for unrecognised rules — documented
- [x] `flutter test test/domain/tasks/ --no-pub` exits 0 — 26/26 passing
- [x] `flutter analyze --no-fatal-infos` exits 0 — no issues
- [x] `grep -r "package:flutter\|package:isar" lib/domain/tasks/` returns no output

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 8973f32 | test(02-01): add domain test stubs |
| 2 | 46d6d8f | feat(02-01): add domain enums |
| 3 | e1b4594 | feat(02-01): add Item entity, ItemRepository, RecurrenceEngine |
| 4 | 02b8611 | test(02-01): fill domain test assertions |
| 5 | (verify only) | analyze + test suite — no new files |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused `result.dart` import from item.dart**
- **Found during:** Task 3
- **Issue:** Plan spec included `import 'package:agenda/core/failures/result.dart'` in `item.dart`, but `AsyncResult<T>` is not used in the entity — only in `item_repository.dart`. Keeping it would cause an `unused_import` lint error.
- **Fix:** Removed the import from `item.dart`. `item_repository.dart` imports it correctly.
- **Files modified:** `lib/domain/tasks/item.dart`
- **Commit:** e1b4594

**2. [Rule 1 - Bug] Reordered Item constructor required params**
- **Found during:** Task 3
- **Issue:** `createdAt` and `updatedAt` (required) were placed after optional params, triggering `always_put_required_named_parameters_first` lint rule from `very_good_analysis`.
- **Fix:** Moved `required this.createdAt` and `required this.updatedAt` immediately after `required this.title` in the constructor.
- **Files modified:** `lib/domain/tasks/item.dart`
- **Commit:** e1b4594

**3. [Rule 1 - Bug] Fixed doc comment infos in item_repository.dart**
- **Found during:** Task 3
- **Issue:** Doc comments used `[.limit(500)]`, `[updatedAt]`, `[deletedAt]` reference syntax, triggering `comment_references` and `unintended_html_in_doc_comment` infos.
- **Fix:** Rewrote affected doc comment lines to use plain text instead of bracket references for non-API symbols.
- **Files modified:** `lib/domain/tasks/item_repository.dart`
- **Commit:** e1b4594

**4. [Rule 1 - Bug] Fixed local variable naming in item_test.dart**
- **Found during:** Task 4/5
- **Issue:** `_now` and `_makeItem` used leading underscores for local variables, triggering `no_leading_underscores_for_local_identifiers`. Explicit `false` defaults in `_makeItem` calls triggered `avoid_redundant_argument_values`.
- **Fix:** Renamed to `now` / `makeItem`; removed redundant `isUrgent: false` / `isImportant: false` default arguments.
- **Files modified:** `test/domain/tasks/item_test.dart`
- **Commit:** 02b8611

## Known Stubs

None. All domain contracts are fully defined. `nextOccurrence()` implementation and its tests are correctly deferred to Plan 02 by design — the abstract interface is complete.

## Threat Flags

No new threat surface introduced. All files are pure-Dart domain layer with no network endpoints, no auth paths, no file access, and no schema changes at trust boundaries.

## Self-Check: PASSED
