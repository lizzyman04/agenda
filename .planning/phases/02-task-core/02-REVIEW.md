---
phase: 02-task-core
reviewed: 2026-06-14T16:54:06Z
depth: standard
files_reviewed: 50
files_reviewed_list:
  - lib/application/tasks/day_planner/day_planner_cubit.dart
  - lib/application/tasks/day_planner/day_planner_state.dart
  - lib/application/tasks/project/project_cubit.dart
  - lib/application/tasks/project/project_state.dart
  - lib/application/tasks/task_list/task_list_cubit.dart
  - lib/application/tasks/task_list/task_list_filter.dart
  - lib/application/tasks/task_list/task_list_state.dart
  - lib/config/di/tasks_module.dart
  - lib/config/l10n/app_en.arb
  - lib/config/l10n/app_pt.arb
  - lib/config/l10n/app_pt_BR.arb
  - lib/core/config/app_config.dart
  - lib/data/database/migration_runner.dart
  - lib/data/tasks/item_dao.dart
  - lib/data/tasks/item_mapper.dart
  - lib/data/tasks/item_model.dart
  - lib/domain/tasks/eisenhower_quadrant.dart
  - lib/domain/tasks/item.dart
  - lib/domain/tasks/item_repository.dart
  - lib/domain/tasks/item_type.dart
  - lib/domain/tasks/priority.dart
  - lib/domain/tasks/recurrence_engine.dart
  - lib/domain/tasks/size_category.dart
  - lib/infrastructure/tasks/item_repository_impl.dart
  - lib/infrastructure/tasks/recurrence_engine_impl.dart
  - lib/main.dart
  - lib/presentation/tasks/screens/day_planner_screen.dart
  - lib/presentation/tasks/screens/eisenhower_screen.dart
  - lib/presentation/tasks/screens/gtd_filter_screen.dart
  - lib/presentation/tasks/screens/project_screen.dart
  - lib/presentation/tasks/screens/task_form_screen.dart
  - lib/presentation/tasks/screens/task_list_screen.dart
  - lib/presentation/tasks/widgets/gtd_chip.dart
  - lib/presentation/tasks/widgets/quadrant_card.dart
  - lib/presentation/tasks/widgets/slot_section.dart
  - lib/presentation/tasks/widgets/task_card.dart
  - test/application/tasks/day_planner_cubit_test.dart
  - test/application/tasks/project_cubit_test.dart
  - test/application/tasks/task_list_cubit_test.dart
  - test/data/tasks/item_dao_test.dart
  - test/data/tasks/item_mapper_test.dart
  - test/domain/tasks/eisenhower_quadrant_test.dart
  - test/domain/tasks/item_test.dart
  - test/domain/tasks/recurrence_engine_test.dart
  - test/infrastructure/tasks/item_repository_impl_test.dart
  - test/infrastructure/tasks/recurrence_engine_impl_test.dart
  - test/presentation/tasks/day_planner_test.dart
  - test/presentation/tasks/eisenhower_board_test.dart
  - test/presentation/tasks/gtd_test.dart
  - test/presentation/tasks/task_form_test.dart
  - test/presentation/tasks/task_list_screen_test.dart
findings:
  critical: 1
  warning: 9
  info: 6
  total: 16
status: issues_found
---

# Phase 02: Code Review Report

**Reviewed:** 2026-06-14T16:54:06Z
**Depth:** standard
**Files Reviewed:** 50
**Status:** issues_found

## Summary

Phase 02 implements the task core: domain entities (Item, recurrence, Eisenhower),
the Isar data layer (model/mapper/DAO), the repository, three Cubits, and the
presentation screens. The layering is clean and the privacy constraint is upheld —
no network, analytics, crash-reporting, or external I/O appears anywhere in the
task code.

Note: a previous REVIEW.md existed for an older revision of this phase; many of its
findings (the unsafe `as` cast in `createItem`, the fire-and-forget save calls,
`copyWith` being unable to clear nullable fields, the `getDistinctGtdContexts`
full-table scan, and unbounded day-planner duplicates) have since been fixed in the
current code and are not re-reported. This review reflects the code as it stands now.

The remaining blocker is a data-integrity bug: editing a subtask through the task
form flips its `type` from `subtask` to `task` while keeping its `parentId`,
producing a row that violates the create-time invariant and corrupts the
project/subtask relationship. Warnings cover lost error feedback on save paths
(cubits emit error states but the UI pops/closes anyway), a recurrence drift bug on
month-end "same day" rules, a state-machine race between the soft-delete pending-undo
state and the `watchChanges` auto-reload, a non-atomic migration runner, and — most
importantly for confidence in this phase — `ItemDao` (the file holding every query)
shipping with an empty test stub, plus `Item.copyWith` (subtle sentinel semantics)
being untested.

## Critical Issues

### CR-01: Editing a subtask flips its type to `task` while keeping `parentId`, corrupting the project relationship

**File:** `lib/presentation/tasks/screens/task_form_screen.dart:68-69, 275-300`
**Issue:** In edit mode `_itemType` is initialized as
`item?.type == ItemType.project ? ItemType.project : ItemType.task` (line 68-69),
which collapses `ItemType.subtask` to `ItemType.task`. `_save()` then writes
`type: _itemType` via `widget.item!.copyWith(...)`. `copyWith` keeps the original
`parentId` (the arg is omitted), so saving an edited subtask produces a row with
`type == task` **and** a non-null `parentId` pointing at a project.

That state is explicitly rejected on the create path
(`ItemRepositoryImpl.createItem` enforces "parentId must reference a project" only
for items whose parent is validated, T-02-04), but `updateItem` performs **no**
type/parentId consistency check, so the corruption persists. Downstream,
`getSubtasks`/`getSubtaskCounts` filter purely on `parentId` (DAO lines 29-35,
112-126) regardless of `type`, so the now-"task" still counts toward the project
rollup while also appearing in the main task list and Eisenhower board. The
SegmentedButton only offers task/project, so the original `subtask` type can never
be restored through the UI. Data integrity is silently broken by a normal edit.

**Fix:** Preserve the discriminator on edit and add a guard on the update path:
```dart
// initState — keep the real type instead of collapsing subtask -> task:
_itemType = item?.type ?? ItemType.task;

// _save() — never let a subtask's type/parent change via this generic form:
if (_isEditing) {
  saved = widget.item!.copyWith(
    title: _titleController.text.trim(),
    type: widget.item!.type == ItemType.subtask
        ? widget.item!.type      // lock subtask type
        : _itemType,             // task <-> project toggle only for non-subtasks
    // parentId intentionally omitted so it is preserved
    // ...rest unchanged...
  );
}
```
Also mirror the `createItem` parentId/type validation inside
`ItemRepositoryImpl.updateItem` so an inconsistent row can never be written.

## Warnings

### WR-01: Recurrence drifts permanently for month-end "same day" rules

**File:** `lib/infrastructure/tasks/recurrence_engine_impl.dart:81-101`
**Issue:** `_nextMonthly` uses `day = byMonthDay ?? from.day` and clamps to the
target month's length. In the null-`byMonthDay` "same day as seed" mode, a task
seeded on Jan 31 yields Feb 28; the next occurrence is then computed from Feb 28 and
produces Mar 28 — not Mar 31 — because the clamped day becomes the new `from.day`.
The monthly anchor is irreversibly lost after the first short month.
**Fix:** Anchor the day-of-month on the rule, not the rolling `from.day`. Either
require `byMonthDay` for monthly recurrence (the form already emits
`FREQ=MONTHLY;BYMONTHDAY=${_dueDate!.day}`, so production rules carry it), or carry
the seed day so the engine re-expands to the full day after a short month. At
minimum, add a Jan-31 -> Feb -> Mar test to pin the intended behaviour.

### WR-02: `softDelete` pending-undo state is immediately overwritten by the watchChanges reload

**File:** `lib/application/tasks/task_list/task_list_cubit.dart:36-41, 60-82`
**Issue:** `softDelete` performs an Isar `writeTxn`, which fires the
`watchChanges()` stream the cubit subscribed to in `start()`. The listener calls
`_reload()`, emitting `TaskListLoaded` and replacing the just-emitted
`TaskListWithPendingUndo` before the 5 s window. The documented state machine
("`TaskListWithPendingUndo` persists for `undoSnackbarDuration`, then transitions to
`TaskListLoaded`") therefore does not hold — the transition is effectively instant
and racy. The undo SnackBar still works only because the screen captured
`deletedItemId` in the listener closure; any other consumer of the pending state
will misbehave.
**Fix:** Hold the auto-reload while an undo is pending:
```dart
Future<void> _reload() async {
  if (isClosed) return;
  if (_pendingUndoId != null) return; // suppress during undo window
  // ...existing reload...
}
```
Set `_pendingUndoId` in `softDelete`, clear it in the timer callback and in
`restoreItem`.

### WR-03: TaskFormScreen swallows repository errors — user sees a successful-looking pop on failed save

**File:** `lib/presentation/tasks/screens/task_form_screen.dart:300-332`
**Issue:** `_save()` awaits `updateItem`/`createItem` then unconditionally pops. If
the cubit emits `TaskListError` (e.g. the `createItem` parentId validation fails, or
a DB error), the form pops as if the save succeeded and the error is never shown.
The user believes the task was saved.
**Fix:** Have the cubit methods return a `Result`/bool, or inspect the cubit state
after awaiting and only pop on success:
```dart
await context.read<TaskListCubit>().createItem(saved);
if (!mounted) return;
final state = context.read<TaskListCubit>().state;
if (state is TaskListError) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(state.failure.message)));
  return;
}
Navigator.of(context).pop();
```

### WR-04: ProjectScreen add-subtask sheet leaks its controller and drops errors

**File:** `lib/presentation/tasks/screens/project_screen.dart:28-73`
**Issue:** The `TextEditingController` created at line 30 is never disposed (leak on
every sheet open). The button pops the sheet whether or not a subtask was added
(empty input is silently ignored via `if (title.isNotEmpty)`), and `addSubtask` can
emit `ProjectError` which is never surfaced — the user just sees the sheet close
with no new subtask and no feedback.
**Fix:** Move the sheet to a small `StatefulWidget` that disposes its controller,
add a validator/inline error for empty titles, and surface `ProjectError` via
SnackBar before popping.

### WR-05: `updateItem` returns the in-memory item instead of re-reading the persisted row

**File:** `lib/infrastructure/tasks/item_repository_impl.dart:93-103`
**Issue:** Unlike `createItem`/`softDelete`/`restoreItem`, which re-read via
`findById` after writing, `updateItem` returns the locally-built `updated` object
without confirming the write or reading back any DB-side state. If `_dao.save`
silently no-ops, the caller still receives `Success` with stale-but-plausible data.
The contract is inconsistent across the repository and can mask write failures.
**Fix:** Re-read after save for parity:
```dart
final id = await _dao.save(model);
final saved = await _dao.findById(id);
if (saved == null) {
  return Err<Item>(DatabaseFailure('Item ${item.id} not found after update'));
}
return Success<Item>(_mapper.toDomain(saved));
```

### WR-06: ItemDao has zero test coverage — only an empty group stub ships

**File:** `test/data/tasks/item_dao_test.dart:1-6`
**Issue:** The DAO holds all query logic this phase rests on (`deletedAtIsNull`
filtering, the 500-row limit, the multi-criteria `filterItems` `.optional()` chain
with three date-range branches, `searchByTitle`, soft-delete/restore,
`findDistinctGtdContexts`), yet the test file is `group('ItemDao', () {});` with no
tests. None of the T-02-01/T-02-02 guarantees (no string interpolation,
deletedAt-first, limit(500)) are verified, and the date-range branching is exactly
the kind of conditional logic that regresses silently.
**Fix:** Add integration tests against a temp Isar instance covering: soft-deleted
rows excluded, limit enforced, each `filterItems` date branch (`from && to`,
`from only`, `to only`), `searchByTitle` case-insensitivity, and
`findDistinctGtdContexts` distinctness + sort.

### WR-07: `Item.copyWith` sentinel logic is untested despite subtle semantics

**File:** `lib/domain/tasks/item.dart:146-218` (test:
`test/domain/tasks/item_test.dart`)
**Issue:** `copyWith` uses the `clearField` sentinel to distinguish "omitted" from
"explicitly null" across ~12 nullable fields, with `as String?`/`as int?`/
`as DateTime?` casts. `item_test.dart` covers defaults and the Eisenhower getter but
never exercises `copyWith` — not the keep-existing path, the explicit-null path, nor
the casts. Both CR-01 and WR-03 flow through `copyWith`, making this a high-risk
untested surface.
**Fix:** Add tests: `copyWith()` keeps each nullable field; `copyWith(field:
clearField)` nulls it; `copyWith(field: value)` sets it.

### WR-08: `completeItem` next-occurrence copy omits fields and ignores create errors

**File:** `lib/application/tasks/task_list/task_list_cubit.dart:125-170`
**Issue:** When a recurring task completes, the next occurrence is built field-by-
field (lines 144-164) and omits `linkedGoalId`/`linkedDebtId`, so a recurring task
linked to a goal/debt loses that link on every rollover. The result of
`await _repository.createItem(nextItem)` is also discarded — if creation fails, the
recurring series silently stops with no error emitted.
**Fix:** Build the next occurrence via `copyWith` so future fields are not forgotten,
and handle the create result:
```dart
final nextItem = item.copyWith(
  id: 0,
  dueDate: nextDate,
  isCompleted: false,
  completedAt: clearField,
  createdAt: now,
  updatedAt: now,
);
final created = await _repository.createItem(nextItem);
if (created is Err<Item>) emit(TaskListError(created.failure));
```

### WR-09: Migration runner is not atomic and has no error handling — a throwing migration bricks startup

**File:** `lib/data/database/migration_runner.dart:25-51`
**Issue:** `run` loops over versions, executing each migration then writing the new
version to prefs, with no try/catch. If a migration throws, it propagates out of
`IsarService.open` and prevents the app from starting, with no recovery path. The
version-bump and data-write are also separate steps: a crash between them can leave
prefs and Isar data divergent. The current v3 `_seedDefaultCategories` is saved only
by its `count > 0` idempotency guard; any future non-idempotent migration would be
unsafe under this pattern.
**Fix:** Wrap each step in try/catch and surface failures clearly; keep the
version-bump and the data write as close to atomic as Isar allows; and document that
every migration must be idempotent.

## Info

### IN-01: Duplicate localization file `app_pt.arb` generates an unused locale

**File:** `lib/config/l10n/app_pt.arb` (vs `app_pt_BR.arb`)
**Issue:** `app_pt.arb` is a key-for-key duplicate of `app_pt_BR.arb` (287 identical
keys), but `l10n.yaml` declares only `pt_BR` and `en` as supported locales with
`app_pt_BR.arb` as the template. The `pt` file produces a generated `pt`
localization the app never selects, and is a second copy to keep in sync. CLAUDE.md
specifies "PT-BR with EN toggle"; there is no plain-`pt` requirement.
**Fix:** Delete `app_pt.arb` unless a generic `pt` fallback is intended; if kept,
document why and keep it in sync.

### IN-02: `_loadFinanceLinks` uses try/catch on `firstWhere` instead of `firstWhereOrNull`

**File:** `lib/presentation/tasks/screens/task_form_screen.dart:96-100, 111-115`
**Issue:** `firstWhere((g) => g.id == _linkedGoalId)` is wrapped in `catch (_) {}` to
handle the not-found case. Empty catch blocks hide all errors, not just the expected
`StateError`.
**Fix:** Use `package:collection`'s `firstWhereOrNull` with a null check; no catch.

### IN-03: Hardcoded EN/PT-BR strings bypass the l10n pipeline

**File:** `lib/presentation/tasks/screens/task_form_screen.dart:151, 815` (and the
whole `_GtdGuideSheet`), `lib/presentation/tasks/widgets/task_card.dart:107`,
`lib/presentation/tasks/widgets/slot_section.dart:80`
**Issue:** Literals like `'Sem vínculo'`, `'8 questions to clarify & prioritize'`,
`tooltip: 'Delete'`, `tooltip: 'Remove'`, and the GTD guide's many inline strings
(`'Pergunta X de Y'`, `'Próximo →'`, `'Título'`, `'Contexto'`, the priority labels)
are not in the ARB files, so the EN toggle does not affect them and EN/PT-BR literals
are mixed.
**Fix:** Move user-facing strings into `app_*.arb` and reference via
`AppLocalizations`.

### IN-04: `app_config.dart` notification-base comment contradicts the constants

**File:** `lib/core/config/app_config.dart:27, 31-38`
**Issue:** The header comment states "Deterministic derivation: entityId * 10 +
notificationType" while the constants define per-domain bases (`taskNotificationBase
= 10`, `financeNotificationBase = 20`, `systemNotificationBase = 30`). Both cannot be
the derivation rule; this will mislead Phase 4 notification ID generation.
**Fix:** Reconcile the comment with the constants and state the exact ID formula
once.

### IN-05: Day-planner `slotLimitWarning` is cached pre-update and reset on remove — inconsistent UX

**File:** `lib/application/tasks/day_planner/day_planner_cubit.dart:21-71`
**Issue:** `slotLimitWarning` is computed from the pre-update state on each assign,
but `remove()` and the next non-overflowing assign reset it to `false`, so the global
banner can switch off while a slot is still over capacity. The per-section
`isOverCapacity` (from `areMediumSlotsFull` etc.) is the reliable signal; the global
flag is redundant and can disagree with it.
**Fix:** Derive `slotLimitWarning` from the resulting state (any slot length > its
max) rather than caching the pre-update boolean, or drop the global flag in favour of
the per-section indicator.

### IN-06: Finance-link fields documented as "always null in Phase 2" but the form writes them

**File:** `lib/domain/tasks/item.dart:119-123`,
`lib/presentation/tasks/screens/task_form_screen.dart:296-297, 323-324`
**Issue:** The domain docs say `linkedGoalId`/`linkedDebtId` are "Reserved for
Phase 3 — always null in Phase 2," yet `TaskFormScreen` loads active goals/debts and
persists these links. The documented invariant is already violated (the feature
appears intentionally pulled forward), so the comment will mislead future readers.
**Fix:** Update the doc comments to reflect that finance linkage is wired in this
phase, or gate the finance-link card behind a Phase-3 flag if it is not meant to be
live yet.

---

_Reviewed: 2026-06-14T16:54:06Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
