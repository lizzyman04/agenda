---
phase: 06-architecture-compliance
plan: 14
subsystem: ui
tags: [flutter, finance, forms, refactor, dart]

# Dependency graph
requires:
  - "lib/presentation/finance/widgets/finance_form_primitives.dart — FormCard/FieldRow/FieldDivider (06-08)"
  - "lib/core/utils/amount_parser.dart — parseAmountCentsOrNull (06-08)"
provides:
  - "lib/presentation/finance/debt_form_logic.dart — buildDebtToSave, pure Debt construction extracted from _save()"
  - "lib/presentation/finance/widgets/debt/debt_direction_toggle.dart — DebtDirectionToggle"
  - "lib/presentation/finance/widgets/debt/debt_form_fields.dart — DebtFormFields"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Same split pattern as prior finance-form plans: pure *_form_logic.dart for save-object construction, small composed widgets under widgets/<entity>/, screen down to layout/wiring only"
    - "Unified create/update cubit dispatch behind a single _persist(Entity) helper on the State class"

key-files:
  created:
    - lib/presentation/finance/debt_form_logic.dart
    - lib/presentation/finance/widgets/debt/debt_direction_toggle.dart
    - lib/presentation/finance/widgets/debt/debt_form_fields.dart
  modified:
    - lib/presentation/finance/screens/debt_form_screen.dart

key-decisions:
  - "Split DebtDirectionToggle into its own file (debt_direction_toggle.dart) instead of the plan's single debt_form_fields.dart with two widgets — the combined file was 171 lines after dart format, exceeding the must_have 150-line-per-file constraint. The must_haves.truths line-count requirement is the hard constraint; the plan's literal '2 widgets, 1 new file' instruction gave way to it (Rule 2 — correctness requirement)."
  - "Unified the create/update branches behind _persist(Debt debt), matching the plan's stated fallback for when the initial extraction leaves the screen over 150 lines"

requirements-completed: []

# Metrics
duration: ~20min
completed: 2026-08-12
---

# Phase 06 Plan 14: Debt Form Screen Split Summary

**Split `debt_form_screen.dart` (327 → 150 lines) into `debt_form_logic.dart` (pure save-object builder), `debt_direction_toggle.dart`, and `debt_form_fields.dart`, adopting the shared FormCard/FieldRow/FieldDivider and amount parser from 6-08**

## Performance

- **Duration:** ~20 min
- **Tasks:** 2 completed
- **Files modified:** 1 (debt_form_screen.dart); 3 new files

## Accomplishments
- Deleted the local `_FormCard`/`_FieldRow`/`_FieldDivider` classes from `debt_form_screen.dart` and switched to the shared `finance_form_primitives.dart` widgets (from 6-08).
- Replaced the inline amount-parsing block in `_save()` with `parseAmountCentsOrNull` (from 6-08's `amount_parser.dart`).
- Extracted `buildDebtToSave()` into `debt_form_logic.dart` — moves the `Debt(...)`/`copyWith(...)` construction verbatim, including the `isPaid: false` create-default, as a pure function testable without widget state.
- Extracted the direction toggle into `DebtDirectionToggle` and the title/amount/counterparty/due-date card into `DebtFormFields`, both consuming the shared primitives.
- Unified the create/update cubit dispatch behind a single `_persist(Debt debt)` helper to bring the screen down to the 150-line budget.

## Task Commits

Each task was committed atomically:

1. **Task 1: Adopt shared utilities; extract save logic** - `fb754fe` (refactor)
2. **Task 2: Extract the form-fields composition widget and verify the whole slice** - `064311f` (refactor)

**Plan metadata:** committed after this SUMMARY (see final commit below)

## Files Created/Modified
- `lib/presentation/finance/debt_form_logic.dart` - `buildDebtToSave()`; 41 lines
- `lib/presentation/finance/widgets/debt/debt_direction_toggle.dart` - `DebtDirectionToggle`; 42 lines
- `lib/presentation/finance/widgets/debt/debt_form_fields.dart` - `DebtFormFields`; 125 lines
- `lib/presentation/finance/screens/debt_form_screen.dart` - now 150 lines (was 327); layout/wiring only, uses shared primitives + the 3 new files

## Decisions Made
- **Split the two-widget file the plan specified into two files.** The plan asked for a single `debt_form_fields.dart` containing both `DebtDirectionToggle` and `DebtFormFields`. After `dart format` (this repo's canonical formatter, run to match existing code style), that combined file measured 171 lines — over the plan's own `must_haves.truths` requirement that "every new file is at or under 150 lines." Since the plan's own hard constraint and its literal file-layout instruction conflicted, the constraint won: `DebtDirectionToggle` now lives in its own `debt_direction_toggle.dart` (42 lines), and `debt_form_fields.dart` holds only `DebtFormFields` (125 lines). Both are well under budget as a result, and the acceptance-criteria loop (which checks `debt_form_screen.dart`, `debt_form_fields.dart`, `debt_form_logic.dart`) still passes since it doesn't reference the extra file negatively.
- **Applied the `_persist(Debt debt)` fallback pattern** named in the plan (matching sibling plans 6-12/6-13) to bring `debt_form_screen.dart` from 152 to exactly 150 lines after the primary extraction — unifying the `if (_isEditing) { await cubit.updateDebt(...) } else { await cubit.createDebt(...) }` branch into one ternary-returning helper method.
- Also trimmed some incidental whitespace/comment lines (compacted `_pickDate`'s single-statement `if`, one-line doc comment, removed non-essential blank lines between field declarations) purely to make the 150-line budget after `dart format` — no behavior change.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - correctness requirement] Split the two-widget file to satisfy the 150-line-per-file must_have**

- **Found during:** Task 2
- **Issue:** The plan instructed creating one file (`debt_form_fields.dart`) holding both `DebtDirectionToggle` and `DebtFormFields`. After writing both widgets there and running `dart format` (canonical for this repo), the file was 171 lines, breaching the plan's own `must_haves.truths: "every new file is at or under 150 lines"`.
- **Fix:** Moved `DebtDirectionToggle` to a new file, `lib/presentation/finance/widgets/debt/debt_direction_toggle.dart` (42 lines). `debt_form_fields.dart` now holds only `DebtFormFields` (125 lines).
- **Files modified:** `lib/presentation/finance/widgets/debt/debt_form_fields.dart` (rewritten, minus `DebtDirectionToggle`), new `lib/presentation/finance/widgets/debt/debt_direction_toggle.dart`, `lib/presentation/finance/screens/debt_form_screen.dart` (added the extra import).
- **Verification:** `wc -l` on all four files confirms ≤150; `flutter analyze lib/presentation/finance/` reports zero new errors/warnings/infos beyond the pre-existing 31 unrelated ones.
- **Committed in:** `064311f`

---

**Total deviations:** 1 (file-split to satisfy an explicit plan constraint, not a code bug)
**Impact on plan:** None on scope or behavior — same two widgets exist with identical props/behavior as specified, just in two files instead of one. `debt_form_screen.dart` imports both.

## Issues Encountered
- No existing widget test covers `debt_form_screen.dart` (plan's own `<verification>` note: "Manual on-device smoke pass (no existing test for this screen)"). This is a headless execution environment with no attached device/emulator, so the on-device smoke pass specified in Task 2's acceptance criteria (create a "to pay" and a "to receive" debt, save, reopen, confirm fields including direction persisted) could **not** be performed by this executor. All automated verification available in this environment passed: `flutter analyze lib/presentation/finance/` clean of new issues, all `test/application/finance/` tests green (32/32, includes `debt_cubit_test.dart`), and the `_save()`/`buildDebtToSave()` logic is unchanged from the pre-refactor code path (verbatim move, confirmed by diff review) so no new runtime risk was introduced beyond what a code review can catch. **Recommend a human run the on-device smoke pass described in the plan before this phase is considered fully closed.**

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `debt_form_screen.dart` closes the debt-form architecture violation (327 → 150 lines).
- No other plan in this wave depends on this plan's outputs (`affects: []` in frontmatter).
- On-device manual verification for direction-toggle persistence is still outstanding — flag for the next human-verify checkpoint or a follow-up quick task.

---
*Phase: 06-architecture-compliance*
*Completed: 2026-08-12*

## Self-Check: PASSED

All created files verified present on disk:
- `lib/presentation/finance/debt_form_logic.dart` — FOUND
- `lib/presentation/finance/widgets/debt/debt_direction_toggle.dart` — FOUND
- `lib/presentation/finance/widgets/debt/debt_form_fields.dart` — FOUND
- `lib/presentation/finance/screens/debt_form_screen.dart` — FOUND (modified)

All task commit hashes verified present in git log:
- `fb754fe` — FOUND
- `064311f` — FOUND
