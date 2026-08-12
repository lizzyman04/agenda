---
phase: 06-architecture-compliance
plan: 18
subsystem: tooling
tags: [documentation, readme, ci, github-actions, architecture-guard, dart, flutter]

# Dependency graph
requires:
  - "06-01 (built the guard in informational mode and recorded the literal README-scope decision this plan implements)"
  - "06-02 through 06-17 (every file split and directory nesting — the final tree this plan documents and locks in)"
provides:
  - "A README.md in all 36 directories under lib/presentation/ and lib/application/ — SC-3 closed"
  - "tool/check_architecture.dart in enforcing mode: exit 1 on any violation, remediation hint on stderr"
  - ".github/workflows/ci.yml runs the guard on every push/PR, between Analyze and Test"
affects:
  - "every future PR: a new lib/presentation/ or lib/application/ directory without a README.md, a hand-written file over 150 lines, or a directory over 10 hand-written .dart files now fails CI"

tech-stack:
  added: []
  patterns:
    - "Per-directory README as an enforced architectural artifact, not a convention"
    - "Umbrella directories get short pointer READMEs rather than a guard exemption"

key-files:
  created:
    - "34 README.md files: all 14 directories under lib/application/, and 20 of the 22 under lib/presentation/ (the other 2 already existed and were updated)"
  modified:
    - "lib/presentation/tasks/form/README.md (refreshed to the post-wave file set and line counts)"
    - "lib/presentation/finance/goals/README.md (goal_form_fields.dart added; pointers to the new sub-READMEs)"
    - "tool/check_architecture.dart (informational → enforcing)"
    - "tool/architecture_exemptions.dart (comment only: readmeExemptDirs confirmed empty)"
    - ".github/workflows/ci.yml (new Architecture guard step)"

decisions:
  - "The literal reading of SC-3 stands: all 36 directories get a README, including the five pure-umbrella ones (lib/application/, lib/application/shared/, lib/application/tasks/, lib/application/finance/, lib/presentation/). readmeExemptDirs stays empty — an umbrella gets a short pointer README rather than an exemption, so the guard needs no 'does this directory have direct files' branching."
  - "Guard failures go to stderr, not stdout, and carry a remediation hint naming tool/architecture_exemptions.dart — a CI failure should say what to do next."
  - "dart format enforcement was NOT added to CI. Measured, not assumed: dart format --set-exit-if-changed lib test reports 103 of 258 files changed. Enforcing it would reformat ~103 untouched files and push several past the 150-line cap, breaking SC-1 in the same commit that locks it in."
  - "No raw column-width check was added. 88 raw lines in non-generated code exceed 80 characters while lines_longer_than_80_chars reports 0, because the lint exempts unsplittable tokens (mostly the long import URIs that 06-16/17's nesting created). A column-counting guard would flag 88 files the analyzer considers clean. Width policing defers to the lint."

metrics:
  duration: ~45min
  tasks: 3
  files_changed: 39
  completed: 2026-08-12
---

# Phase 06 Plan 18: README Coverage and CI Enforcement Summary

Wrote a substantive README in all 36 `lib/presentation/` and
`lib/application/` directories, then flipped `tool/check_architecture.dart`
from informational-only to enforcing and wired it into CI between Analyze
and Test — closing SC-3 and making all three architecture rules
un-mergeable to violate.

## What Was Built

### Task 1 — Task-side and shared READMEs (`ffe9f25`)

17 new READMEs plus a refresh of the existing `tasks/form/README.md`,
covering all 18 directories under `lib/application/` (excluding
`finance/`), `lib/presentation/` itself, and `lib/presentation/tasks/`.
(The commit message says "16 new" — it undercounts by one; the commit's
own stat line, 18 files changed, is authoritative.)

Directories with direct `.dart` files got a file/role table with line
counts, following `form/README.md`'s format, plus a "Conventions in this
slice" section stating the rules that directory actually enforces (screens
own state, sheets own controllers, cards render nothing when empty, the
GTD tree contains no widgets). The five pure-umbrella directories got
short pointer READMEs — what they group, and where to look next.

`presentation/tasks/form/README.md` was stale: plans 06-02/03 and the
`227d030` extraction pass had added `task_form_pickers.dart`,
`task_form_gtd_entry.dart`, `task_form_save_feedback.dart`,
`widgets/task_form_app_bar.dart` and `widgets/finance_link_card.dart`, and
every line count in its tables had moved. It was rewritten as the
sub-slice overview (top-level table + slice-wide conventions) with the
per-directory detail moved into the four new sub-READMEs.

### Task 2 — Finance-side READMEs (`fd01d97`)

17 new READMEs plus an update to the existing `finance/goals/README.md`,
covering all 7 directories under `lib/application/finance/` and all 10
under `lib/presentation/finance/`.

`presentation/finance/` was documented as a real directory, not an
umbrella: it holds the four `*_form_logic.dart` files plus
`transaction_form_model.dart`, and its README states the convention they
establish — *load and save logic for a finance form lives beside the slice
as a plain function file, not inside the screen* — along with the
boundary that sends `transaction_form_submit.dart` to
`widgets/transaction/` instead (it needs a cubit and a `BuildContext`, so
it cannot live in the deliberately widget-free logic file).

`goals/README.md` gained `goal_form_fields.dart` in its widgets table (added
by 06-15) and pointers to the two new sub-READMEs; its controller-lifecycle
post-mortem was left intact and is now cross-referenced from
`presentation/README.md` and `widgets/budget/README.md`.

### Task 3 — Enforcement (`88949ec`)

`tool/check_architecture.dart`: the `exit(0)`-on-failure branch became
`exit(1)`, violations moved from stdout to stderr, the `[informational
only — not yet enforced in CI]` tag was dropped from the FAIL line, the
file header now describes enforcing mode, and a remediation hint was added
pointing at `tool/architecture_exemptions.dart`.

`.github/workflows/ci.yml`: a three-line `Architecture guard` step between
`Analyze` and `Test`.

`tool/architecture_exemptions.dart`: comment-only change recording that
`readmeExemptDirs` is empty *by compliance*, not by deferral.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `tool/check_architecture.dart` edited, though it
is not in the plan's `files_modified`**

- **Found during:** Task 3
- **Issue:** The plan's `files_modified` lists only README files,
  `ci.yml` and `architecture_exemptions.dart`, but its own `must_haves`
  require "the guard is now enforcing, not just informational" and its
  objective says "flip the guard from informational-only to CI-enforcing".
  The guard hardcoded `exit(0)` on failure (06-01's informational mode),
  so wiring it into CI without touching it would have added a step that
  can never fail — enforcement in name only.
- **Fix:** Changed the failure branch to `exit(1)`, moved violation output
  to stderr, removed the informational-mode wording, added a remediation
  hint. Verified both directions by temporarily deleting a README.
- **Files modified:** `tool/check_architecture.dart`
- **Commit:** `88949ec`

**2. [Rule 1 - Bug] Plan's directory inventory was out of date in two
places**

- **Found during:** Tasks 1 and 2
- **Issue:** The plan predicted `presentation/finance/widgets/` would be a
  pure umbrella needing only a pointer README; it in fact holds 8 direct
  `.dart` files. It also listed `presentation/finance/` as holding four
  form-logic files; it holds five (`transaction_form_model.dart` was not
  in the list). Writing to the plan's inventory would have produced two
  READMEs that misdescribe their directory.
- **Fix:** Enumerated with `find` at execution time as the plan itself
  instructs, and gave `widgets/` a full 8-row file/role table.
- **Files modified:** `lib/presentation/finance/widgets/README.md`,
  `lib/presentation/finance/README.md`
- **Commit:** `fd01d97`

**3. [Rule 1 - Bug] Two first-draft README claims were wrong on
measurement**

- **Found during:** Tasks 1 and 2 self-review
- **Issue:** `widgets/detail/README.md` attributed waiting-for to
  `TaskDetailFlagsCard` (it is on the GTD card; the flags card is
  urgent / important / next-action), and two READMEs called their
  directory "at the ten-file cap" when both hold 8 files.
- **Fix:** Verified against the source with `grep` and corrected all three
  claims before committing. A README that misdescribes its directory is
  worse than none.
- **Files modified:** `lib/presentation/tasks/widgets/detail/README.md`,
  `lib/presentation/finance/widgets/README.md`,
  `lib/presentation/finance/widgets/transaction/README.md`
- **Commits:** `ffe9f25`, `fd01d97`

### Deliberately Not Done

- **`dart format --set-exit-if-changed` was not added to CI.** Not in the
  plan, and measured here as genuinely breaking: 103 of 258 files in
  `lib/`+`test/` differ from `dart format` output, and several would cross
  the 150-line cap if reformatted. STATE.md's CORRECTION block on this was
  read and honoured.
- **No raw column-width guard was added.** `lines_longer_than_80_chars`
  reports 0 while 88 raw lines exceed 80 characters, because the lint
  exempts unsplittable tokens — mostly the long `import` URIs 06-16/17
  created. A column-counting check would flag files the analyzer considers
  clean.

## Verification

### 1. Guard passes, enforcing, no "informational only" wording

```
$ dart run tool/check_architecture.dart
Documented exemptions in effect:
  - lib/core/constants/currencies.dart — Flat ISO 4217 data table (single static const List<Currency>) — splitting by line range fragments a single semantic unit and destroys Ctrl+F lookup for a currency code, for zero readability gain. See 6-RESEARCH.md Split-or-Exempt Recommendations.

Architecture guard: PASS
exit: 0
```

### 2. Guard genuinely fails on a violation

Temporarily removed `lib/application/tasks/day_planner/README.md`:

```
$ dart run tool/check_architecture.dart
Documented exemptions in effect:
  - lib/core/constants/currencies.dart — ...

Architecture guard: FAIL (1 violation(s))
  - README lib/application/tasks/day_planner: missing README.md

Split the file, nest the directory, or add a documented, justified entry to tool/architecture_exemptions.dart. An exemption without a written justification is a rule with a hole in it.
exit: 1
```

Restored, re-ran: `Architecture guard: PASS` / `exit after restore: 0`.

### 3. Analyze clean (SC-5)

```
$ flutter analyze --no-fatal-infos --fatal-warnings
65 issues found. (ran in 22.6s)
ANALYZE EXIT: 0
```

All 65 are info-level — identical to the pre-plan baseline. Zero errors,
zero warnings, zero `lines_longer_than_80_chars`.

### 4. Full suite green (SC-4)

```
01:35 +265: All tests passed!
TEST EXIT: 0
```

265/265, unchanged from baseline. This plan added no tests: it touched no
`lib/` source, only README files and tooling.

### 5. README coverage (SC-3)

```
$ find lib/application lib/presentation -type d | wc -l
36
$ find lib/application lib/presentation -name README.md | wc -l
36
```

Diffed the two lists directory-by-directory — identical, one-to-one, no
directory doubled up and none missed.

### 6. CI diff

```diff
       - name: Analyze
         run: flutter analyze --no-fatal-infos --fatal-warnings
 
+      - name: Architecture guard
+        run: dart run tool/check_architecture.dart
+
       - name: Test
         run: flutter test --no-pub --coverage
```

## Not Verified

**No on-device or emulator run was possible** — there is no device or
emulator in this execution environment. This is a documentation and CI
plan that changed zero `lib/` source files, so runtime behaviour cannot
have moved; but the phase-level advice from 06-16/17 stands: a human
on-device pass before merging Phase 6 as a whole is still worthwhile,
since the phase moved every finance and task file.

## Phase 06 Success Criteria — Final State

| SC | Criterion | State |
|----|-----------|-------|
| SC-1 | No hand-written file over 150 lines | Closed (06-02…15); guard reports zero LINES violations, one documented exemption (`currencies.dart`) |
| SC-2 | No directory over 10 hand-written `.dart` files | Closed (06-16/17); guard reports zero FILES violations |
| SC-3 | README in every presentation/application nest | **Closed by this plan** — 36/36 |
| SC-4 | Full suite green | 265/265 |
| SC-5 | `flutter analyze` clean | exit 0, 65 infos, 0 errors/warnings |

## Known Stubs

None. This plan created no code.

## Threat Flags

None. No new network endpoint, auth path, file access pattern, or schema
change. The one threat in the plan's register (T-06-18-01, a CI
false-positive blocking merges) was mitigated as specified: the guard was
confirmed PASS locally, and its exit-1 path was exercised deliberately
before the CI step was committed.

## Commits

| Commit | Task | Description |
|--------|------|-------------|
| `ffe9f25` | 1 | 16 new READMEs for application/ + presentation/tasks/; form/README.md refreshed |
| `fd01d97` | 2 | 17 new READMEs for finance application + presentation; goals/README.md updated |
| `88949ec` | 3 | Guard flipped to enforcing; CI step added after Analyze |
| `482bd47` | 3 | Comment fixup: README count in `readmeExemptDirs` doc |

## Self-Check: PASSED

- All 36 claimed README paths exist (`find … -name README.md | wc -l` = 36,
  diffed one-to-one against the directory list).
- `.planning/phases/06-architecture-compliance/06-18-SUMMARY.md`,
  `.github/workflows/ci.yml`, `tool/check_architecture.dart`,
  `tool/architecture_exemptions.dart` all present.
- All four commit hashes (`ffe9f25`, `fd01d97`, `88949ec`, `482bd47`)
  resolve in `git log`.
- Guard re-run after the final commit: PASS, exit 0.
