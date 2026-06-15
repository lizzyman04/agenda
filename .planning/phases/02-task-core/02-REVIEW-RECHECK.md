---
phase: 02-task-core
reviewed: 2026-06-15T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - lib/infrastructure/tasks/item_repository_impl.dart
  - lib/presentation/tasks/screens/task_form_screen.dart
  - lib/presentation/tasks/screens/project_screen.dart
  - test/infrastructure/tasks/item_repository_impl_test.dart
  - test/presentation/tasks/task_form_test.dart
  - test/widget_test.dart
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: resolved
post_review_fixes:
  - "WR-01 (warning) — FIXED in 2dfbe7b: createItem/updateItem now return bool; TaskFormScreen branches on the returned outcome instead of post-await shared state. Four cubit regression tests added. Full suite green (206/206)."
deferred_followups:
  - "WR-02 (warning): GTD-guide 'cancel task' branches pop silently — debatable UX (user explicitly cancelled); deferred as polish, out of CR-01/WR-03/WR-04 scope."
  - "IN-01 (info): dead toDomain mapper stub in subtask updateItem test."
  - "IN-02 (info): pre-existing empty catch blocks in _loadFinanceLinks; prefer firstOrNull."
---

# Phase 02: Code Review Report (Recheck)

**Reviewed:** 2026-06-15
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Re-review to confirm resolution of three prior Phase 02 findings (CR-01, WR-03, WR-04) and to surface any defects introduced by the fixes.

**Resolution verdict:**

- **CR-01 (critical) — RESOLVED.** All three required fixes are present and correct:
  - (a) `ItemRepositoryImpl.updateItem` now guards `item.type != ItemType.subtask && item.parentId != null` and returns `ValidationFailure` before any DAO write (`item_repository_impl.dart:96-100`).
  - (b) `TaskFormScreen` type-locks subtask on edit: `type: widget.item!.type == ItemType.subtask ? widget.item!.type : _itemType` (`task_form_screen.dart:281-283`). The SegmentedButton only offers task/project, so a subtask edited cannot be re-typed to project, and even if `_itemType` drifts it is ignored.
  - (c) `TaskFormScreen` clears the stale `parentId` for non-subtasks on save: `parentId: widget.item!.type == ItemType.subtask ? widget.item!.parentId : null` (`task_form_screen.dart:288-289`). This recovers legacy invalid rows and keeps the repo guard from rejecting otherwise-valid edits. The repo test suite covers all three branches (subtask+parentId -> Success, task+parentId -> Err, task+null -> Success).

- **WR-03 (warning) — RESOLVED.** The add-subtask sheet is now `_AddSubtaskSheet`, a `StatefulWidget` whose `_AddSubtaskSheetState` owns `_controller` and disposes it in `dispose()` (`project_screen.dart:125-138`). No controller leak.

- **WR-04 (warning) — PARTIALLY RESOLVED.** Both save paths now inspect post-await state and surface a SnackBar instead of blindly popping. The `ProjectScreen` path is fully correct because `addSubtask` emits a fresh `ProjectLoaded` on success. The `TaskFormScreen` path has a residual correctness gap (see WR-01 below): the shared, app-scoped `TaskListCubit` emits nothing synchronously on a successful create/update, so a stale `TaskListError` from a prior operation can cause a successful save to be misreported as a failure.

Two info-level observations are also recorded.

## Warnings

### WR-01: Stale `TaskListError` can mask a successful save in TaskFormScreen

**File:** `lib/presentation/tasks/screens/task_form_screen.dart:308-352`
**Issue:** The WR-04 fix reads the cubit state synchronously after awaiting the write:

```dart
await context.read<TaskListCubit>().updateItem(saved);
if (!mounted) return;
final updateState = context.read<TaskListCubit>().state;
if (updateState is TaskListError) { ...show SnackBar...; return; }
```

`TaskListCubit.updateItem`/`createItem` (`task_list_cubit.dart:103-118`) emit `TaskListError` **only** on failure; on success they emit nothing and rely on the async `watchChanges()` stream to fire `_reload()` later. The `TaskListCubit` is app-scoped and shared (registered in `app.dart:64-65`), so when the form opens, the cubit may already hold a `TaskListError` left over from an earlier failed operation (e.g. a failed delete on the list screen) or never have reached a loaded state. In that case a fully successful save is read back as `TaskListError`: the screen shows a spurious error SnackBar and refuses to pop, even though the write succeeded. This is the same class of "state not surfaced correctly" defect WR-04 set out to fix, now inverted into a false negative.

The `ProjectScreen` sibling path does not have this problem because `ProjectCubit.addSubtask` emits a fresh `ProjectLoaded` on success (`project_cubit.dart:54-57`), overwriting any prior error state synchronously within the awaited call.

**Fix:** Make success unambiguous rather than inferring it from residual cubit state. Preferred: have the cubit methods return the `Result` (or a bool) so the screen can branch on the actual outcome of *this* operation:

```dart
// task_list_cubit.dart
Future<bool> updateItem(Item item) async {
  final result = await _repository.updateItem(item);
  if (result is Err<Item>) {
    emit(TaskListError(result.failure));
    return false;
  }
  return true;
}
```

```dart
// task_form_screen.dart
final ok = await context.read<TaskListCubit>().updateItem(saved);
if (!mounted) return;
if (!ok) {
  final s = context.read<TaskListCubit>().state;
  final msg = s is TaskListError ? s.failure.message : l10n.genericError;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  return;
}
Navigator.of(context).pop();
```

This removes the dependency on stale shared state and is robust regardless of what the cubit was doing before the form opened.

### WR-02: GTD "cancel task" branches discard input without surfacing any feedback

**File:** `lib/presentation/tasks/screens/task_form_screen.dart:1322, 1363`
**Issue:** In the GTD guide sheet, `_GtdNode.q5bCancelTask` and `_GtdNode.q7bCancelTask` call `Navigator.of(context).pop()` with no result and no SnackBar, whereas every other terminal branch uses `_endWithSnackbar(...)` to tell the user what happened. From the user's perspective the sheet silently vanishes mid-flow with no confirmation that the task was intentionally discarded. This is the same "operation completes without surfacing its outcome" gap that motivated WR-04, in an adjacent code path that was not part of the original fix scope.
**Fix:** Route both cancel branches through `_endWithSnackbar(_l.gtdTaskCancelledMessage)` (add the l10n key) so the dismissal is acknowledged, consistent with the other terminal nodes.

## Info

### IN-01: Unused mapper stub in updateItem subtask test

**File:** `test/infrastructure/tasks/item_repository_impl_test.dart:174`
**Issue:** The test "returns Success when type is subtask and parentId is non-null" stubs `when(() => mockMapper.toDomain(any())).thenReturn(savedItem)`, but `ItemRepositoryImpl.updateItem` returns `Success<Item>(updated)` (the locally built domain object, `item_repository_impl.dart:104`) and never calls `toDomain`. The stub is dead. Harmless, but it falsely implies a mapping round-trip is exercised.
**Fix:** Remove the `toDomain` stub (and `savedItem`) from this test, or assert the returned value's fields to make the intent explicit.

### IN-02: Empty `catch (_) {}` blocks in finance-link lookups

**File:** `lib/presentation/tasks/screens/task_form_screen.dart:100, 115`
**Issue:** `_loadFinanceLinks` wraps `firstWhere` (which throws when no element matches) in `try { ... } catch (_) {}`, silently swallowing the lookup miss. The behaviour is acceptable (a linked goal/debt that no longer exists simply shows no title), but a bare empty catch hides any unrelated error too and reads as an anti-pattern. Pre-existing; not introduced by the CR-01/WR-03/WR-04 fixes.
**Fix:** Replace with a non-throwing lookup, e.g. `goals.where((g) => g.id == _linkedGoalId).firstOrNull?.title`, eliminating the try/catch entirely.

---

_Reviewed: 2026-06-15_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
