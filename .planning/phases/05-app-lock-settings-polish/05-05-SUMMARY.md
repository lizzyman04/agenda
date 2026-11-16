---
phase: 05-app-lock-settings-polish
plan: 05
subsystem: ui
tags: [flutter, empty-state, ux-04, l10n, shared-widgets]
status: complete

requires:
  - phase: 05-app-lock-settings-polish
    provides: "05-01 empty-state ARB strings (tasksEmptyBody, tasksEmptyCta, tasksSearchEmptyTitle, tasksSearchEmptyBody(query), gtdEmptyBody)"
provides:
  - "AppEmptyState (lib/presentation/shared/widgets/) — the shared UX-04 layout with an optional CTA"
  - "TaskListEmptyState(l10n, searchQuery, onCreate): no-tasks prompt with Adicionar tarefa CTA, and a no-search-match state"
  - "GtdFilterScreen empty state through AppEmptyState"
  - "FinanceEmptyState delegates to AppEmptyState (constructor unchanged)"
  - "New presentation/shared slice with READMEs"
affects: [settings-screen, any future list screen needing an empty state]

actuals:
  tokens: 5559
  tasks: 2
  commits: 2
plan_head_before: 17e98c64a65528156256b71c5ac2bc57a3d4982d
plan_head_after: 4daa04e4ef355b87f7b60224f7f0128876cdfb81

tech-stack:
  added: []
  patterns:
    - "Cross-slice widgets live in presentation/shared/widgets only when two or more slices use them"
    - "Slice wrappers keep their constructor and delegate build to the shared widget so visuals cannot drift"
    - "Optional CTA renders only when both label and callback are non-null"

key-files:
  created:
    - lib/presentation/shared/widgets/app_empty_state.dart
    - lib/presentation/shared/README.md
    - lib/presentation/shared/widgets/README.md
    - test/presentation/shared/app_empty_state_test.dart
  modified:
    - lib/presentation/tasks/widgets/task_list_view.dart
    - lib/presentation/tasks/screens/task_list_screen.dart
    - lib/presentation/tasks/screens/gtd_filter_screen.dart
    - lib/presentation/finance/widgets/finance_empty_state.dart
    - lib/presentation/tasks/widgets/README.md
    - lib/presentation/tasks/screens/README.md
    - lib/presentation/finance/widgets/README.md
    - test/presentation/tasks/task_list_screen_test.dart
    - test/presentation/tasks/gtd_test.dart

key-decisions:
  - "TaskListScreen stays under the 150-line cap by merging the Loaded/PendingUndo list arms into one Dart 3 or-pattern and collapsing the loading/error arms, not by extracting a builder (147 lines, no behaviour change)"
  - "FinanceEmptyState keeps its required-CTA constructor and becomes a thin delegate to AppEmptyState"

requirements-completed: [UX-04]

duration: 7min
completed: 2026-11-16
---

# Phase 5 Plan 05: Shared Empty States Summary

**AppEmptyState promotes the approved finance empty-state layout to a cross-slice widget; the task list now prompts "Adicionar tarefa", search-with-no-match echoes the query, and the GTD filter explains how to add contexts.**

## Performance

- **Duration:** about 7 min
- **Started:** 2026-11-16T19:11:46Z
- **Completed:** 2026-11-16T19:18:09Z
- **Tasks:** 2
- **Files modified:** 13 (4 created, 9 modified)

## Accomplishments

- `AppEmptyState` reproduces `FinanceEmptyState`'s widget tree exactly (icon 72 `onSurfaceVariant`, gaps 16/8/24, horizontal padding 32, `titleMedium` heading, `bodyMedium` `onSurfaceVariant` body). The `FilledButton` renders only when both `ctaLabel` and `onCta` are given.
- Empty task list with no query: `check_box_outline_blank`, `noTasks`, `tasksEmptyBody`, and a `tasksEmptyCta` button that calls `_navigateToCreate`, the same flow as the FAB.
- Non-empty search with no match: `search_off`, `tasksSearchEmptyTitle`, `tasksSearchEmptyBody(query)`, no CTA.
- GTD filter with no contexts: `label_outline`, `noGtdContexts`, `gtdEmptyBody`, no CTA.
- `FinanceEmptyState` delegates to `AppEmptyState`. `finance_empty_state_test.dart` passes and was not modified.
- New `lib/presentation/shared/` slice with READMEs, which satisfies the architecture guard.

## Task Commits

1. **Task 1 (tracer): shared AppEmptyState and task list empty-state CTA** - `0b28a91` (feat). The tracer gate re-ran `<verify>` end-to-end and it passed (13 tests, analyze at 64 issues, guard PASS) before Task 2 started.
2. **Task 2: search, GTD and finance empty states via AppEmptyState** - `4daa04e` (feat)

## Verification

- `flutter test --no-pub test/presentation/tasks test/presentation/finance test/presentation/shared`: 90 passed.
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, 64 issues (cap 65). All issues were already there or are infos in untouched lines.
- `dart run tool/check_architecture.dart`: PASS.
- `git diff --stat -- test/presentation/finance/finance_empty_state_test.dart`: empty.
- Line counts: task_list_screen 147, task_list_view 100, gtd_filter_screen 144, finance_empty_state 49, app_empty_state 76.

## Decisions Made

- I kept the 150-line cap on `task_list_screen.dart` with a Dart 3 or-pattern (`TaskListLoaded(:final items) || TaskListWithPendingUndo(:final items)`) and single-line loading/error arms, instead of extracting a builder method. The rendered output for every state is the same as before.
- The CTA navigation test registers mock `GoalRepository` and `DebtRepository` in `getIt`, because the pushed `TaskFormScreen` resolves them in `initState`. This follows the pattern in `task_form_test.dart`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] GTD test assertion too broad**
- **Found during:** Task 2
- **Issue:** `find.byType(FilledButton), findsNothing` also matched the GTD screen's own Apply button, which is outside the empty state.
- **Fix:** Limited the assertion to descendants of `AppEmptyState`.
- **Files modified:** test/presentation/tasks/gtd_test.dart
- **Commit:** 4daa04e

**Total deviations:** 1 auto-fixed (a test-scoping fix in a test written by this plan). **Impact:** none on production code.

## Issues Encountered

None.

## Notes for Later

- The layout tree in `lib/presentation/README.md` still lists only `tasks/` and `finance/`. It was already out of date before this plan (it also leaves out `backup/`, `onboarding/`, `notifications/` and `shell/`), and the file is not in this plan's `files_modified`. A future docs pass should add `shared/` and the other slices.

## Known Stubs

None.

## Threat Flags

None. The echoed search query (T-05-15, accepted) is rendered by a plain `Text` widget.

## Next Phase Readiness

- Any new list screen (for example in Settings) can use `AppEmptyState` directly.

## Self-Check: PASSED

- FOUND: lib/presentation/shared/widgets/app_empty_state.dart
- FOUND: lib/presentation/shared/README.md
- FOUND: lib/presentation/shared/widgets/README.md
- FOUND: test/presentation/shared/app_empty_state_test.dart
- FOUND: 0b28a91
- FOUND: 4daa04e
