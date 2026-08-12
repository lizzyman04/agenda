---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
stopped_at: Completed 03.1-16-PLAN.md (Wave 3) — domain/finance nested, 93 consumer files repointed
last_updated: "2026-08-12T13:13:22.939Z"
progress:
  total_phases: 6
  completed_phases: 3
  total_plans: 33
  completed_plans: 32
  percent: 97
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-21)

**Core value:** Open AGENDA at any moment and immediately see what needs doing and where the money stands — no internet connection ever required.
**Current focus:** Phase 03.1 — architecture-compliance

## Current Position

Phase: 03.1 (architecture-compliance) — EXECUTING
Plan: 18 of 18
Status: Ready to execute

**Resume state — read before dispatching anything:**

- `03.1-01` through `03.1-17` COMPLETE, SUMMARY.md written for each. Waves 1, 2, 3 and 4 of 5 are closed.
- `03.1-16` (Wave 3) DONE — `lib/domain/finance/` nested into six per-entity subfolders (`transaction/`, `budget/`, `goal/`, `debt/`, `recurring/`, `category/`) via `git mv`; 93 consumer files across `lib/` and `test/` repointed; `injection.config.dart` regenerated.
- `03.1-17` (Wave 4) DONE — `lib/data/finance/` nested into **the identical six subfolders**; 24 files moved via `git mv` (18 hand-written + 6 Isar `.g.dart`, each model co-moved with its companion in one command); 27 consumer files repointed; `build_runner` re-run, `injection.config.dart` genuinely regenerated (alias numbers changed). `lib/infrastructure/finance/` was **not** nested — 6 files, under the cap, only its imports were rewritten.
- `03.1-18` (Wave 5) NEXT. Wires the guard into CI; everything else has landed.

Post-Wave-4 measurements (03.1-17 branch):

- `dart run tool/check_architecture.dart`: **ZERO line-count violations AND ZERO directory-size violations** (35 → 34). SC-1 and SC-2 are both closed. All 34 remaining violations are missing per-nest READMEs — 03.1-18's entire remaining job. Note `lib/data/` is outside the README check's scope (`lib/presentation/` + `lib/application/` only), so 03.1-17's six new subfolders added no README debt.
- `flutter test`: 265/265 passing — unchanged.
- `flutter analyze --no-fatal-infos --fatal-warnings` (the CI invocation): exit 0, 65 infos — identical to the pre-plan baseline. The only issue-level delta is one pre-existing `unintended_html_in_doc_comment` whose file path moved.
- `flutter analyze --no-fatal-infos | grep -c lines_longer_than_80_chars`: **0**, measured after the nesting, not assumed.
- `dart format` parity: 103/258 dirty before and after, the same file set modulo this plan's own renames. See Blockers for the contradiction 03.1-18 must still settle.
- **NOT verified:** no on-device / emulator cold-start check was possible in the execution environment for either 03.1-16 or 03.1-17. Isar collection names are unchanged (only file locations moved) and the DI resolution test plus the full suite are green, but a human on-device pass before merging the phase is still advisable.

**RESOLVED (commit `227d030`) — the 150-line vs 80-column tension.** The four densest
split files (`task_form_screen.dart`, `task_form_fields.dart`,
`transaction_form_screen.dart`, `recurring_payment_form_fields.dart`) previously sat under
the 150-line cap only by using compact, non-`dart format` formatting; formatting them
pushed them to 178/195/190/188. That was closed by extraction rather than reflowing:
11 new files (form models, picker helpers, app-bar builders, submit helpers, scaffolds),
after which all four are both `dart format`-clean **and** under the cap (149/141/144/141).

Current state on main: `lines_longer_than_80_chars` is **0 project-wide** (was 58). Note
the extracted screens still have no widget tests, so this was verified by
`flutter analyze` + the existing 265-test suite, not by UI-level regression tests.

**CORRECTION — an earlier version of this note told 03.1-18 that requiring `dart format`
would be a no-op. That was wrong; do not act on it.** The clean-format claim was only ever
true of the ~16 files the extraction pass touched, not the tree. Measured on `f2c612f`:
`dart format --set-exit-if-changed lib test` reports **103 of 258 files changed**.
Enforcing `dart format` is therefore a real migration that would reformat ~103 untouched
files, and several of them would cross the 150-line cap and break SC-1. **03.1-18 must
decide the order deliberately** — most likely raise or exempt the cap first, or scope
formatting to changed files only.

Column width is the separate, easier half: the two limits do **not** in fact conflict,
because `lines_longer_than_80_chars` exempts lines with no whitespace past column 80.
88 raw lines in non-generated code exceed 80 characters while the lint reports 0 — 83 are
`import`/`export` URIs (unsplittable; 03.1-16's nesting made them longer and there is no
legal break point) and 5 are trailing unbreakable tokens. So a guard that counts raw
columns would flag 88 files the analyzer considers clean. If 03.1-18 polices width, it
should defer to the lint rather than measure columns itself.

Phase 03 (finance-core) remains open behind it: code complete, but 3 UAT issues are unresolved (test 2 — category-name stub showing `#id` and a duplicated note; test 3 — SnackBar queueing on a second swipe inside the undo window; test 9 — task-link chip showing a raw id) plus an undiagnosed app-wide undo-timer defect where 5s SnackBars never dismiss. None of these block Phase 3.1, which is a pure refactor.

Baseline entering Phase 3.1: 230 tests passing, `flutter analyze` clean, 21 files over 150 lines, 2 directories over 10 files, 2 of 30 feature nests carrying a README.

Progress: [██████████] 97%

## Performance Metrics

**Velocity:**

- Total plans completed: 10
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Foundation | 5 | — | — |
| 2. Task Core | 5 | — | — |

**Recent Trend:**

- Last 5 plans: 03-01, 03-02, 03-03, 03-04 (partial), DI post-fix
- Trend: On track

*Updated after each plan completion*
| Phase 03.1 P16 | 35min | 2 tasks | 102 files |
| Phase 03.1 P17 | 25min | 2 tasks | 51 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- **Pre-Phase 1**: Use `isar_community` 3.3.2 — original `isar` package abandoned April 2023; API is drop-in compatible; all import paths use `package:isar_community/isar_community.dart`
- **Pre-Phase 1**: Add `infrastructure/` as sixth architectural layer between `data/` and `application/` — houses notification, backup, and app lock service implementations with Flutter/platform dependencies
- **Pre-Phase 1**: `@enumerated(EnumType.name)` is the project-wide convention for all Isar-persisted enums — prevents ordinal corruption on enum reordering
- **Pre-Phase 1**: Schema migration runner design — `schemaVersion` stored in SharedPreferences; migration blocks run inside `IsarService.open()`; `MigrationRunner` executes sequentially
- **Pre-Phase 1**: Notification ID strategy — deterministic derivation (e.g., `taskId * 10 + notificationType`); no separate ID registry; enables cancellation on delete/update and safe boot rescheduling
- **Pre-Phase 1**: Biometric unlock (DATA-06) is in v1 scope — `FlutterFragmentActivity` must replace `MainActivity` before any auth code is written
- **Pre-Phase 1**: Task search (TASK-11) is in v1 scope — Isar indexed field queries; index strategy finalized during Phase 2 schema design
- **Stack**: Flutter + isar_community + BLoC/Cubit + GetIt + injectable; minimum Flutter SDK 3.38.1
- **Architecture**: core/ → domain/ → data/ → infrastructure/ → application/ → presentation/ → config/; strict outer-depends-on-inner rule
- **Language**: All code/comments/enums in English; UI text in PT-BR by default with EN toggle
- **Phase 2**: EisenhowerQuadrant computed from isUrgent + isImportant flags at domain layer — not stored in Isar
- **Phase 2**: Soft delete via `deletedAt` field on ItemModel; 500-item query cap on active items
- **Phase 2**: `go_router` declared in pubspec but routing handled via `IndexedStack` + modal routes in Phase 2; go_router guard wired in Phase 5
- [Phase ?]: Phase 3.1: domain/finance nested into six per-entity subfolders (transaction, budget, goal, debt, recurring, category) — the same six names 03.1-17 must apply to data/finance
- [Phase ?]: Phase 3.1: data/finance nested into the same six per-entity subfolders as domain/finance (transaction, budget, goal, debt, recurring, category); Isar .g.dart companions co-located with their models — architecture guard now reports ZERO directory-size and ZERO line-count violations

### Pending Todos

None.

### Blockers/Concerns

- **BUG FOUND 2026-08-11 (Phase 3.1, plan 03.1-08) — amount parsing rejects PT-BR thousands separators.** `parseAmountCentsOrNull` in `lib/core/utils/amount_parser.dart` does `raw.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '')`, so `'1.250,50'` becomes `'1.250.50'` — two dots, invalid double — and returns `null`. A user typing an amount the natural PT-BR way gets it silently rejected. Separately, a leading `-` is stripped rather than rejected, so `'-5'` parses as **500 cents positive**. This is PRE-EXISTING behaviour duplicated across all four finance forms, not introduced by the refactor; plan 03.1-08 preserved it verbatim and unit-tested the real behaviour, which is correct for a pure refactor. Round-tripping is unaffected (`formatCentsForInput` emits no thousands separator), so this only bites on manual entry. **Fix in a separate task after Phase 3.1 — do not fix mid-refactor.**
- **Phase 2 research flag**: OEM Android notification behavior (Samsung/Xiaomi/Huawei) varies significantly; consider a focused research spike before Phase 4 notification scheduling architecture is finalized
- **Phase 4 research flag**: PT-BR comma decimal separator in CSV round-trip (`1.234,56`) has edge cases; dedicate a spike to locale-aware parsing before the backup feature spec is written
- **Phase 5 research flag**: iOS `inactive` vs `paused` lifecycle states for lock triggering behave differently on simulator vs real device; spike recommended before Phase 5 app lock implementation
- **RESOLVED (2026-06-02, commit ae397ae)**: Budget-limit-save `_dependents.isEmpty` crash. True root cause was a `TextEditingController` disposed too early (method-scope dispose right after the `showModalBottomSheet` await → "used after being disposed" during the dismiss transition → cascaded to the overlay `_dependents.isEmpty` assertion). Fixed by moving the sheet body into `_BudgetLimitSheet` (StatefulWidget that owns/disposes the controller). Reproducing widget test added (budget_limit_sheet_test.dart). Earlier provider-scope/pop-order attempts were unrelated to this cause.
- CONTRADICTION for 03.1-18 to settle: the 03.1-16 brief claimed 'dart format --set-exit-if-changed is clean' project-wide, but measured on main (f2c612f) it is NOT — 103 of 258 files in lib/+test/ differ from dart format output. STATE.md's narrower claim ('clean on every touched file') is the accurate one. 03.1-16 therefore verified format PARITY with baseline (dirty set byte-identical) rather than cleanliness. 03.1-18 must decide whether dart format is the project's formatter before wiring it into CI; enforcing it wholesale would reformat ~103 files and push several past the 150-line cap.
- For 03.1-18 (column-width guard): two domain/finance import URIs unavoidably exceed 80 columns after 03.1-16's nesting — '…/recurring/recurring_payment_repository.dart' (83) and '…/category/transaction_category_repository.dart' (85). A plain 'import uri;' has no legal line break, so a raw column-width guard would flag 16 unfixable import lines. The enforced lints_longer_than_80_chars lint exempts directive URIs and still reports 0. Any guard 03.1-18 adds must mirror that exemption.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260601-u6q | Fix finance form `_dependents.isEmpty` crash (hoist cubits above MaterialApp) | 2026-06-01 | d8dc04c | [260601-u6q-fix-finance-provider-scope](./quick/260601-u6q-fix-finance-provider-scope/) |
| 260614-w5e | Fix phase 02 code review findings CR-01 WR-03 WR-04 (+ recheck WR-01, finance-repo test stubs) — CLOSED 2026-06-15, suite green 206/206, no PR (solo local) | 2026-06-15 | 756b67d | [260614-w5e-fix-phase-02-code-review-findings-cr-01-](./quick/260614-w5e-fix-phase-02-code-review-findings-cr-01-/) |
| 260811-97x | Fix phase 03 UAT test-5 blocker: goal contribution sheet crash + the fixed-length-list persistence bug it masked; goals slice restructured to the 150-line/nested-folder rules — device-verified, suite green 211/211 | 2026-08-11 | a2f8e7d, f5347ba | [260811-97x-fix-goal-contribution-sheet-crash](./quick/260811-97x-fix-goal-contribution-sheet-crash/) |

## Session Continuity

Last session: 2026-08-12T13:13:10.648Z
Stopped at: Completed 03.1-16-PLAN.md (Wave 3) — domain/finance nested, 93 consumer files repointed
Resume file: None
