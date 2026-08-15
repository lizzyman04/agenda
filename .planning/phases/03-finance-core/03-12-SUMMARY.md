---
phase: 03-finance-core
plan: 12
subsystem: presentation/tasks, presentation/finance
tags: [undo-snackbar, defunct-context, amount-parser, gap-closure]
dependency-graph:
  requires: [03-07 (messenger house pattern), 03-10, 03-11]
  provides: [task-detail-undo-fix, budget-limit-shared-parser]
  affects:
    - lib/presentation/tasks/screens/task_detail_screen.dart
    - lib/presentation/finance/widgets/budget/budget_limit_sheet.dart
tech-stack:
  added: []
  patterns:
    - "Capture cubit/messenger/l10n strings into locals BEFORE Navigator.pop() when a SnackBar action will run after the route is gone"
key-files:
  created:
    - test/presentation/tasks/task_detail_undo_test.dart
  modified:
    - lib/presentation/tasks/screens/task_detail_screen.dart
    - lib/presentation/tasks/screens/README.md
    - lib/presentation/finance/widgets/budget/budget_limit_sheet.dart
    - lib/presentation/finance/widgets/budget/README.md
decisions:
  - "budget_limit_sheet: ANY null from parseAmountCentsOrNull (including an empty field) now shows the error snackbar and keeps the sheet open, rather than silently popping null. The Save button previously treated empty-and-invalid identically as a silent no-op; that ambiguity is now resolved in favor of always requiring a valid amount to use Save. Cancelling still works via the sheet's own drag-down/tap-outside dismissal, unaffected by this change."
metrics:
  duration: "~35min"
  completed: "2026-08-15"
---

# Phase 03 Plan 12: Close CR-03 (dead-context undo) and WR-07 (inline amount parser) Summary

Fixed the task-detail undo SnackBar reading a cubit off a popped route's
defunct context (CR-03), and removed the fifth inline re-implementation of
amount-cents parsing in the budget limit sheet, making a rejected amount
visible instead of silently discarding the save (WR-07).

## What Was Built

**Task 1 — `task_detail_screen.dart` (CR-03 fix).** `_confirmDelete` now
resolves `cubit`, `messenger`, and the two l10n strings (`taskDeleted`,
`undo`) into locals BEFORE `Navigator.of(context).pop()`. The
`SnackBarAction.onPressed` closure calls `cubit.restoreItem(item.id)` on the
captured local, never `context.read<...>()`. Matches the house pattern
established by 03-07 in `transaction_list_screen.dart`: a `messenger`
cascade — `..hideCurrentSnackBar()..showSnackBar(...)`. A comment at the
capture site explains why: the SnackBar can outlive the route by up to
`AppConstants.undoSnackbarDuration` (5s), and an ancestor lookup performed
later against a defunct element throws.

The plan flagged a "messenger question" — whether the messenger resolved
from the detail route's own context would still be valid post-pop. It is:
`ScaffoldMessenger.of(context)` resolves the nearest `ScaffoldMessenger`
ancestor at CALL time (before the pop), returning a live `ScaffoldMessengerState`
object, not a context-bound lookup. Once captured, that object reference
stays valid regardless of what happens to the widget tree below it. No
fallback to a root-navigator-context messenger was needed; the file's own
detail-route context worked correctly, verified by the new test in Task 2
actually seeing the SnackBar appear post-pop.

**Task 2 — `test/presentation/tasks/task_detail_undo_test.dart` (new).**
Pushes `TaskDetailScreen` as a real route (so the pop genuinely defuncts the
route's context), confirms delete, then TAPS Undo and verifies
`restoreItem(9)` was called exactly once — the tap is the entire point,
since the pre-existing `task_detail_screen_test.dart` only confirms the
delete dialog and never taps Undo, which is exactly how CR-03 shipped
undetected. A second test proves the SnackBar still auto-dismisses on its
own when Undo is not tapped, guarding against a regression of the separate
`d102f2b` fix.

**Task 3 — `budget_limit_sheet.dart` (WR-07 fix).** `_submit` now calls the
shared `parseAmountCentsOrNull` instead of re-implementing
`.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '')` inline (the fifth
such copy in the codebase). When the parser returns `null`, the sheet no
longer pops silently — it shows the existing `errorAmountRequired` SnackBar
(reusing the key already used by `goal_form_screen.dart` /
`debt_form_screen.dart`, no new ARB strings needed) and returns without
popping, leaving the sheet open for correction. A comment at the call site
records the known PT-BR thousands-separator defect in
`amount_parser.dart` (`'1.250,00'` → `'1.250.50'` → `null`) as the reason
surfacing the rejection matters, and explicitly hands that root-cause fix
off to its own deferred task. `amount_parser.dart` itself is untouched
(`git diff --stat` confirmed empty).

## Deviations from Plan

### Auto-fixed Issues

None beyond the plan's own explicit scope — no Rule 1/2/3 auto-fixes were
needed; both defects and their fixes were fully specified by the plan.

**1. [Design choice within Task 3's explicit action] Any null from the
parser (not just a non-empty unparseable string) now triggers the error
path.** The plan's wording ("when the parser returns null, do NOT close the
sheet as if the save succeeded") does not carve out empty input as a
special case, and the original code already treated empty and invalid
input identically (both silently popped `null`, which the caller
(`budget_overview_screen.dart`) treats as "no-op, no limit change" either
way — there was never a "clear the limit by leaving it blank and saving"
pathway). Requiring a valid amount to use the "Set Budget Limit" button is
therefore not a functional regression; users still cancel via the sheet's
native drag-down/tap-outside dismissal. Documented as a decision above so
a future reader does not "simplify" it back.

## Gates (measured after all 3 tasks, each command run unpiped)

- `dart run tool/check_architecture.dart`: **PASS, exit 0**
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, **65 issues**
  — budget held; `lines_longer_than_80_chars` grep count is **0**
- `flutter test --no-pub`: **297/297 passing**, exit 0 (295 baseline + 2 new
  from Task 2's `task_detail_undo_test.dart`)

## Mutation Check (Task 2, performed and reverted)

Reverted Task 1's capture — put `context.read<TaskListCubit>()` back inside
the `SnackBarAction.onPressed` closure — and re-ran
`task_detail_undo_test.dart`. It failed exactly as expected, reproducing
CR-03's real symptom:

```
══╡ EXCEPTION CAUGHT BY GESTURE ╞═══
Looking up a deactivated widget's ancestor is unsafe.
At this point the state of the widget's element tree is no longer stable.
...
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞═══
No matching calls. All calls: MockTaskListCubit.stream, [VERIFIED] MockTaskListCubit.softDelete(9)
```

The second (auto-dismiss) test also failed as a cascading side effect of the
same exception. Reverted the mutation via `Edit` (not `git checkout --`, per
the trap noted by 03-11); `git diff --stat` on
`task_detail_screen.dart` came back empty, confirming the file matched the
committed Task 1 state exactly, not a stale earlier commit.

## Manual Verification (Task 3, no persisted test — not in plan's file list)

The plan's `<files>` for Task 3 lists only `budget_limit_sheet.dart` and its
README, no test file. To confirm the acceptance criterion ("An unparseable
amount keeps the sheet open and shows a localized error") without adding an
out-of-scope test file, a throwaway widget test was written, run, and
deleted before commit: entering `1.250,00` (the known thousands-separator
defect input) and tapping the Save button left `BudgetLimitSheet` mounted
and showed `l10n.errorAmountRequired`. `git status --short` after deletion
confirmed no residue.

## Self-Check

- `lib/presentation/tasks/screens/task_detail_screen.dart` — FOUND
- `lib/presentation/tasks/screens/README.md` — FOUND
- `test/presentation/tasks/task_detail_undo_test.dart` — FOUND
- `lib/presentation/finance/widgets/budget/budget_limit_sheet.dart` — FOUND
- `lib/presentation/finance/widgets/budget/README.md` — FOUND
- Commit `fe2b0c1` (Task 1) — FOUND in `git log`
- Commit `3f6be3a` (Task 2) — FOUND in `git log`
- Commit `bfd56d2` (Task 3) — FOUND in `git log`

## Self-Check: PASSED
