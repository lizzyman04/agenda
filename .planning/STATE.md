---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
stopped_at: Phase 03 gap-closure wave 1 (03-06, 03-08) MERGED into main and gated green. Wave 2 (03-07) not started. Phase 06 COMPLETE; Phases 04 and 05 not started.
last_updated: "2026-08-14T00:00:00.000Z"
progress:
  total_phases: 6
  completed_phases: 3
  total_plans: 42
  completed_plans: 35
  percent: 83
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-21)

**Core value:** Open AGENDA at any moment and immediately see what needs doing and where the money stands — no internet connection ever required.
**Current focus:** Phase 03 — finance-core (its 3 open UAT issues), then Phase 04.

## Current Position

Phase: 06 (architecture-compliance) — **COMPLETE AND CLOSED**
Plan: 18 of 18
Status: All 18 plans merged, goal-backward verification PASSED (5/5 must-haves), and
on-device UAT PASSED on a physical Infinix X6831 (Android 13). See 06-VERIFICATION.md.

**Renumbered 2026-08-12: this phase was `3.1` and is now `6`.** The decimal-insertion
number was dropped at the user's request; it is a normal integer phase that happens to have
been executed out of order, immediately after Phase 03 and before Phases 04 and 05. Every
artifact was renamed (`.planning/phases/06-architecture-compliance/`, `06-NN-PLAN.md`,
`06-NN-SUMMARY.md`) and 392 in-document references updated. Note that **git commit messages
still say `3.1`/`03.1`** — history was not rewritten, so `refactor(3.1-16): …` and
`docs(phase-03.1): …` refer to this phase.

**Next:** Phase 03's 3 unresolved UAT issues, then Phase 04 (notifications + backup).

**Verification result (06-VERIFICATION.md, independent re-measurement — not read from SUMMARYs):**

- SC-1 through SC-5 all verified. 204 hand-written files checked by a hand-rolled `find`/`wc`
  pass that deliberately bypassed the guard; exactly one file exceeds 150 lines and it is the
  single allowlist entry. The guard's own exclusion set was audited file-by-file — nothing
  hand-written is being wrongly skipped.
- All 36 READMEs are accurate, not just present: none omits a `.dart` file that exists in its
  directory, none names a file that does not exist, and every line count in every README file
  table matches the real file.
- Guard enforcement exercised by injecting one violation of each of the three rules — exit 1
  each time, tree restored clean.
- **All six regenerated Isar `*_model.g.dart` files are byte-identical to their pre-move
  versions** — collection name AND id hash unchanged. This materially lowers the 06-17
  migration risk that earlier notes flagged; the schema genuinely did not move.

**Three items surfaced by verification:**

1. The sole line-cap exemption, `lib/core/constants/currencies.dart`, protects a file with
   **zero importers** anywhere in `lib/` or `test/` — dead code staged for multi-currency work.
   The entry now carries a note. Delete file + exemption together if multi-currency is dropped.
2. The house rule covers `lib/` only. `tool/check_architecture.dart` is itself 182 lines and 16
   `test/` files exceed 150 — matching SC-1's literal wording, but the enforcer is exempt from
   the rule it enforces.
3. **On-device UAT: DONE and PASSED** (2026-08-12, physical Infinix X6831, Android 13). The
   pre-phase build's real 1 MB Isar database was backed up, upgraded in place with
   `adb install -r`, and cold-started: every task, transaction, goal and debt survived, balance
   unchanged at MT 3.800,00, zero Isar/schema/Dart errors in logcat. Transaction and task forms
   driven end-to-end. Full evidence in the 06-VERIFICATION.md addendum.

**Three pre-existing UI defects found during UAT — none are Phase 06 regressions**, each
confirmed by diffing against the pre-refactor source. Worth their own fix task:

- Two identical **X** close buttons in the GTD sheet header on step 1
  (`gtd/widgets/gtd_sheet_header.dart:47,73` — `canGoBack` false makes the left button a
  second close). Same logic existed at `task_form_screen.dart:892/919` pre-extraction.
- The **"Tamanho"** segmented control wraps unreadably: "Médio" renders as `M/éd/io`,
  "Pequeno" as `Pequen/o`, "Nenhum" as `Nenhu/m`; only "Grande" fits
  (`form/widgets/flags_size_notes_fields.dart:69`). Identical markup pre-extraction.
- Hardcoded unlocalised strings: `'Pergunta X de Y'` (PT-only) and
  `'8 questions to clarify & prioritize'` (EN-only, rendered inside the PT-BR UI). Both from
  commit `7275715` in Phase 02; neither goes through `AppLocalizations`.

Also reconfirmed on device: the Phase 03 undo-timer defect still reproduces (the delete
snackbar was still on screen after **12 seconds**, against a 5s duration), and the Phase 03
category-name stub (`#10`, `#1` as transaction titles) is present in the pre-Phase-06 build
too — both belong to Phase 03, not here.

**Resume state — read before dispatching anything:**

- **ALL 18 PLANS COMPLETE.** `06-01` through `06-18`, SUMMARY.md written for each. All five waves closed.
- `06-18` (Wave 5) DONE — READMEs written for all 36 directories under `lib/presentation/` + `lib/application/` (34 new, 2 refreshed), closing **SC-3**. `tool/check_architecture.dart` flipped from informational-only to **enforcing** (exit 1 on violation, violations to stderr) and wired into `.github/workflows/ci.yml` as an `Architecture guard` step between Analyze and Test. `readmeExemptDirs` stays empty — umbrella directories carry short pointer READMEs rather than exemptions.
- `06-18` settled the two open questions left for it: **`dart format` was NOT added to CI** (measured: 103 of 258 files differ from `dart format` output, several would cross the 150-line cap if reformatted) and **no raw column-width guard was added** (88 raw lines exceed 80 chars while `lines_longer_than_80_chars` reports 0, because the lint exempts unsplittable import URIs). Both blockers below are therefore resolved-by-decision, not deferred.

Post-Wave-5 measurements (06-18 branch, all verified not assumed):

- `dart run tool/check_architecture.dart`: **PASS, exit 0** — zero violations of all three rules. Exit-1 path exercised deliberately by deleting one README (reported the violation, exited 1) and restoring it.
- `flutter test --no-pub`: **265/265 passing**, exit 0.
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, 65 infos — unchanged from baseline.
- 36 directories, 36 READMEs, diffed one-to-one.
- On-device UAT has since been performed and PASSED (see above) — this note is superseded.

Earlier waves, for reference:

- `06-01` through `06-17` COMPLETE, SUMMARY.md written for each. Waves 1, 2, 3 and 4 of 5 are closed.
- `06-16` (Wave 3) DONE — `lib/domain/finance/` nested into six per-entity subfolders (`transaction/`, `budget/`, `goal/`, `debt/`, `recurring/`, `category/`) via `git mv`; 93 consumer files across `lib/` and `test/` repointed; `injection.config.dart` regenerated.
- `06-17` (Wave 4) DONE — `lib/data/finance/` nested into **the identical six subfolders**; 24 files moved via `git mv` (18 hand-written + 6 Isar `.g.dart`, each model co-moved with its companion in one command); 27 consumer files repointed; `build_runner` re-run, `injection.config.dart` genuinely regenerated (alias numbers changed). `lib/infrastructure/finance/` was **not** nested — 6 files, under the cap, only its imports were rewritten.
- `06-18` (Wave 5) — see above; it has now landed too.

Post-Wave-4 measurements (06-17 branch):

- `dart run tool/check_architecture.dart`: **ZERO line-count violations AND ZERO directory-size violations** (35 → 34). SC-1 and SC-2 are both closed. All 34 remaining violations are missing per-nest READMEs — 06-18's entire remaining job. Note `lib/data/` is outside the README check's scope (`lib/presentation/` + `lib/application/` only), so 06-17's six new subfolders added no README debt.
- `flutter test`: 265/265 passing — unchanged.
- `flutter analyze --no-fatal-infos --fatal-warnings` (the CI invocation): exit 0, 65 infos — identical to the pre-plan baseline. The only issue-level delta is one pre-existing `unintended_html_in_doc_comment` whose file path moved.
- `flutter analyze --no-fatal-infos | grep -c lines_longer_than_80_chars`: **0**, measured after the nesting, not assumed.
- `dart format` parity: 103/258 dirty before and after, the same file set modulo this plan's own renames. See Blockers for the contradiction 06-18 must still settle.
- Superseded: the on-device cold-start check for 06-16/06-17 was performed on 2026-08-12 and PASSED.

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

**CORRECTION — an earlier version of this note told 06-18 that requiring `dart format`
would be a no-op. That was wrong; do not act on it.** The clean-format claim was only ever
true of the ~16 files the extraction pass touched, not the tree. Measured on `f2c612f`:
`dart format --set-exit-if-changed lib test` reports **103 of 258 files changed**.
Enforcing `dart format` is therefore a real migration that would reformat ~103 untouched
files, and several of them would cross the 150-line cap and break SC-1. **06-18 must
decide the order deliberately** — most likely raise or exempt the cap first, or scope
formatting to changed files only.

Column width is the separate, easier half: the two limits do **not** in fact conflict,
because `lines_longer_than_80_chars` exempts lines with no whitespace past column 80.
88 raw lines in non-generated code exceed 80 characters while the lint reports 0 — 83 are
`import`/`export` URIs (unsplittable; 06-16's nesting made them longer and there is no
legal break point) and 5 are trailing unbreakable tokens. So a guard that counts raw
columns would flag 88 files the analyzer considers clean. If 06-18 polices width, it
should defer to the lint rather than measure columns itself.

Phase 03 (finance-core) remains open behind it: code complete, but 3 UAT issues are unresolved (test 2 — category-name stub showing `#id` and a duplicated note; test 3 — SnackBar queueing on a second swipe inside the undo window; test 9 — task-link chip showing a raw id) plus an undiagnosed app-wide undo-timer defect where 5s SnackBars never dismiss. None of these block Phase 6, which is a pure refactor.

Baseline entering Phase 6: 230 tests passing, `flutter analyze` clean, 21 files over 150 lines, 2 directories over 10 files, 2 of 30 feature nests carrying a README.

Progress: [██████████] 100%

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
| Phase 06 P16 | 35min | 2 tasks | 102 files |
| Phase 06 P17 | 25min | 2 tasks | 51 files |
| Phase 06 P18 | 45min | 3 tasks | 39 files |

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
- [Phase ?]: Phase 6: domain/finance nested into six per-entity subfolders (transaction, budget, goal, debt, recurring, category) — the same six names 06-17 must apply to data/finance
- [Phase ?]: Phase 6: data/finance nested into the same six per-entity subfolders as domain/finance (transaction, budget, goal, debt, recurring, category); Isar .g.dart companions co-located with their models — architecture guard now reports ZERO directory-size and ZERO line-count violations
- [Phase ?]: Phase 6: architecture guard is now ENFORCING in CI (exit 1 on violation, step runs between Analyze and Test); all 36 lib/presentation + lib/application directories carry a README, readmeExemptDirs stays empty
- [Phase ?]: Phase 6: dart format is NOT enforced in CI and no raw column-width guard was added — measured, 103/258 files differ from dart format output and 88 raw lines exceed 80 cols while the lint reports 0; width policing defers to lines_longer_than_80_chars

### Pending Todos

None.

### Blockers/Concerns

- **BUG FOUND 2026-08-11 (Phase 6, plan 06-08) — amount parsing rejects PT-BR thousands separators.** `parseAmountCentsOrNull` in `lib/core/utils/amount_parser.dart` does `raw.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '')`, so `'1.250,50'` becomes `'1.250.50'` — two dots, invalid double — and returns `null`. A user typing an amount the natural PT-BR way gets it silently rejected. Separately, a leading `-` is stripped rather than rejected, so `'-5'` parses as **500 cents positive**. This is PRE-EXISTING behaviour duplicated across all four finance forms, not introduced by the refactor; plan 06-08 preserved it verbatim and unit-tested the real behaviour, which is correct for a pure refactor. Round-tripping is unaffected (`formatCentsForInput` emits no thousands separator), so this only bites on manual entry. **Fix in a separate task after Phase 6 — do not fix mid-refactor.**
- **Phase 2 research flag**: OEM Android notification behavior (Samsung/Xiaomi/Huawei) varies significantly; consider a focused research spike before Phase 4 notification scheduling architecture is finalized
- **Phase 4 research flag**: PT-BR comma decimal separator in CSV round-trip (`1.234,56`) has edge cases; dedicate a spike to locale-aware parsing before the backup feature spec is written
- **Phase 5 research flag**: iOS `inactive` vs `paused` lifecycle states for lock triggering behave differently on simulator vs real device; spike recommended before Phase 5 app lock implementation
- **RESOLVED (2026-06-02, commit ae397ae)**: Budget-limit-save `_dependents.isEmpty` crash. True root cause was a `TextEditingController` disposed too early (method-scope dispose right after the `showModalBottomSheet` await → "used after being disposed" during the dismiss transition → cascaded to the overlay `_dependents.isEmpty` assertion). Fixed by moving the sheet body into `_BudgetLimitSheet` (StatefulWidget that owns/disposes the controller). Reproducing widget test added (budget_limit_sheet_test.dart). Earlier provider-scope/pop-order attempts were unrelated to this cause.
- **RESOLVED by 06-18 (decision: do not enforce).** `dart format` was deliberately NOT wired into CI. The measurement below was re-confirmed and the reformat would push several files past the 150-line cap, breaking SC-1 in the same commit that locks it in. If the project later adopts `dart format`, it must be its own plan: reformat first, re-split whatever crosses the cap, then enforce. Original note: the
- **RESOLVED by 06-18 (decision: defer to the lint).** No raw column-width guard was added; `lines_longer_than_80_chars` remains the only width authority. Original note follows.
- CONTRADICTION 06-18 settled: the 06-16 brief claimed 'dart format --set-exit-if-changed is clean' project-wide, but measured on main (f2c612f) it is NOT — 103 of 258 files in lib/+test/ differ from dart format output. STATE.md's narrower claim ('clean on every touched file') is the accurate one. 06-16 therefore verified format PARITY with baseline (dirty set byte-identical) rather than cleanliness. 06-18 must decide whether dart format is the project's formatter before wiring it into CI; enforcing it wholesale would reformat ~103 files and push several past the 150-line cap.
- For 06-18 (column-width guard): two domain/finance import URIs unavoidably exceed 80 columns after 06-16's nesting — '…/recurring/recurring_payment_repository.dart' (83) and '…/category/transaction_category_repository.dart' (85). A plain 'import uri;' has no legal line break, so a raw column-width guard would flag 16 unfixable import lines. The enforced lints_longer_than_80_chars lint exempts directive URIs and still reports 0. Any guard 06-18 adds must mirror that exemption.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260601-u6q | Fix finance form `_dependents.isEmpty` crash (hoist cubits above MaterialApp) | 2026-06-01 | d8dc04c | [260601-u6q-fix-finance-provider-scope](./quick/260601-u6q-fix-finance-provider-scope/) |
| 260614-w5e | Fix phase 02 code review findings CR-01 WR-03 WR-04 (+ recheck WR-01, finance-repo test stubs) — CLOSED 2026-06-15, suite green 206/206, no PR (solo local) | 2026-06-15 | 756b67d | [260614-w5e-fix-phase-02-code-review-findings-cr-01-](./quick/260614-w5e-fix-phase-02-code-review-findings-cr-01-/) |
| 260811-97x | Fix phase 03 UAT test-5 blocker: goal contribution sheet crash + the fixed-length-list persistence bug it masked; goals slice restructured to the 150-line/nested-folder rules — device-verified, suite green 211/211 | 2026-08-11 | a2f8e7d, f5347ba | [260811-97x-fix-goal-contribution-sheet-crash](./quick/260811-97x-fix-goal-contribution-sheet-crash/) |

## Session Continuity

Last session: 2026-08-14
Stopped at: Merged phase 03 gap-closure wave 1 into main — `worktree-agent-a02b75e60f0b5ed1c`
(plan 03-06, category names + single note) and `worktree-agent-a61e24f07fe8ace8d` (plan 03-08,
finance-chip title), both `--no-ff`, zero conflicts, no file overlap between them.

**Post-merge gate, measured on the merged tree (not inferred from the per-branch numbers):**

- `dart run tool/check_architecture.dart`: PASS, exit 0
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, **65 infos** — baseline unchanged
- `flutter test --no-pub`: **279/279 passing**, exit 0

The per-branch counts (03-06 reported 277, 03-08 reported 270, both against a 268 baseline) are
superseded by this single measurement. The two worktrees are now safe to remove.

**Next:** wave 2 = plan 03-07 (SnackBar FIFO queueing). It was deliberately serialized behind
03-06 because both edit `transaction_list_screen.dart`; it now rebases on a main that already
carries 03-06's version of that file. Then phase 03 verification, the 3 pre-existing UI defects,
and the on-device undo-timer re-test (still blocked on reattaching the Infinix X6831).

Resume file: .planning/HANDOFF.json (updated — 2 of 6 remaining tasks now closed)
