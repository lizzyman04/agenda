---
phase: 02
slug: task-core
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-13
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + bloc_test + mocktail |
| **Config file** | none — framework already installed (Phase 1) |
| **Quick run command** | `flutter test test/domain/tasks/ test/data/tasks/ test/application/tasks/ --no-pub` |
| **Full suite command** | `flutter test --no-pub` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick command targeting the affected layer
- **After every plan wave:** Run `flutter test --no-pub`
- **Before `/gsd-verify-work`:** Full suite must be green + `flutter analyze --no-fatal-infos` exits 0
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | TASK-01,02,03 | — | N/A | unit | `flutter test test/domain/tasks/item_test.dart --no-pub` | ❌ W0 | ⬜ pending |
| 02-01-02 | 01 | 1 | TASK-07 | — | EisenhowerQuadrant never persisted | unit | `flutter test test/domain/tasks/item_test.dart --no-pub` | ❌ W0 | ⬜ pending |
| 02-01-03 | 01 | 1 | TASK-08 | — | N/A | unit | `flutter test test/domain/tasks/item_test.dart --no-pub` | ❌ W0 | ⬜ pending |
| 02-01-04 | 01 | 1 | TASK-09 | — | N/A | unit | `flutter test test/domain/tasks/item_test.dart --no-pub` | ❌ W0 | ⬜ pending |
| 02-01-05 | 01 | 1 | TASK-10 | — | Recurrence creates new Item; original immutable | unit | `flutter test test/domain/tasks/recurrence_engine_test.dart --no-pub` | ❌ W0 | ⬜ pending |
| 02-02-01 | 02 | 1 | TASK-01,02,03 | — | deletedAt filter on all queries | unit | `flutter test test/data/tasks/ --no-pub` | ❌ W0 | ⬜ pending |
| 02-02-02 | 02 | 1 | TASK-05 | — | Soft delete excludes from all queries | unit | `flutter test test/data/tasks/item_repository_impl_test.dart --no-pub` | ❌ W0 | ⬜ pending |
| 02-02-03 | 02 | 2 | DATA-01 | — | No network calls; all writes go to Isar | unit | `flutter test test/data/tasks/ --no-pub` | ❌ W0 | ⬜ pending |
| 02-03-01 | 03 | 1 | TASK-01,02,04,06 | — | N/A | unit | `flutter test test/application/tasks/task_list_cubit_test.dart --no-pub` | ❌ W0 | ⬜ pending |
| 02-03-02 | 03 | 1 | TASK-05 | — | Undo timer cancelled on restore | unit | `flutter test test/application/tasks/task_list_cubit_test.dart --no-pub` | ❌ W0 | ⬜ pending |
| 02-03-03 | 03 | 1 | TASK-08 | — | DayPlannerCubit enforces 1-3-5 soft limit | unit | `flutter test test/application/tasks/day_planner_cubit_test.dart --no-pub` | ❌ W0 | ⬜ pending |
| 02-03-04 | 03 | 2 | TASK-11,12 | — | N/A | unit | `flutter test test/application/tasks/ --no-pub` | ❌ W0 | ⬜ pending |
| 02-04-01 | 04 | 1 | TASK-01,03 | — | N/A | widget | `flutter test test/presentation/tasks/ --no-pub` | ❌ W0 | ⬜ pending |
| 02-04-02 | 04 | 1 | TASK-07 | — | N/A | widget | `flutter test test/presentation/tasks/eisenhower_board_test.dart --no-pub` | ❌ W0 | ⬜ pending |
| 02-04-03 | 04 | 1 | TASK-08 | — | Slot constraint shown as warning not hard block | widget | `flutter test test/presentation/tasks/day_planner_test.dart --no-pub` | ❌ W0 | ⬜ pending |
| 02-05-01 | 05 | 1 | TASK-09 | — | N/A | widget | `flutter test test/presentation/tasks/gtd_test.dart --no-pub` | ❌ W0 | ⬜ pending |
| 02-05-02 | 05 | 1 | TASK-11 | — | N/A | unit | `flutter test test/application/tasks/task_list_cubit_test.dart --no-pub` | ❌ W0 | ⬜ pending |
| 02-05-03 | 05 | 1 | TASK-12 | — | N/A | unit | `flutter test test/application/tasks/task_list_cubit_test.dart --no-pub` | ❌ W0 | ⬜ pending |
| 02-05-04 | 05 | 2 | TASK-10 | — | Completed recurring task generates new Item; original deletedAt set | unit | `flutter test test/domain/tasks/recurrence_engine_test.dart --no-pub` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/domain/tasks/item_test.dart` — Item entity, Priority enum, EisenhowerQuadrant getter, sizeCategory
- [ ] `test/domain/tasks/recurrence_engine_test.dart` — RRULE parsing + next-date generation for DAILY/WEEKLY/MONTHLY/YEARLY
- [ ] `test/data/tasks/item_repository_impl_test.dart` — CRUD, soft delete, restore, parent/child queries
- [ ] `test/application/tasks/task_list_cubit_test.dart` — loading, search, filter, undo timer states
- [ ] `test/application/tasks/project_cubit_test.dart` — project CRUD, subtask rollup computation
- [ ] `test/application/tasks/day_planner_cubit_test.dart` — slot assignment, 1-3-5 constraint, soft warning
- [ ] `test/presentation/tasks/task_list_screen_test.dart` — task list renders, empty state, delete+undo snackbar
- [ ] `test/presentation/tasks/eisenhower_board_test.dart` — 2×2 grid renders tasks in correct quadrants
- [ ] `test/presentation/tasks/day_planner_test.dart` — slot UI, warning display at limit
- [ ] `test/presentation/tasks/gtd_test.dart` — GTD tag display and filter
- [ ] `test/presentation/tasks/task_form_test.dart` — create/edit form fields, validation

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Undo snackbar visible for 5 seconds on real device | TASK-05 | Timer behavior in widget tests is not real-time | Delete a task on device; observe snackbar; tap undo; confirm task restored |
| Eisenhower board touch targets usable on small screen | TASK-07 | Layout depends on physical screen density | Open board on Infinix X6831; tap each quadrant; verify task moves |
| 1-3-5 soft warning appears at limit | TASK-08 | Requires interactive state sequence | Add 1 big task; try to add 2nd big; confirm warning shown, task still saves |
| Recurring task regenerated after completion | TASK-10 | Sequence: complete task → observe new task created | Complete a WEEKLY recurring task; verify new instance appears with next due date |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 20s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
