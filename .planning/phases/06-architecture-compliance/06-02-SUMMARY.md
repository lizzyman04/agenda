---
phase: 06
plan: 02
subsystem: ui
tags: [flutter, bloc, presentation-layer, architecture-compliance, refactor]

# Dependency graph
requires:
  - phase: 06
    provides: "GTD guide already extracted from task_form_screen.dart (commits 6c06312/04c4f84, plan 6-01), leaving a 752-line screen"
provides:
  - "task_form_screen.dart at 148 lines (was 752); every file in presentation/tasks/form/ (including the new ones) at or under the 150-line architecture gate"
  - "TaskFormFieldsModel: a mutable holder consolidating the task form's non-controller field state, with batch apply* methods for sheet/wizard results"
  - "TaskFormFields: composite widget assembling the field-group widgets; owns date/time pickers and the finance-link sheet since they only ever touch the model"
affects: [presentation/tasks, architecture-compliance-followups]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Screen owns TextEditingControllers + a single mutable non-widget model (TaskFormFieldsModel); widgets receive the model read-only plus one onModelChanged(mutate) callback the screen wraps in setState, instead of one callback per field"
    - "Sheets/pickers that only touch the model (no TextEditingController) are implemented directly on a StatelessWidget that already has BuildContext in build(), rather than always bouncing back to the screen"
    - "Sheets that must also write into text controllers (GTD guide) stay screen-owned, per the slice's existing pop-returns-a-value convention"

key-files:
  created:
    - lib/presentation/tasks/form/task_form_fields_model.dart
    - lib/presentation/tasks/form/widgets/task_form_fields.dart
    - lib/presentation/tasks/form/widgets/title_type_card.dart
    - lib/presentation/tasks/form/widgets/schedule_fields.dart
    - lib/presentation/tasks/form/widgets/flags_size_notes_fields.dart
    - lib/presentation/tasks/form/widgets/finance_link_sheet.dart
  modified:
    - lib/presentation/tasks/form/screens/task_form_screen.dart
    - lib/presentation/tasks/form/task_form_logic.dart
    - lib/presentation/tasks/form/README.md

key-decisions:
  - "Consolidated 11+ non-controller State fields into one mutable TaskFormFieldsModel to make the ≤150-line gate achievable; without this the screen's build()/save()/init callback wiring alone exceeded 150 lines even with every field-group extracted into its own widget"
  - "Moved date/time picking and the finance-link sheet invocation from the screen into TaskFormFields (a StatelessWidget) because they only ever mutate the model, not a TextEditingController — this is a widened but not violated reading of 'screens own state': the screen still owns the model object and still wraps every mutation in setState via onModelChanged"
  - "Kept the GTD guide's showModalBottomSheet call on the screen because applying its result writes into TextEditingControllers, which only the screen may touch"
  - "buildFormItem now takes the TaskFormFieldsModel directly instead of 11 flat parameters, and FinanceLinksSnapshot/GtdFormValues moved from task_form_logic.dart into task_form_fields_model.dart, to keep the import direction one-way (logic -> model, never the reverse)"

patterns-established:
  - "TaskFormFieldsModel + onModelChanged(mutate) callback: use this pattern for any future Flutter form screen in this codebase that accumulates more than ~6 independent pieces of non-controller state and needs to stay under the 150-line file gate"

requirements-completed: []

duration: ~50min (this session, resuming rescued WIP; total including the interrupted prior session unknown)
completed: 2026-08-11
---

# Phase 06 Plan 02: Task Form Screen Decomposition Summary

**Split `task_form_screen.dart` (752 lines) into 8 compliant files by extracting field-group widgets and introducing a mutable `TaskFormFieldsModel` to collapse per-field callback wiring, landing the screen itself at 148 lines.**

## Performance

- **Duration:** ~50 min this session (resumed from a rescued, unverified WIP commit)
- **Completed:** 2026-08-11
- **Tasks:** 2/2
- **Files modified/created:** 8 (`task_form_screen.dart`, `task_form_logic.dart`, `README.md` modified; `task_form_fields_model.dart`, `widgets/task_form_fields.dart`, `widgets/title_type_card.dart`, `widgets/schedule_fields.dart`, `widgets/flags_size_notes_fields.dart`, `widgets/finance_link_sheet.dart` created)

## Accomplishments

- `task_form_screen.dart`: 752 → 148 lines
- Every file in `lib/presentation/tasks/form/` (top level + `screens/` + `widgets/`, GTD sub-slice untouched) is ≤150 lines, confirmed by `dart run tool/check_architecture.dart` (zero LINES violations under this directory) and a manual `wc -l` sweep
- `flutter analyze lib/presentation/tasks/form/` is clean (info-only: pre-existing style lints like line length and `RadioListTile` deprecation, none introduced by files this plan didn't touch)
- `task_form_test.dart`, `gtd_test.dart`, `gtd_decision_tree_test.dart` all pass unchanged (28 tests total across the three files)

## Task Commits

1. **Task 1: Extract non-widget logic and the finance-link sheet** — `fef445f` (refactor). Completed the rescued WIP: wired `buildFormItem`/`applyGtdResult` into `_save()`/`_openGtdGuide()` (the rescued commit had created `task_form_logic.dart` and `widgets/finance_link_sheet.dart` but never actually called into them), fixed two missing imports (`savings_goal.dart`, `debt.dart`) that were analyzer errors in the rescued state.
2. **Task 2: Extract the remaining field-group widgets and verify the whole slice** — `ce0da5c` (refactor). Extracted `TitleTypeCard`, `ScheduleFields`, `FlagsSizeNotesFields`; introduced `TaskFormFieldsModel` and `TaskFormFields` (both beyond the plan's original file list) to hit the ≤150-line gate; updated the README.

**Plan metadata:** (this commit, `docs(6-02): complete task form screen decomposition plan`)

## Rescued WIP: What Was Kept vs. Redone

The orchestrator rescued uncommitted work from a prior interrupted executor into commit `525afaf` on branch `worktree-agent-a87f3e2112faf19f9`, merged into this worktree at the start of this session. Per the resume instructions, I verified it before trusting it:

- **Kept as-is:** `task_form_logic.dart`'s `loadFinanceLinks`/`buildFormItem`(v1)/`applyGtdResult`, and `widgets/finance_link_sheet.dart` in full — both were correct, matched the plan's spec, and needed no changes beyond later refactors made in Task 2 for the line-count gate.
- **Redone:** `task_form_screen.dart`'s wiring. The rescued state had created the logic file and the finance-link sheet but had **not** finished replacing `_save()`'s inline `Item` construction or `_openGtdGuide()`'s inline field mapping with calls into the new functions — the duplicate inline logic was still present, and two imports were missing (`savings_goal.dart`, `debt.dart`), which `flutter analyze` confirmed as two hard errors before I touched anything. I fixed both and completed the delegation the rescued commit's message said it was "about to" do.
- Ran `flutter analyze lib/presentation/tasks/` and `flutter test test/presentation/tasks/task_form_test.dart` against the merged state before writing any new code, per the resume instructions — confirmed the two errors, then fixed them as part of Task 1's own commit.

## Decisions Made

See `key-decisions` in frontmatter. The one substantive judgment call: the plan's `<interfaces>` section (written at planning time against the 752-line file) anticipated the screen would still directly call `showModalBottomSheet<FinanceLinkSelection>(... FinanceLinkSheet(...))` after Task 2. Hitting the hard ≤150-line gate required moving that call into `TaskFormFields` instead, since the picker only touches the model (no `TextEditingController`). This is documented as a deviation below because it changes one of the plan's stated `key_links` from `screens/task_form_screen.dart -> widgets/finance_link_sheet.dart` to `widgets/task_form_fields.dart -> widgets/finance_link_sheet.dart`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Completed the rescued WIP's unfinished delegation and two missing imports**
- **Found during:** Task 1
- **Issue:** The rescued commit (`525afaf`) had created `task_form_logic.dart` and `widgets/finance_link_sheet.dart` and updated `initState`/`_pickFinanceLink` to use them, but `_save()` and `_openGtdGuide()` still had the old inline logic duplicated alongside the new functions (dead code, and `buildFormItem`/`applyGtdResult` were never called). `flutter analyze` also reported two hard errors: `SavingsGoal`/`Debt` used as type arguments without being imported.
- **Fix:** Rewired `_save()` to call `buildFormItem(...)` + a `_persist`/`_handleSaveResult` split (matching the plan's suggested unification); rewired `_openGtdGuide()` to call `applyGtdResult(...)`; added the two missing imports (`hide clearField` to avoid the sentinel-name collision with `item.dart`'s `clearField`).
- **Files modified:** `lib/presentation/tasks/form/screens/task_form_screen.dart`, `lib/presentation/tasks/form/task_form_logic.dart` (parameter reordering for a lint)
- **Verification:** `flutter analyze` went from 2 errors to 0; `flutter test test/presentation/tasks/task_form_test.dart` passed (3/3)
- **Committed in:** `fef445f`

**2. [Rule 2/3 - Missing critical functionality, required by the plan's own hard gate] Introduced `TaskFormFieldsModel` and `TaskFormFields`, beyond the plan's `files_modified` list**
- **Found during:** Task 2
- **Issue:** After extracting `TitleTypeCard`/`ScheduleFields`/`FlagsSizeNotesFields` exactly as specified and applying the plan's suggested fallback (moving `initState`'s item-to-field mapping into a logic-file function), `task_form_screen.dart` was still ~390 lines — the plan's own "apply one additional cut" fallback was insufficient because the screen's bulk wasn't really in `initState`, it was in the sheer number of independent state fields each needing their own `setState`-wrapped callback at the `build()` call site (11 non-controller fields × individual `onXChanged` wiring).
- **Fix:** Consolidated those 11 fields into one mutable `TaskFormFieldsModel`, passed to a new composite widget `TaskFormFields` alongside a single generic `onModelChanged(void Function(TaskFormFieldsModel) mutate)` callback the screen wraps in one `setState`. This collapsed the `build()` call site from ~25 named per-field parameters to ~10, and shrank `initState`/`_save`/`_openGtdGuide` correspondingly since they now read/write `_f.x` via batch `apply*` methods on the model instead of assigning each field individually. Also moved date/time picking and the finance-link sheet invocation into `TaskFormFields` itself, since both only ever mutate the model (no controller involved) and `TaskFormFields` already has `BuildContext` in its own `build()`.
- **Files modified:** `lib/presentation/tasks/form/task_form_fields_model.dart` (new), `lib/presentation/tasks/form/widgets/task_form_fields.dart` (new), `lib/presentation/tasks/form/screens/task_form_screen.dart`, `lib/presentation/tasks/form/task_form_logic.dart`
- **Verification:** Final `wc -l` sweep — every file in the slice ≤150 lines; `dart run tool/check_architecture.dart` reports zero LINES violations under `tasks/form/`; `flutter analyze` clean; all three test files green
- **Committed in:** `ce0da5c`
- **Consequence for the plan's stated key_links:** The plan's frontmatter lists `screens/task_form_screen.dart -> widgets/finance_link_sheet.dart via showModalBottomSheet<FinanceLinkSelection>(...)`. That call now lives in `widgets/task_form_fields.dart -> widgets/finance_link_sheet.dart` instead (same pattern, `FinanceLinkSheet(`, different source file). The `must_haves.truths` behavior itself — "the finance-link bottom sheet still lets the user pick a goal, a debt, or clear the link, and the selection is applied only after the sheet closes" — is unchanged and verified by inspection; only which file issues the `showModalBottomSheet` call moved.

---

**Total deviations:** 2 auto-fixed (1 Rule 3 blocking-issue fix, 1 Rule 2/3 necessary-for-completion architectural adjustment forced by the plan's own explicit hard gate)
**Impact on plan:** No scope creep — both deviations exist solely to satisfy the plan's stated `must_haves.truths` line-count requirement, which the plan's own text acknowledged might need more than the one fallback it suggested ("Do not stop until every file in the slice is ≤150 lines — this is a hard acceptance gate, not a target").

## Issues Encountered

`dart format` (the version bundled with this environment's Dart 3.11.1 SDK) uses a newer "tall style" that adds enough line breaks to push several files over the 150-line gate on its own — confirmed by running it against the already-compliant `gtd_guide_sheet.dart` (139 lines), which it also wanted to reformat upward. Did not run `dart format` on any file in this plan; hand-formatted everything in the compact multi-arg-per-line style already used elsewhere in the slice (e.g. `Item(id: 0, type: itemType, ...)` in the pre-existing `task_form_logic.dart`). This is a style-tool version mismatch, not a code issue — flagging in case a future plan runs `dart format` project-wide and needs to reconcile the line-count gate against the newer formatter's output.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

The `tasks/form/` slice (including `gtd/`) is now fully compliant with the 150-line architecture gate. No further decomposition work is queued for this slice. The `TaskFormFieldsModel` + `onModelChanged` pattern introduced here is a reasonable template for the next architecture-compliance plans that hit similarly stateful screens — `dart run tool/check_architecture.dart` currently also reports LINES violations in `lib/presentation/finance/goals/screens/goal_form_screen.dart` (286), `lib/presentation/finance/screens/recurring_payment_form_screen.dart` (431), `lib/presentation/finance/screens/debt_form_screen.dart` (327), and `lib/presentation/finance/screens/transaction_form_screen.dart` (587) — all pre-existing, out of this plan's scope, and good candidates for the same pattern.

No on-device manual smoke test was performed (no emulator/device available in this sandboxed environment) for the specific scenario the plan calls out — "edit and clear the due date, confirm no `TextEditingController used after being disposed` crash." This is a residual gap: `task_form_test.dart` covers create-mode title validation and `cubit.createItem`, but there is no automated test exercising the due-date-clear path. Note that this gap already existed before this plan (the plan's own acceptance criteria flagged it as untestable via existing infra) and is not new: `TaskFormFields` and `FlagsSizeNotesFields`/`ScheduleFields` never create or dispose a `TextEditingController` (verified by inspection — they only receive `TextEditingController` instances as constructor parameters), so the crash class this check guards against structurally cannot occur from this refactor. A follow-up plan could add a widget test that pumps the form, sets a due date, clears it, and asserts no exception — flagging as a suggested addition, not a blocker.

---
*Phase: 06-architecture-compliance*
*Completed: 2026-08-11*

## Self-Check: PASSED

- FOUND: lib/presentation/tasks/form/task_form_fields_model.dart
- FOUND: lib/presentation/tasks/form/widgets/task_form_fields.dart
- FOUND: lib/presentation/tasks/form/widgets/title_type_card.dart
- FOUND: lib/presentation/tasks/form/widgets/schedule_fields.dart
- FOUND: lib/presentation/tasks/form/widgets/flags_size_notes_fields.dart
- FOUND: lib/presentation/tasks/form/widgets/finance_link_sheet.dart
- FOUND: lib/presentation/tasks/form/screens/task_form_screen.dart
- FOUND: lib/presentation/tasks/form/task_form_logic.dart
- FOUND commit fef445f (Task 1)
- FOUND commit ce0da5c (Task 2)
