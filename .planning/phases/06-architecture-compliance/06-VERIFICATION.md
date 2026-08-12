---
phase: 06-architecture-compliance
verified: 2026-08-12T13:52:27Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
human_verification:
  status: completed 2026-08-12 on a physical device
  device: "Infinix X6831 — Android 13 (API 33), arm64-v8a, serial 099344034M008322"
  method: >-
    The build already installed on the device (2026-08-11 07:25, i.e. pre-Phase-6) carried a
    real 1 MB default.isar. It was backed up byte-identically (md5 cae5b902...), the
    post-Phase-6 debug APK was installed OVER it with `adb install -r` so app data survived,
    and the app was then cold-started. No wipe, no reinstall, no seeded fixture.
  results:
    - test: "Cold start against a pre-Phase-6 database"
      outcome: PASS
      evidence: >-
        Tasks 'Tarefa teste' and 'Pagar Joao' unchanged; Saldo atual MT 3.800,00 and
        Patrimonio liquido MT 4.050,00 identical before and after the upgrade; transactions
        #10 (MT 5.000,00) and 'Mercado semana' (MT 1.200,00) intact; spending pie chart
        renders. Savings goal 'Fundo Emergencia' and debt 'Emprestimo Joao' both load through
        the newly nested repositories. logcat shows IsarCore opening cleanly with zero Isar,
        schema, migration or Dart errors.
    - test: "Manual smoke of the extracted form screens"
      outcome: PASS
      evidence: >-
        Transaction form end-to-end: Receita/Despesa toggle flips filteredCategories (expense
        picker showed only expense categories), the goal-link row appears only for expenses
        (showGoalLink), date defaults to today, save persisted MT 250,00 and popped the form,
        and the dashboard recomputed to exactly 3.800 - 250 = MT 3.550,00. Swipe-delete
        removed it with the 'Transacao excluida / Desfazer' snackbar. Task form: GTD guide
        sheet opens and dismisses without corrupting form state, due-date picker opens fully
        PT-BR localised, advanced options expand, and the finance-link sheet lists the real
        goal and debt.
    - test: "Keyboard, focus and scroll behaviour"
      outcome: PASS_WITH_NOTE
      evidence: >-
        Correct keyboard per field type (numeric for Valor, QWERTY for Titulo) and scrolling
        works. Note: the task form autofocuses Titulo on open, so the keyboard covers the
        lower half of the form until dismissed. Pre-existing, not introduced by Phase 6.
  defects_found: 3
  defects_are_regressions: 0
---

# Phase 6: Architecture Compliance Verification Report

**Phase Goal:** Every hand-written source file is under 150 lines, every directory is nested by responsibility with no more than ~10 related files, and every feature nest carries a README documenting its responsibility and rules
**Verified:** 2026-08-12T13:52:27Z
**Status:** human_needed (all 5 roadmap Success Criteria verified by independent measurement; on-device UAT was never performed and is the outstanding item)
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

The ROADMAP defines **five** Success Criteria for this phase (the verification brief referenced SC-1..SC-3; SC-4 and SC-5 are part of the roadmap contract and were verified too).

| #   | Truth (ROADMAP Success Criteria)                                                                 | Status     | Evidence |
| --- | ------------------------------------------------------------------------------------------------ | ---------- | -------- |
| 1   | No hand-written file under `lib/` exceeds 150 lines (generated `*.g.dart` and `injection.config.dart` exempt) | ✓ VERIFIED | Independent `find lib -name '*.dart' ! -name '*.g.dart' ! -path 'lib/generated/*' ! -path '.../injection.config.dart' -exec wc -l` over 204 hand-written files: **exactly one** file over 150 — `lib/core/constants/currencies.dart` at 207, which is the single documented allowlist entry. Next largest is 150. Verified independently of the guard. |
| 2   | No directory under `lib/` holds more than 10 related source files                                  | ✓ VERIFIED | Independent per-directory count: maximum is **10** (`lib/presentation/tasks/form/widgets`), i.e. at the cap, not over. Next: 9, 8, 8, 8, 8. |
| 3   | Every feature directory under `lib/presentation/` and `lib/application/` contains a README.md stating its responsibility, contents and slice rules | ✓ VERIFIED | 36 directories enumerated, **36 READMEs present, 0 missing**. Quality audited programmatically across all 36 plus manually on 7 (both layers) — see "README Quality Audit" below. |
| 4   | The full test suite passes unchanged — pure refactor, no behaviour change                          | ✓ VERIFIED | `flutter test --no-pub` → **265/265 passing, exit 0** (measured, not read from SUMMARY). Baseline entering the phase was 230; +35 from 6 new test files, **0 test files deleted**, **0 `skip:` markers** anywhere in `test/`. Behaviour-preservation spot-checks on the riskiest splits all came back equivalent — see "Refactor Behaviour Spot-Checks". |
| 5   | `flutter analyze` reports no new errors or warnings                                                | ✓ VERIFIED | `flutter analyze --no-fatal-infos --fatal-warnings` → **exit 0**, 65 infos. `grep -cE "error •\|warning •"` over the full analyze output → **0**. `lines_longer_than_80_chars` count → **0**. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `tool/check_architecture.dart` | Enforcing three-rule guard | ✓ VERIFIED | 182 lines; three standalone testable functions; `exit(1)` on any violation, violations to stderr. Header comment accurately describes enforcing mode. |
| `tool/architecture_exemptions.dart` | Documented, justified allowlist | ✓ VERIFIED (with caveat) | `lineLimitExemptions` = 1 entry, `readmeExemptDirs` = **empty**. See "Exemption Allowlist Assessment" for the caveat. |
| `test/tool/check_architecture_test.dart` | Guard unit-tested against fixtures | ✓ VERIFIED | 142 lines, 11 tests across 3 groups: 151-line flagged, 150-line not flagged, exemption honoured, 11-file dir flagged, `.g.dart` not counted, missing/present README. Runs in the 265-test suite. |
| `.github/workflows/ci.yml` | Guard wired into CI | ✓ VERIFIED | `Architecture guard` step at line 41-42, positioned between `Analyze` and `Test`. No `continue-on-error`, no `\|\| true` — a non-zero exit fails the job. |
| 36 × `README.md` under `lib/presentation/`, `lib/application/` | Per-nest documentation | ✓ VERIFIED | 36/36 present, 23-78 lines each, 1472 lines total. No stub/placeholder text. |
| `lib/domain/finance/{transaction,budget,goal,debt,recurring,category}/` | Six-way nesting | ✓ VERIFIED | Present; consumer imports repointed; analyze clean. |
| `lib/data/finance/{transaction,budget,goal,debt,recurring,category}/` | Six-way nesting with co-located `.g.dart` | ✓ VERIFIED | Present; each `*_model.g.dart` sits beside its `*_model.dart`. |
| 6 × per-entity mapper files (from `finance_mappers.dart`) | Split of the 327-line monolith | ✓ VERIFIED | Normalised token-level diff of old monolith vs the 6 new files: **only differences are an import alias and one line-wrap**. Logic is byte-equivalent. |
| `lib/domain/tasks/item_copy_with.dart` + `lib/core/utils/copy_with_sentinel.dart` | `item.dart` sentinel/copyWith split | ✓ VERIFIED | `item.dart` re-exports both, so call sites are unchanged. Semantics preserved (see spot-checks). |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| CI workflow | `tool/check_architecture.dart` | `run: dart run tool/check_architecture.dart` | ✓ WIRED | Step exists and is unguarded; job fails on non-zero exit. |
| `check_architecture.dart` | `architecture_exemptions.dart` | `import 'architecture_exemptions.dart'` | ✓ WIRED | Both `lineLimitExemptions` and `readmeExemptDirs` are consumed as default parameter values and honoured (proved by the guard's own printed "Documented exemptions in effect" block). |
| `check_architecture.dart` `isGenerated()` | `analysis_options.yaml` `analyzer.exclude` | mirrored predicate | ✓ WIRED | Exact one-to-one match: `lib/generated/**`, `lib/config/di/injection.config.dart`, `**/*.g.dart`. All 7 `.g.dart` files carry the `// GENERATED CODE - DO NOT MODIFY BY HAND` header; `injection.config.dart` and `lib/generated/l10n/*` are genuine tool output. **No hand-written file is being wrongly skipped.** |
| `TransactionFormScreen` | `submitTransactionForm` / `loadTransactionFormData` | direct call | ✓ WIRED | Data flows: repositories → `TransactionFormData` → `setState` → rendered fields. |
| `TaskFormScreen` | `buildFormItem` / `showTaskSaveFailure` | direct call | ✓ WIRED | Save path and failure-snackbar path both reach the cubit and the localised message. |

### Independent Measurement (Level 4 — did I trust the guard?)

The brief asked for a measurement independent of the guard's own exclusion logic. Both were run:

| Check | Guard result | My independent result | Agree? |
| ----- | ------------ | --------------------- | ------ |
| Files over 150 lines | 0 violations, 1 exemption in effect | 1 file over 150 (`currencies.dart`, 207) — the exempted one | ✓ |
| Directories over 10 files | 0 violations | max 10 (`presentation/tasks/form/widgets`) | ✓ |
| Missing READMEs | 0 violations | 0 of 36 missing | ✓ |
| Generated-file exclusion set | 3 rules | audited each excluded file for a generator header / tool origin — all legitimate | ✓ |

One methodological note: the guard counts with `readAsLinesSync().length`, `wc -l` counts newlines. These differ by 1 for a file with no trailing newline, so a `wc`-150 file could be a guard-151 file. All five files sitting at exactly 150 were checked — **all have trailing newlines**, so the two methods agree.

### README Quality Audit

Presence alone is not the criterion. Every one of the 36 READMEs was cross-checked programmatically, and 7 were read in full (4 presentation, 3 application: `lib/presentation`, `lib/application`, `presentation/tasks/form/widgets`, `presentation/finance/widgets/transaction`, `presentation/finance/goals`, `application/tasks/task_list`, `application/finance/dashboard`).

| Check (all 36 dirs) | Result |
| ------------------- | ------ |
| README omits a `.dart` file that actually exists in its directory | **0 occurrences** |
| README names a `.dart` file that does not exist anywhere in the repo | **0 occurrences** (the only unresolved token is `flutter/widgets.dart`, a package reference) |
| README's file table states a line count that disagrees with the actual file | **0 mismatches** across every table row in every README |
| Placeholder / TODO / "coming soon" filler text | 1 hit — `presentation/finance/widgets/dashboard/README.md` uses the word "placeholder" to *document* a hardcoded MZN currency symbol as a deliberate dev default pending D-16. This is honest documentation, not stub text. |

Manual reading confirms the prose is specific rather than generic: `presentation/finance/goals/README.md` carries a full post-mortem of the controller-disposal crash with commit references and the names of the two regression tests; `application/tasks/task_list/README.md` explains why undo is modelled as a state rather than a timer side effect; `presentation/tasks/form/widgets/README.md` explicitly notes the directory is at the 10-file cap and states what a new field group must do instead. Spot-verified `presentation/finance/goals`: its README's screens/widgets tables list exactly the 3 + 6 files that are actually on disk.

### Guard Enforcement Verification (negative testing)

The guard exiting 0 today proves nothing on its own. All three rules were deliberately violated and the tree restored afterwards (`git status` confirmed clean at the end):

| Injected violation | Guard exit | stderr |
| ------------------ | ---------- | ------ |
| (none — current tree) | **0** | `Architecture guard: PASS` |
| 200-line file added at `lib/core/__guard_probe_tmp.dart` | **1** | `LINES  lib/core/__guard_probe_tmp.dart: 200 > 150` |
| 11 `.dart` files in `lib/core/__guard_probe_dir/` | **1** | `FILES  lib/core/__guard_probe_dir: 11 hand-written files > 10` |
| `lib/application/finance/dashboard/README.md` removed | **1** | `README lib/application/finance/dashboard: missing README.md` |
| (all probes reverted) | **0** | `Architecture guard: PASS` |

The CI step is a plain `run:` with no `continue-on-error` and no exit-code suppression, so each of the above would fail the `Analyze & Test` job. The guard also runs *before* `Test`, so a violation fails fast.

### Refactor Behaviour Spot-Checks

SC-4 claims a pure refactor. Rather than trust that, the riskiest splits were diffed against their pre-refactor sources.

| Split | Method | Result |
| ----- | ------ | ------ |
| `finance_mappers.dart` (327 lines) → 6 per-entity mappers | Normalised token-multiset diff, old vs new | ✓ Equivalent. Only deltas: 2 × `as domain;` import-alias lines and one statement re-wrapped across two lines. |
| `item.dart` → entity + `item_copy_with.dart` + `copy_with_sentinel.dart` | Read both versions of `copyWith` | ✓ Equivalent. The mechanism changed from `x is _Absent` to `identical(x, clearField)` because `_Absent` is no longer visible in the extension's library. Since `_Absent` is a private, const-only class with exactly one canonicalised instance, the two predicates are provably the same. All 24 fields checked. |
| Isar model relocation (06-17) | Byte-diff of each regenerated `*_model.g.dart` against its pre-move version | ✓ **All six byte-identical.** Collection `name:` and the `id:` hash are unchanged for `TransactionModel`, `BudgetModel`, `SavingsGoalModel`, `DebtModel`, `RecurringPaymentModel`, `TransactionCategoryModel`. This is materially stronger evidence than STATE.md's "collection names derive from unchanged class names". |
| `transaction_form_screen.dart` (587 → 149 lines) | Read old `_save`, `_loadCategories`, `_loadGoals`, `initState` vs new screen + `transaction_form_logic.dart` + `transaction_form_submit.dart` | ✓ Equivalent. `formatCentsForInput(0)` returns `''`, matching the old `tx != null ? ... : ''` pre-fill. Validation order, snackbar behaviour (`SnackBarBehavior.floating`), create-vs-edit construction and `mounted` guards all preserved. |
| `recurring_payment_form_screen.dart` | Same method | ✓ Equivalent. `showFormError` preserves `SnackBarBehavior.floating`; `buildRecurringPaymentToSave` preserves `isActive: true` on create. |
| `task_form_screen.dart` → screen + logic + fields model + feedback helper | Same method, against the phase-baseline commit (`aac7cf5`) | ✓ Equivalent. The `parentId` subtask invariant and the `linkedGoalId ?? clearField` / `linkedDebtId ?? clearField` edit-path behaviour were moved verbatim (initially suspected as new — confirmed pre-existing at the baseline, where it was wrapped across two lines). `showTaskSaveFailure` reproduces the old state-derived error message with the same localised fallback. |
| `item_repository_impl.dart` → `part` + private mixin | Read both files | ✓ Class identity preserved — still one `ItemRepositoryImpl` implementing all 12 `ItemRepository` methods; no interface change, no extra DI registration. |

**One non-regression behavioural nuance found:** the old transaction form fired `_loadCategories()` and `_loadGoals()` concurrently, each with its own `setState`; the new `loadTransactionFormData` awaits them sequentially and does one `setState`. The end state is identical and the loading flag is handled the same way; only the intermediate render sequence differs marginally. Not a correctness change.

### Exemption Allowlist Assessment

The allowlist is small and disciplined: **one** line-cap exemption, **zero** README exemptions.

`lib/core/constants/currencies.dart` (207 lines): verified to be exactly what the justification claims — a `Currency` value class plus a single flat static list of ~157 ISO 4217 entries, one per line. Splitting it by line range genuinely would fragment a single semantic unit. The exemption is **legitimate, not a cover for skipped work**.

**Caveat (WARNING, not a violation):** this file is **dead code**. `grep` across all of `lib/` and `test/` finds zero references to `currencies.dart`, `Currency(` or any currency list outside the file itself. It was added in Phase 03-01 and has never been imported. The written justification argues from Ctrl+F ergonomics without disclosing that no code reads the file at all. The exemption should record this — an exemption for an unreferenced file is weaker than it reads.

`readmeExemptDirs` being empty is a real result, not a technicality: the two umbrella directories (`lib/presentation/`, `lib/application/`) carry genuine pointer READMEs rather than exemptions, and both were read and are substantive.

### Requirements Coverage

Phase 6 declares **no** requirement IDs (`**Requirements**: (none — internal quality)` in ROADMAP.md). No orphaned requirements are mapped to Phase 6 in REQUIREMENTS.md. Nothing to cover.

### Behavioural Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Guard passes on the current tree | `dart run tool/check_architecture.dart` | exit 0, `Architecture guard: PASS` | ✓ PASS |
| Guard fails on an over-length file | probe file + guard | exit 1 with `LINES` violation | ✓ PASS |
| Guard fails on an over-full directory | probe dir + guard | exit 1 with `FILES` violation | ✓ PASS |
| Guard fails on a missing README | README moved + guard | exit 1 with `README` violation | ✓ PASS |
| Full test suite green | `flutter test --no-pub` | `+265: All tests passed!`, exit 0 | ✓ PASS |
| Static analysis clean | `flutter analyze --no-fatal-infos --fatal-warnings` | exit 0, 65 infos, 0 errors, 0 warnings | ✓ PASS |
| 80-column lint clean | `flutter analyze --no-fatal-infos \| grep -c lines_longer_than_80_chars` | 0 | ✓ PASS |
| Formatter parity claim | `dart format --output=none --set-exit-if-changed lib test` | `258 files (103 changed)` — confirms the documented 103/258 | ✓ PASS (claim accurate) |
| Working tree unchanged after probing | `git status --porcelain` | clean | ✓ PASS |

### Probe Execution

No `scripts/*/tests/probe-*.sh` files exist in this project and no PLAN or SUMMARY in this phase declares a probe. The equivalent role is played by `tool/check_architecture.dart` and `test/tool/check_architecture_test.dart`, both of which were executed above.

| Probe | Command | Result | Status |
| ----- | ------- | ------ | ------ |
| Architecture guard (project's de-facto probe) | `dart run tool/check_architecture.dart` | exit 0 | PASS |
| Guard fixture tests | included in `flutter test --no-pub` | 11 tests green | PASS |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| — | — | `TBD` / `FIXME` / `XXX` in `lib/` or `tool/` | — | **None found.** Zero debt markers. |
| — | — | `TODO` / `HACK` / `PLACEHOLDER` in `lib/` or `tool/` | — | **None found.** |
| `lib/core/constants/currencies.dart` | file | Dead code — never imported, and it is the sole allowlist exemption | ⚠️ Warning | Not a SC violation; predates the phase. The exemption justification omits that the file is unreferenced. |
| `lib/core/extensions/datetime_extensions.dart`, `lib/core/extensions/string_extensions.dart` | file | Dead code — never imported | ℹ️ Info | Added in Phase 01-01, predates this phase, under the line cap. |
| `lib/config/di/infrastructure_module.dart` | 10 | `abstract class InfrastructureModule {}` — empty, and absent from the regenerated `injection.config.dart` | ℹ️ Info | Pre-existing DI scaffolding, not wired. Out of Phase 6 scope. |
| `tool/check_architecture.dart` | 182 lines | The guard exceeds its own 150-line cap | ℹ️ Info | Literal SC-1 scope is "under `lib/`", so not a violation — but the enforcer is exempt from the rule it enforces. |
| `test/` (16 files) | — | 16 test files exceed 150 lines | ℹ️ Info | Out of SC-1's literal scope (`lib/` only). Flagged for consistency, not as a failure. |
| `lib/presentation/tasks/form/widgets` | — | Exactly 10 files — at the cap, zero headroom | ℹ️ Info | Compliant. The directory's own README documents this and states what to do instead of adding an 11th file. |
| `lib/infrastructure/tasks/item_repository_impl{,_queries}.dart` | — | `part` / `part of` split (141 + 112 lines) | ℹ️ Info | The weakest form of cap compliance — one library across two files — but the split is semantic (CRUD vs queries), documented in both files, and preserves class identity. |
| `lib/domain/tasks/item_copy_with.dart` | 20-27 | Doc comment says `copyWith(dueDate: clearField)` clears the field; the implementation treats `clearField` as "not provided" and keeps the existing value (passing `null` is what clears) | ℹ️ Info | **Pre-existing** — introduced in commit `27e525b` (Phase 2), carried through the split verbatim. Correct behaviour for a pure refactor; worth a follow-up doc fix. |

### Known Gaps Carried Into This Report

Reported as declared by the phase, and independently corroborated where possible:

1. **No on-device UAT was performed for any plan in this phase.** No emulator or device exists in the execution environment. Six plans had manual smoke tests in their acceptance criteria that could not run. Confirmed against STATE.md and the SUMMARYs; this is the reason for `status: human_needed` rather than `passed`.
2. **Highest residual risk is 06-17 (Isar model relocation).** Independently checked and **found to be lower than documented** — all six regenerated `.g.dart` files are byte-identical to their pre-move versions, so collection names *and* id hashes are provably unchanged. Cold start against real seeded data is still the honest gap.
3. **The extracted form screens have no widget tests.** Confirmed — `test/presentation/` contains no test for `task_form_screen`, `transaction_form_screen`, `recurring_payment_form_screen`, `debt_form_screen` or `goal_form_screen`. Their correctness rests on `flutter analyze` plus the existing suite, exactly as stated.
4. **`dart format` is not enforced and the tree is not format-clean.** Independently measured: `dart format --set-exit-if-changed lib test` → **103 of 258 files changed**. The decision not to enforce is recorded in STATE.md with a coherent reason (reformatting would push several files past the 150-line cap and break SC-1 in the same commit that locks it in). Deliberate, documented, and correctly *not* claimed as done.
5. **The pre-existing PT-BR amount-parsing bug is preserved unchanged.** Verified in `lib/core/utils/amount_parser.dart`: `parseAmountCentsOrNull('1.250,50')` returns `null` and `'-5'` yields +500 cents. The file's own doc comment documents both quirks explicitly and states they are pre-existing, and `test/core/utils/amount_parser_test.dart` tests the real behaviour rather than the desired behaviour. This is the correct call for a pure refactor. Logged in STATE.md for a follow-up task.

### Human Verification Required

Three items — see the `human_verification` block in the frontmatter for full test/expected/why detail:

1. **Cold start against pre-Phase-3.1 seeded data** — the only way to close the Isar-relocation risk. (Static evidence is strong; this is confirmation, not investigation.)
2. **Manual smoke of the five extracted form screens**, create and edit, all pickers, both validation paths — these have no widget tests.
3. **Keyboard/focus/scroll behaviour** of the extracted field groups — visual quality, unverifiable from source.

### Gaps Summary

**No gaps.** All five ROADMAP Success Criteria are verified by measurement I ran myself, not by reading SUMMARY.md:

- SC-1 and SC-2 were measured with my own `find`/`wc`/`uniq -c` pass, deliberately bypassing the guard, and the guard's exclusion set was separately audited file-by-file for legitimacy. The two methods agree.
- SC-3 was verified beyond presence: every README was cross-checked against its directory's real contents, and **not one** omits a file, names a nonexistent file, or misstates a line count.
- SC-4 and SC-5 were measured by running the suite and the analyzer, and reinforced by seven source-level behaviour diffs against pre-refactor commits, all of which came back equivalent.
- The guard was proven to fail — not just to pass — by injecting one violation of each of its three rules and confirming exit 1 for each, then restoring the tree.

The SUMMARY narrative held up under adversarial checking. The three things worth a decision are not failures:

- **The one line-cap exemption is for dead code.** `currencies.dart` is unreferenced anywhere in the project. The exemption is technically sound but its justification should say so. Recommend a one-line amendment to `tool/architecture_exemptions.dart`, or deleting the file and the exemption together if D-16 (currency setting) is not imminent.
- **The house rule only covers `lib/`.** `tool/check_architecture.dart` itself is 182 lines and 16 `test/` files exceed 150. This matches the literal wording of SC-1, so it is not a violation — but if the intent was "the codebase", the guard's own root list is where to change it.
- **On-device UAT is genuinely outstanding.** This is why the status is `human_needed` and not `passed`. It is not a defect in the work; it is a check that the execution environment could not perform.

---

_Verified: 2026-08-12T13:52:27Z_
_Verifier: Claude (gsd-verifier)_

---

## Addendum — On-device UAT, 2026-08-12

Ran on a physical **Infinix X6831 (Android 13, arm64-v8a)**. This closes the three
`human_verification` items that kept the phase at `human_needed`.

### Method

The device already had the **pre-Phase-6 build** installed (2026-08-11 07:25) with a real
1 MB `default.isar`. That database was backed up byte-identically first
(`md5 cae5b902…`, 1048576 bytes, verified against the on-device copy), then the
post-Phase-6 debug APK was installed **over** it with `adb install -r` so app data survived.
This is a genuine upgrade-in-place test, not a fresh install against a seeded fixture —
which is what makes it meaningful for 06-17's Isar relocation.

### Result: no regressions

Every pre-existing record survived. Balance identical before and after
(**MT 3.800,00** / Património **MT 4.050,00**), both transactions and both tasks intact,
chart renders, and `logcat` shows `IsarCore using libmdbx: v0.13.8` opening cleanly with
**zero** Isar, schema, migration or Dart errors. The savings goal and debt both load through
the newly nested repositories, which exercises 06-16 and 06-17 end to end.

The extracted widgets behave. A full create→save→delete round trip through the transaction
form drove `TransactionFormModel`, the extracted pickers, scaffold, app bar and
`submitTransactionForm`; the dashboard then recomputed to exactly `3.800 − 250 = 3.550`.
The task form's GTD guide, date picker and finance-link card all work, and dismissing the
GTD sheet returns `null` without corrupting form state.

### Three UI defects found — all pre-existing, none caused by this phase

Each was checked against the pre-refactor source before being classified.

| Defect | Where | Verdict |
|---|---|---|
| Two identical **X** close buttons in the GTD sheet header on step 1 | `gtd/widgets/gtd_sheet_header.dart:47,73` | Pre-existing. `canGoBack` is false on the first step, so the left button falls back to `Icons.close`. Identical logic existed at `task_form_screen.dart:892/919` before extraction. |
| **"Tamanho"** segmented control wraps badly — "Médio" renders as `M/éd/io`, "Pequeno" as `Pequen/o`, "Nenhum" as `Nenhu/m`; only "Grande" fits | `form/widgets/flags_size_notes_fields.dart:69` | Pre-existing. Byte-for-byte the same `SegmentedButton` and padding as `task_form_screen.dart:511` before extraction. Four segments do not fit the viewport at this text scale. |
| Hardcoded, unlocalised strings: `'Pergunta X de Y'` (PT-only) and `'8 questions to clarify & prioritize'` (EN-only, shown inside the PT-BR UI) | `gtd_sheet_header.dart:55`, `widgets/gtd_guide_card.dart:56` | Pre-existing. Both trace to commit `7275715` in Phase 2. Neither goes through `AppLocalizations`. |

That all three survived the refactor unchanged is itself evidence of fidelity: a pure
refactor should preserve defects, and this one did.

### Also confirmed while on the device

- The **undo-timer defect** logged against Phase 3 still reproduces: the
  "Transação excluída / Desfazer" snackbar was still on screen **12 seconds** after a delete,
  well past its 5s duration.
- The **category-name stub** bug (transactions titled `#10`, `#1` instead of a category name)
  is visible in the pre-Phase-6 build too — also Phase 3, not this one.

### Not covered

Only the transaction and task forms were driven end-to-end. The goal, debt and recurring-payment
forms were reached indirectly (their data loads correctly through the finance-link sheet) but
their own create/edit paths were not exercised. iOS was not tested at all — no device available.
