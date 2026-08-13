---
phase: 03-finance-core
plan: 08
subsystem: tasks-presentation
tags: [gap-closure, uat, finance-link, widget-test]
gap_closure: true
requires:
  - loadFinanceLinks (lib/presentation/tasks/form/task_form_logic.dart)
  - GoalRepository, DebtRepository (via getIt)
provides:
  - Task detail finance chip that names the linked goal/debt
affects:
  - lib/presentation/tasks/widgets/detail/
tech-stack:
  added: []
  patterns:
    - "unawaited(future.then(...)) for fire-and-forget lookups in initState"
    - "getIt + registerSingleton in setUp, getIt.reset() in tearDown for widget tests"
key-files:
  created: []
  modified:
    - lib/presentation/tasks/widgets/detail/task_detail_finance_chip.dart
    - lib/presentation/tasks/widgets/detail/README.md
    - test/presentation/tasks/task_detail_screen_test.dart
decisions:
  - "Reused loadFinanceLinks instead of adding a repository method or a second lookup"
  - "Wrapped the lookup in unawaited() rather than copying the analog's bare .then, keeping the analyze baseline at 65 infos"
  - "Kept the kind-label + raw-id string as the explicit degraded fallback rather than hiding the chip"
requirements: [FIN-05, FIN-07]
metrics:
  duration: ~25m
  tasks: 2
  completed: 2026-08-13
---

# Phase 03 Plan 08: Finance-Link Chip Name Resolution Summary

The task detail screen's finance chip now resolves and displays the linked
goal/debt title ("Ligado a Empréstimo Joao") instead of the raw Isar id
("Ligado a Dívidas #1"), reusing the same `loadFinanceLinks` helper the task
form already calls.

## What Was Built

**Task 1 — chip resolves the linked entity title** (`fec622d`)

`TaskDetailFinanceChip` converted from `StatelessWidget` to `StatefulWidget`.
`initState` returns early without touching a repository when the task carries
no link (the chip is placed unconditionally on every detail screen, so the
unlinked path had to stay zero-cost). Otherwise it calls `loadFinanceLinks`
with `getIt<GoalRepository>()` / `getIt<DebtRepository>()` and stores
`s.linkedGoalTitle ?? s.linkedDebtTitle` behind an `if (mounted)` guard.

The public constructor is unchanged — `task_detail_info_cards.dart` needed no
edit, and the diff touches no ARB file and adds no l10n key.

**Task 2 — tests register the repositories and pin both paths** (`c360c25`)

`test/presentation/tasks/task_detail_screen_test.dart` now declares
`MockGoalRepository` / `MockDebtRepository`, registers them in `setUp` with
empty-list defaults, and resets GetIt in `tearDown` — the precedent
`task_form_test.dart` already set. Two new cases: one asserting the chip
renders the debt title and *not* `#1`, one asserting the deleted-entity
fallback still renders and throws nothing.

## Key Decisions

**Reuse over reinvention.** `loadFinanceLinks` already loads active goals and
debts and resolves the title for whichever id was passed, leaving it null when
the entity is missing — exactly this gap's requirement. No new repository
method, no parallel lookup function.

**`unawaited()` over the analog's bare `.then`.** The plan's stated analog
(`task_form_screen.dart:52`) uses a bare `.then` in a non-async `initState`,
which is itself one of the 65 accepted `discarded_futures` infos. Copying it
verbatim would have produced a 66th and broken the phase gate. `unawaited` is
the wider presentation-layer convention here (`dashboard_tab.dart:32`,
`gtd_filter_screen.dart:38`, `task_detail_screen.dart:41`), so the chip
follows that instead. The lint was not silenced with an `// ignore:` comment.

**Fallback kept, not hidden.** When the linked entity has been deleted, the
chip still renders with the kind label plus the id rather than vanishing. This
is commented in-code as the deliberate degraded case.

## Deviations from Plan

None affecting behavior. Two presentational choices within the plan's latitude:

**1. Label built via an intermediate `label` local.** The plan spelled the new
label as a nested interpolation
(`'${l10n.linkedTo} ${_linkedTitle ?? '$kindLabel #${...}'}'`). Implemented as
a separate `final label = _linkedTitle ?? '...'` followed by
`Text('${l10n.linkedTo} $label')` — identical output, avoids a nested
single-quote interpolation. Verified equivalent by the mutation check below.

**2. Class doc comment reworded.** An earlier draft mentioned
`loadFinanceLinks` in the doc comment, which made
`grep -c loadFinanceLinks` return 2 against an acceptance criterion expecting
exactly 1. The comment now says "the same finance-link helper the task form
already uses"; the call site is the single match.

## Interim RED (expected, per plan)

Task 1 deliberately left `task_detail_screen_test.dart` failing — the chip
resolved `getIt<GoalRepository>()` with nothing registered, throwing
`Bad state: GetIt: Object/factory with type GoalRepository is not registered`
at `task_detail_finance_chip.dart:43:14`. This was the plan's declared and
expected interim state; Task 2 repaired it. Verified green at the end.

## Verification

| Gate | Baseline (`c10f314`) | After | Status |
|------|---------------------|-------|--------|
| `dart run tool/check_architecture.dart` | exit 0 | exit 0 | PASS |
| `flutter analyze --no-fatal-infos --fatal-warnings` | exit 0, 65 infos | exit 0, 65 infos | PASS |
| `discarded_futures` info count | 25 | 25 | PASS — none added |
| `flutter test --no-pub` | 268 passing | 270 passing | PASS — +2, no regression |
| `task_detail_screen_test.dart` | 3 passing | 5 passing | PASS |

Additional checks:
- `task_detail_finance_chip.dart` is 89 lines (cap 150); the README `Lines`
  column was updated 44 → 89 to match.
- `lib/presentation/tasks/widgets/detail/` still holds 9 hand-written `.dart`
  files against the 10-file cap — no file added.
- `git diff --name-only` lists neither `task_detail_info_cards.dart` nor any
  ARB file under `lib/config/l10n/`.
- No `mockito`, `provider`, or `get` import in the touched test.

**Mutation check (acceptance criterion).** Temporarily reverting the label
expression to always render the raw id made exactly one test fail —
`finance chip names the linked debt instead of its raw id`, with
`Found 0 widgets with text "Linked to Empréstimo Joao"`. The chip file was
restored byte-identical to its committed state (confirmed by an empty
`git diff --stat`), proving the new test genuinely pins the fix rather than
passing vacuously.

## Documentation

`lib/presentation/tasks/widgets/detail/README.md`: refreshed the line count and
Role cell for the chip, and amended the "Purely presentational. No cubit, no
repository" bullet — that claim became false. `task_detail_finance_chip.dart`
is now recorded as the one documented exception (it resolves two repositories
through `getIt` because the chip's whole job is naming an entity living in
another aggregate, and an `Item` carries only that entity's id), mirroring how
`presentation/finance/widgets/README.md` documents
`transaction/transaction_form_submit.dart`.

## Known Stubs

None. The `onPressed` on the chip remains an intentional no-op with its
pre-existing "deep-link routing deferred" comment — untouched by this plan and
out of its scope.

## Threat Flags

None. No new network endpoint, auth path, file access pattern, or schema
change. The plan's threat register (T-03-08-01 accept, T-03-08-02 mitigate,
T-03-08-03 accept) is unchanged; T-03-08-02's mitigations — skip the call when
unlinked, null-title fallback on a missing entity, `if (mounted)` before
`setState` — are all implemented and both of its paths are covered by the
Task 2 tests.

## Self-Check: PASSED

- `lib/presentation/tasks/widgets/detail/task_detail_finance_chip.dart` — FOUND
- `lib/presentation/tasks/widgets/detail/README.md` — FOUND
- `test/presentation/tasks/task_detail_screen_test.dart` — FOUND
- Commit `fec622d` — FOUND
- Commit `c360c25` — FOUND

## Commits

| Hash | Message |
|------|---------|
| `fec622d` | fix(03-08): resolve linked goal/debt title in task detail finance chip |
| `c360c25` | test(03-08): pin the resolved finance-link name and its fallback |
