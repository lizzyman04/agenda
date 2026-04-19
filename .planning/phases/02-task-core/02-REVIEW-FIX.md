---
phase: "02"
status: all_fixed
findings_in_scope: 10
fixed: 10
skipped: 0
iteration: 1
---

# Phase 02: Code Review Fix Report

**Fixed at:** 2026-04-19T00:00:00Z
**Source review:** .planning/phases/02-task-core/02-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 10 (4 High + 6 Medium)
- Fixed: 10
- Skipped: 0

---

## Fixed Issues

### HR-01: Unsafe `as` cast in `createItem` — crash on any Err branch

**Files modified:** `lib/infrastructure/tasks/item_repository_impl.dart`, `lib/application/tasks/project/project_cubit.dart`
**Commit:** 61833d3
**Applied fix:** Replaced the two-step `is Err<T>` guard + unconditional `as Success<T>` downcast pattern with exhaustive `switch` pattern matching at all three call sites: `createItem` in `item_repository_impl.dart`, and both `loadProject` and `_refreshSubtasks` in `project_cubit.dart`. Local variables are now assigned via `case Success<T>(:final value)`, eliminating the runtime `TypeError` risk entirely.

---

### HR-02: Fire-and-forget cubit calls in `TaskFormScreen._save` — errors silently lost

**Files modified:** `lib/presentation/tasks/screens/task_form_screen.dart`
**Commit:** 65dc83f
**Applied fix:** Changed `_save` from `void` to `Future<void> async`. Both `context.read<TaskListCubit>().updateItem(saved)` and `.createItem(saved)` are now awaited. Added `if (!mounted) return;` guard before `Navigator.of(context).pop()` to prevent use of a stale `BuildContext` after the async gap. The `onPressed` callback in the AppBar is updated to `() => _save()` to correctly handle the returned Future.

---

### HR-03: `softDelete` reads back a soft-deleted item — returns stale null-id data

**Files modified:** `lib/infrastructure/tasks/item_repository_impl.dart`
**Commit:** 81ad2f0
**Applied fix:** Both `softDelete` and `restoreItem` now call `_dao.findById(id)` directly after the DAO write instead of delegating to `getItem(id)`. This reads the model by raw Isar id (bypassing any `deletedAtIsNull()` filter) and maps it to a domain object via `_mapper.toDomain()`. A null check returns `Err<Item>(DatabaseFailure(...))` if the model is missing. A comment explains why `getItem` must not be used here.

---

### HR-04: `copyWith` cannot clear nullable fields — edit form silently retains stale data

**Files modified:** `lib/domain/tasks/item.dart`
**Commit:** 27e525b
**Applied fix:** Introduced a `clearField` sentinel constant (`const Object clearField = _Absent()`) and a private `final class _Absent`. All nullable `copyWith` parameters now default to `clearField` instead of `null`. Inside the constructor call, each nullable field checks `is _Absent` — if true it keeps `this.field`, otherwise it casts to the target type. This lets callers write `item.copyWith(dueDate: clearField)` to explicitly null a field, while `item.copyWith()` (no arguments) still preserves all existing values. The stale doc comment pointing callers to bypass the domain layer via direct Isar writes was replaced with accurate documentation.

---

### MR-01: `Result<T> = Object` typedef — no compile-time type safety at unwrap sites

**Files modified:** `lib/core/failures/result.dart`
**Commit:** 01c7163
**Applied fix:** Replaced `typedef Result<T> = Object` with `sealed class Result<T>`. `Success<T>` and `Err<T>` are now declared as `final class` subtypes extending `Result<T>`. `AsyncResult<T>` typedef updated to `Future<Result<T>>`. All existing call sites already used `is Success<T>` / `is Err<T>` pattern checks — these continue to work unchanged and are now exhaustiveness-checked by the Dart compiler. No other files required modification since the type was previously erased to `Object` at every usage site.

---

### MR-02: `getDistinctGtdContexts` loads entire active item collection into memory

**Files modified:** `lib/data/tasks/item_dao.dart`, `lib/infrastructure/tasks/item_repository_impl.dart`
**Commit:** 09401b3
**Applied fix:** Added `findDistinctGtdContexts()` to `ItemDao` — it queries Isar with `.deletedAtIsNull().gtdContextIsNotNull().findAll()`, then maps to a deduplicated sorted `List<String>`. `ItemRepositoryImpl.getDistinctGtdContexts()` now calls this DAO method directly instead of calling `filterItems()` and doing an in-Dart projection over up to 500 full `ItemModel` objects.

---

### MR-03: `DayPlannerCubit.assignMedium` / `assignSmall` allow unbounded duplicates

**Files modified:** `lib/application/tasks/day_planner/day_planner_cubit.dart`
**Commit:** 5e2f1fb
**Applied fix:** Added duplicate guards at the top of both `assignMedium` and `assignSmall`: `if (state.mediumTasks.any((i) => i.id == item.id)) return;` and the equivalent for small tasks. If the item is already in the slot list the method is a no-op. Updated doc comments to document the no-duplicate invariant.

---

### MR-04: Recurrence rule frozen to original `dueDate.day` when date changes in form

**Files modified:** `lib/presentation/tasks/screens/task_form_screen.dart`
**Commit:** 1f326cc
**Applied fix:** Inside `_pickDate`, the `setState` callback now also checks whether `_recurrenceRule` starts with `'FREQ=MONTHLY'` and, if so, sets it to `null`. This forces the user to re-select the monthly recurrence rule after choosing a new due date, ensuring the `BYMONTHDAY=` value always reflects the currently selected day.

---

### MR-05: `_nextMonthly` month overflow drops millisecond/microsecond precision

**Files modified:** `lib/infrastructure/tasks/recurrence_engine_impl.dart`
**Commit:** 9a46d50
**Applied fix:** Added `from.millisecond` and `from.microsecond` to the `DateTime` constructor in both `_nextMonthly` and the `yearly` branch of `nextOccurrence`. Sub-second components are now fully preserved across all recurrence frequencies that construct a new `DateTime` explicitly. The `daily` and `weekly` branches use `Duration` arithmetic which already preserves full precision.

---

### MR-06: `TaskFormScreen` comment numbers wrong — both switches say "8."

**Files modified:** `lib/presentation/tasks/screens/task_form_screen.dart`
**Commit:** 00fd372
**Applied fix:** Renumbered all section comments from the duplicate `// 8. Important` onward: Important → 9, Size → 10, Next Action → 11, GTD Context → 12, Waiting For → 13, Amount → 14, Currency → 15. Urgent correctly remains 8. The sequence is now unique and contiguous.

---

_Fixed: 2026-04-19T00:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
