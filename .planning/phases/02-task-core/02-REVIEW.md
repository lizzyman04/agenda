---
phase: "02"
status: findings
severity_counts:
  critical: 0
  high: 4
  medium: 6
  low: 4
  info: 3
reviewed_files: 32
---

# Phase 02 (task-core): Code Review Report

**Reviewed:** 2026-04-15T00:00:00Z
**Depth:** standard
**Files Reviewed:** 32
**Status:** issues_found

## Summary

The task-core phase delivers a well-structured, layered Flutter codebase covering the domain, data, infrastructure, application, and presentation layers for task management. The domain entities and BLoC cubits follow the established Result<T> pattern consistently. Isar queries use typed API methods and avoid string interpolation, matching the security requirement documented in T-02-01. The migration runner, mapper, and DI module are clean.

Four high-severity runtime issues were identified, primarily around the `copyWith` null-clearing limitation leading to data corruption on edit, an unsafe `as` cast in the create flow, a missing `await` on a fire-and-forget cubit call that can cause the form to close before the error state propagates, and a stale-data read-after-write in `softDelete`. Six medium-severity logic and maintainability issues cover the `Result` typedef unsafety pattern used at every call site, the `getDistinctGtdContexts` full-table-scan design, unbounded slot duplication, a wrong comment number, a frozen recurrence rule on date-change, and the `_nextMonthly` overflow edge case. Four low-severity and three info items round out the review.

---

## High Severity

### HR-01: Unsafe `as` cast in `createItem` — crash on any Err branch

**File:** `lib/infrastructure/tasks/item_repository_impl.dart:34-35`
**Issue:** `getItem` is called to validate the parent, and on success the code performs an unconditional `as Success<Item>` cast. Because `Result<T>` is typed as `Object`, if the value is an `Err` the guard on line 34 returns early — but only when `parentResult is Err<Item>`. However, if `parentResult` is a success holding a different concrete type (unlikely today but possible with the untyped `typedef Result<T> = Object`), the cast would throw a `TypeError` at runtime that bypasses the wrapping `try/catch` because `TypeError` is not caught by `on Object`. In practice the same unsafe `as` pattern is repeated in `project_cubit.dart:23` and `project_cubit.dart:98`. The root cause is that the project uses `typedef Result<T> = Object`, which erases the type, making every successful extraction require an explicit downcast that can fail at runtime if the wrong branch is entered.

**Fix:** Replace the two-step is-check + downcast with a pattern match at every call site:
```dart
// Instead of:
if (parentResult is Err<Item>) return parentResult;
final parent = (parentResult as Success<Item>).value;

// Use:
switch (parentResult) {
  case Err<Item>(:final failure):
    return Err<Item>(failure);
  case Success<Item>(:final value):
    // use value
}
```
Or promote `Result<T>` to a proper sealed class so the type system tracks exhaustion.

---

### HR-02: Fire-and-forget cubit calls in `TaskFormScreen._save` — errors silently lost

**File:** `lib/presentation/tasks/screens/task_form_screen.dart:153` and `lib/presentation/tasks/screens/task_form_screen.dart:183`
**Issue:** `context.read<TaskListCubit>().updateItem(saved)` and `.createItem(saved)` are called without `await`. Both methods are `async` and return `Future<void>`. Because `Navigator.of(context).pop()` on line 186 is called immediately after the unawaited fire, the screen is dismissed before the cubit has a chance to emit `TaskListError`. The user never sees any feedback when the create/update fails (e.g., DB write failure). Additionally, calling a method on a potentially-closed `BuildContext` inside a mounted widget is fine here, but the pattern makes it impossible to handle errors from `_save`.

**Fix:** Make `_save` async and await both calls, then check if the cubit emitted an error state before popping:
```dart
Future<void> _save() async {
  if (!_formKey.currentState!.validate()) return;
  // ... build saved item ...

  if (_isEditing) {
    await context.read<TaskListCubit>().updateItem(saved);
  } else {
    await context.read<TaskListCubit>().createItem(saved);
  }

  if (!mounted) return;
  // Optionally inspect cubit state for error before popping.
  Navigator.of(context).pop();
}
```

---

### HR-03: `softDelete` reads back a soft-deleted item — returns stale null-id data

**File:** `lib/infrastructure/tasks/item_repository_impl.dart:101-107`
**Issue:** `softDelete` calls `_dao.softDelete(id)` which writes `deletedAt = DateTime.now()` to the model, then immediately calls `getItem(id)`. `_dao.findById(id)` does a raw `_collection.get(id)` with no `deletedAtIsNull()` filter — so this call will succeed and return the deleted item. However, `restoreItem` follows the same two-step pattern. The real problem is that `getItem` already documents "Returns Err(DatabaseFailure) if not found" — after a soft-delete the item is NOT logically "not found" but the API is semantically misleading. More critically, if a future refactor adds `deletedAtIsNull()` to `findById`, both `softDelete` and `restoreItem` will start returning `Err` because the item is no longer reachable.

**Fix:** After the DAO operation, read the model directly inside the same transaction or capture the updated domain object before delegating to `getItem`:
```dart
@override
AsyncResult<Item> softDelete(int id) async {
  try {
    await _dao.softDelete(id);
    // Re-fetch by raw id (not filtered), map to domain, return it directly.
    final model = await _dao.findById(id);
    if (model == null) return Err<Item>(DatabaseFailure('Item $id not found after softDelete'));
    return Success<Item>(_mapper.toDomain(model));
  } on Object catch (e) {
    return Err<Item>(DatabaseFailure('softDelete failed: $e'));
  }
}
```
Apply the same fix to `restoreItem`.

---

### HR-04: `copyWith` cannot clear nullable fields — edit form silently retains stale data

**File:** `lib/domain/tasks/item.dart:122-177`
**Issue:** The `copyWith` method is documented explicitly: "nullable fields cannot be explicitly set to null via copyWith". Every nullable field uses `?? this.field`, so passing `null` is a no-op. This becomes a correctness bug in `TaskFormScreen._save` (edit mode, line 127-152): if the user clears the `dueDate` by not selecting a date, `_dueDate` is `null` in state. When `widget.item!.copyWith(dueDate: null)` is called, the existing `dueDate` from the original item is silently retained. The same applies to `description`, `gtdContext`, `waitingFor`, `recurrenceRule`, `amount`, and `currencyCode`.

**Fix — Option A (recommended):** Introduce a sentinel / `Optional<T>` wrapper pattern so `copyWith` can distinguish "not provided" from "set to null":
```dart
// Use a wrapper:
class _Absent { const _Absent(); }
const absent = _Absent();

Item copyWith({
  Object? dueDate = absent,
  // ...
}) {
  return Item(
    dueDate: dueDate is _Absent ? this.dueDate : dueDate as DateTime?,
    // ...
  );
}
```

**Fix — Option B (simpler short-term):** Add explicit `clearXxx()` methods for the clearable nullable fields used in the form (`clearDueDate`, `clearDescription`, etc.) and call them when the field is blank in the form save.

---

## Medium Severity

### MR-01: `Result<T> = Object` typedef — no compile-time type safety at unwrap sites

**File:** `lib/core/failures/result.dart:33`
**Issue:** `typedef Result<T> = Object` erases the generic entirely. Every call site must use `is Success<Item>` runtime type checks and then unsafe `as Success<Item>` downcasts. This is a project-wide pattern that bypasses Dart's type system — a wrong cast at any new call site will throw at runtime rather than fail at compile time. The `AsyncResult<T> = Future<Object>` has the same issue.

**Fix:** Replace with a proper sealed class:
```dart
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

typedef AsyncResult<T> = Future<Result<T>>;
```
All switch expressions on `Result` will then be exhaustively checked by the compiler.

---

### MR-02: `getDistinctGtdContexts` loads entire active item collection into memory

**File:** `lib/infrastructure/tasks/item_repository_impl.dart:183-202`
**Issue:** `getDistinctGtdContexts` calls `filterItems()` with no parameters, which fetches up to 500 active items into memory and then does an in-Dart `.map().whereType().toSet()` to extract unique contexts. This is a full collection scan through the application layer. As the collection grows toward the 500-item limit, this becomes both a memory and a latency issue, and it will silently miss any GTD contexts beyond the first 500 items.

**Fix:** Add a dedicated DAO method that queries only the `gtdContext` field:
```dart
Future<List<String>> findDistinctGtdContexts() async =>
    (await _collection
        .filter()
        .deletedAtIsNull()
        .gtdContextIsNotNull()
        .findAll())
        .map((m) => m.gtdContext!)
        .toSet()
        .toList()
      ..sort();
```
Alternatively, if the 500-item ceiling is acceptable for Phase 2, at minimum document the truncation risk in a comment.

---

### MR-03: `DayPlannerCubit.assignMedium` / `assignSmall` allow unbounded duplicates

**File:** `lib/application/tasks/day_planner/day_planner_cubit.dart:35-56`
**Issue:** `assignMedium` and `assignSmall` always append to the existing list without checking whether the item is already assigned. A user can add the same task five times to the medium slot. The `remove(id)` method removes ALL occurrences where `i.id == itemId`, which partially papers over the issue but the duplicate display between assign and remove is a logic error.

**Fix:** Guard against duplicates before appending:
```dart
void assignMedium(Item item) {
  if (state.mediumTasks.any((i) => i.id == item.id)) return;
  final updated = [...state.mediumTasks, item];
  // ...
}
```

---

### MR-04: Recurrence rule frozen to original `dueDate.day` when date changes in form

**File:** `lib/presentation/tasks/screens/task_form_screen.dart:347-350`
**Issue:** The `FREQ=MONTHLY;BYMONTHDAY=...` radio tile hardcodes `_dueDate!.day` at widget build time:
```dart
value: 'FREQ=MONTHLY;BYMONTHDAY=${_dueDate!.day}',
```
The RadioListTile `value` is evaluated once during `build`. If the user first selects the monthly recurrence, then changes the due date to a different day, the recurrence rule stored in `_recurrenceRule` still refers to the original day, not the newly selected one. There is no mechanism to sync the rule when `_dueDate` changes.

**Fix:** Clear `_recurrenceRule` whenever `_dueDate` changes, forcing the user to re-select recurrence after picking a new date:
```dart
if (picked != null) {
  setState(() {
    _dueDate = picked;
    // Reset recurrence rule so the monthly value reflects the new day.
    if (_recurrenceRule != null && _recurrenceRule!.startsWith('FREQ=MONTHLY')) {
      _recurrenceRule = null;
    }
  });
}
```

---

### MR-05: `_nextMonthly` month overflow produces wrong `nextMonth` for January

**File:** `lib/infrastructure/tasks/recurrence_engine_impl.dart:82-84`
**Issue:** The computation for `nextMonth` when `from.month == 12`:
```dart
final nextMonth = from.month == 12
    ? DateTime(from.year + 1)
    : DateTime(from.year, from.month + 1);
```
`DateTime(from.year + 1)` with no month argument defaults to January (month 1, day 1). This is correct. However, `daysInNextMonth` is then computed as:
```dart
DateTime(nextMonth.year, nextMonth.month + 1, 0).day
```
When `nextMonth.month` is 1 (January), `nextMonth.month + 1` is 2, so this correctly gives 31. This part is safe. But the issue is that `nextMonth` for `month == 12` includes `day = 1` while for other months it uses `DateTime(from.year, from.month + 1)` which also defaults to `day = 1`. This is consistent and the overflow clamping is correct. The real edge case is that the `from` time-of-day components (`from.hour`, `from.minute`, `from.second`) are preserved but `from.millisecond` and `from.microsecond` are silently dropped, creating a subtle precision loss for any `DateTime` that carries sub-second components.

**Fix:** Preserve full sub-second precision:
```dart
return DateTime(
  nextMonth.year, nextMonth.month, clampedDay,
  from.hour, from.minute, from.second,
  from.millisecond, from.microsecond,
);
```
Apply the same fix to the `yearly` branch in `nextOccurrence` and `_nextWeekly`.

---

### MR-06: `TaskFormScreen` comment numbers are wrong — both switches say "8."

**File:** `lib/presentation/tasks/screens/task_form_screen.dart:362` and `lib/presentation/tasks/screens/task_form_screen.dart:369`
**Issue:** Both the Urgent and Important `SwitchListTile` sections are labeled `// 8.` in comments. The Important switch should be `// 9.` and all subsequent section comments are off by one. Minor but misleading when reading the file.

**Fix:** Re-number `// 8. Important` → `// 9. Important`, `// 9. Size` → `// 10. Size`, etc.

---

## Low Severity

### LR-01: `TaskCard` delete tooltip is a hardcoded English string

**File:** `lib/presentation/tasks/widgets/task_card.dart:110`
**Issue:** `tooltip: 'Delete'` is a hardcoded English string. The project uses PT-BR as the primary locale, and all other user-visible strings go through `AppLocalizations`. This string will not be translated.

**Fix:**
```dart
tooltip: AppLocalizations.of(context).deleteTask,
```
Add the `deleteTask` key to both ARB files.

---

### LR-02: `SlotSection` remove button tooltip is hardcoded English

**File:** `lib/presentation/tasks/widgets/slot_section.dart:86`
**Issue:** `tooltip: 'Remove'` is a hardcoded English string, same issue as LR-01.

**Fix:** Use `AppLocalizations.of(context).removeTask` or equivalent l10n key.

---

### LR-03: `GtdFilterScreen` accesses GetIt directly — bypasses DI injection

**File:** `lib/presentation/tasks/screens/gtd_filter_screen.dart:39`
**Issue:** `final repo = GetIt.instance<ItemRepository>();` accesses the service locator directly inside a widget method. The project convention threads dependencies through the widget tree (via `BlocProvider`, constructor, or route arguments). Direct `GetIt.instance` calls in UI code are a DI anti-pattern that makes the screen untestable in isolation and couples presentation to infrastructure.

**Fix:** The `ItemRepository` instance is already accessible through the `TaskListCubit`'s data path. Either pass the repository as a constructor parameter to the screen, or expose a `loadGtdContexts` method on `TaskListCubit` that returns the list and emits a state the screen can react to.

---

### LR-04: `ProjectScreen._showAddSubtaskSheet` reads `context` after sheet builder

**File:** `lib/presentation/tasks/screens/project_screen.dart:59`
**Issue:** Inside the `showModalBottomSheet` builder, `context.read<ProjectCubit>()` is called on the outer screen `context` (captured via closure), not on the `sheetContext`. While this works because the outer context is still mounted, it is a subtle Flutter anti-pattern — if the outer widget is removed from the tree while the sheet is open, this will throw a `ProviderNotFoundException`. The correct approach is to pass the cubit value into the sheet explicitly.

**Fix:**
```dart
showModalBottomSheet<void>(
  context: context,
  builder: (sheetContext) {
    return BlocProvider.value(
      value: context.read<ProjectCubit>(),
      child: _AddSubtaskSheet(
        projectId: widget.projectId,
        l10n: l10n,
      ),
    );
  },
);
```

---

## Info

### IN-01: `TaskListCubit` emits `TaskListLoading` state but never transitions to it

**File:** `lib/application/tasks/task_list/task_list_cubit.dart`
**Issue:** `TaskListLoading` is defined in `task_list_state.dart` and the `builder` in `TaskListScreen` renders a spinner for it. However, `TaskListCubit` never emits `TaskListLoading` — `_reload()` goes directly from `TaskListInitial` or `TaskListLoaded` to the new `TaskListLoaded`/`TaskListError` without an intermediate loading state. This means the spinner on the loading state can never appear, making `TaskListLoading` dead code.

**Suggestion:** Either emit `TaskListLoading()` at the top of `_reload()` before the async query, or remove `TaskListLoading` from the state hierarchy and the switch cases if the silent-reload UX is intentional.

---

### IN-02: `RecurrenceEngine` field unused — suppressed with `ignore` comment

**File:** `lib/infrastructure/tasks/item_repository_impl.dart:25-26`
**Issue:** `_recurrenceEngine` is injected but suppressed with `// ignore: unused_field`. The recurring task completion is stubbed to `TaskListCubit.completeItem` (application layer), but the `ItemRepositoryImpl` holds a reference it doesn't use. This leaks infrastructure concern into the repository.

**Suggestion:** Remove `_recurrenceEngine` from `ItemRepositoryImpl` constructor and inject it only where it is consumed (`TaskListCubit`). The cubit already has direct access to `RecurrenceEngine`.

---

### IN-03: `item.dart` documents the `copyWith` null-clearing limitation but offers no workaround in the class

**File:** `lib/domain/tasks/item.dart:119-124`
**Issue:** The existing comment correctly documents the limitation but then directs callers to "use `ItemRepository` directly (Isar write)" as the workaround for clearing nullable fields. This is an abstraction leak — the domain entity is telling consumers to bypass it and go directly to the data layer for a routine use-case (restoring an item). This will cause correctness bugs if any presenter tries to clear a field through `copyWith` without reading the caveat.

**Suggestion:** Address via HR-04 fix (sentinel pattern) or add `clearXxx` factory methods. Remove the comment pointing to direct Isar writes as a workaround.

---

_Reviewed: 2026-04-15T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
