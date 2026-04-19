---
phase: "02"
phase_name: task-core
asvs_level: L1
threats_total: 7
threats_closed: 7
threats_open: 0
status: secured
---

# Phase 02 (task-core): Security Threat Verification

**Audited:** 2026-04-19
**ASVS Level:** L1
**Block On:** medium

## Trust Boundaries

- User input → TaskListCubit.search() → ItemRepository.searchByTitle() → ItemDao (typed Isar API)
- UI form → TaskFormScreen._save() → TaskListCubit.createItem/updateItem() → ItemRepositoryImpl → ItemDao
- Domain entities are pure Dart — no network, no filesystem, no external system access
- All data stored locally in Isar on-device database (no cloud, no sync)

## Threat Register

| Threat ID | Description | Severity | Disposition | Status | Evidence |
|-----------|-------------|----------|-------------|--------|----------|
| T-02-01 | Isar query injection via user search string | medium | mitigate | CLOSED | lib/data/tasks/item_dao.dart:37-43 — `.titleContains(query, caseSensitive: false)` used; no string interpolation present |
| T-02-02 | Unbounded Isar result sets cause OOM | medium | mitigate | CLOSED | lib/data/tasks/item_dao.dart: findByType:26, findSubtasks:34, searchByTitle:42, filterItems:107 — `.limit(500)` applied before `.findAll()` on all four collection queries |
| T-02-03 | moneyInfo amount floating-point drift | low | accept | CLOSED | Accepted risk — no implementation verification required |
| T-02-04 | parent_id cycle (subtask pointing to subtask) | medium | mitigate | CLOSED | lib/infrastructure/tasks/item_repository_impl.dart:31-48 — createItem validates `parent.type != ItemType.project` and returns `ValidationFailure` before save |
| T-02-05 | Soft-deleted items visible via stale Cubit state | medium | mitigate | CLOSED | lib/application/tasks/task_list/task_list_cubit.dart:60-82 — softDelete immediately emits `TaskListWithPendingUndo` with deleted item removed from list; watchChanges() subscription at line 37 triggers `_reload()` on every Isar collection change |
| T-02-06 | Timer leak if Cubit closed before undo window expires | low | mitigate | CLOSED | lib/application/tasks/task_list/task_list_cubit.dart:211-215 — `close()` override cancels both `_undoTimer` and `_watchSubscription` before calling `super.close()` |
| T-02-07 | Form submits with empty title due to missing validator | low | mitigate | CLOSED | lib/presentation/tasks/screens/task_form_screen.dart:124 — `_formKey.currentState!.validate()` guard at entry of `_save()`; TextFormField validator at lines 228-232 rejects null/empty/whitespace-only titles |

## Notes on Verification

### T-02-06 Cubit Name Discrepancy

The threat register and 02-02-PLAN.md threat model both cite `DayPlannerCubit.close()` as the location of the timer/subscription cancellation mitigation. However, `DayPlannerCubit` is a pure in-memory state machine with no timers and no stream subscriptions — it has no `close()` override and requires none. The undo timer (`_undoTimer`) and watch subscription (`_watchSubscription`) are fields of `TaskListCubit`, and `TaskListCubit.close()` correctly cancels both. The mitigation is implemented correctly; the threat register contained an incorrect cubit name. No gap exists.

## Accepted Risks

| Threat ID | Description | Rationale |
|-----------|-------------|-----------|
| T-02-03 | moneyInfo floating-point drift | Acceptable for Phase 2; display layer uses .toStringAsFixed(2); full fixed-point accounting deferred to Phase 3 |

## Unregistered Threat Flags

None. All SUMMARY.md `## Threat Flags` sections across plans 01–05 reported no new threat surface beyond the registered threat model.

## Audit Trail

### Security Audit 2026-04-19

| Metric | Count |
|--------|-------|
| Threats found | 7 |
| Closed | 7 |
| Open | 0 |
| Unregistered flags | 0 |
