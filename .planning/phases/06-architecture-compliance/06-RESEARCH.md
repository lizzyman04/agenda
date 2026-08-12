# Phase 6: Architecture Compliance - Research

**Researched:** 2026-08-11
**Domain:** Flutter/Dart codebase restructuring (file-length limits, folder nesting, README documentation, CI enforcement) — no new product behavior
**Confidence:** MEDIUM-HIGH — stack facts verified against this repo and pub.dev; the README-scope and some split seams are judgment calls flagged as `[ASSUMED]`

## Summary

This phase has no framework unknowns — it is entirely mechanical decomposition of files the team already wrote, governed by three house rules (150-line file cap, ≤10-file directories, README per nest) that the team has already applied once, successfully, to two slices (`presentation/tasks/form/` and `presentation/finance/goals/`). Those two slices **are** the specification: read `lib/presentation/tasks/form/README.md` and `lib/presentation/finance/goals/README.md` before writing any plan, because they encode the two conventions ("screens own state; widgets take data and callbacks", "sheets/dialogs own their own controllers") that must be replicated identically across the remaining twelve screens, and the GTD sub-slice (`lib/presentation/tasks/form/gtd/`) additionally demonstrates the pattern for splitting stateful decision logic into pure spec functions plus dumb renderers.

The highest-value and highest-risk finding is that **no maintained Dart/Flutter lint package enforces file-length or directory-size limits**. `dart_code_metrics` was discontinued and commercialized as paid DCM in July 2023 (disqualified: CLAUDE.md forbids abandoned packages, and a paid SaaS/licensed tool is a poor fit for a solo offline project). `dart_code_linter` (DCL), an actively maintained fork, ships 70+ rules for complexity/nesting/parameters but **has no line-count-per-file or files-per-directory rule** — confirmed by reading its published rule set. There is no existing Dart tool for this. The correct answer is a small, dependency-free Dart script run from CI (`dart run tool/check_architecture.dart`), because Dart is already the project's toolchain and the script needs zero new pubspec entries.

The second major finding is a **file-mapping conflict between plans 6-03 and 6-04**: `data/finance/finance_mappers.dart` (327 lines, in scope for 6-03) splits naturally into six per-entity mapper files, and those six files are exactly what 6-04's proposed `data/finance/<entity>/` subfolders need. Splitting the mapper file before the folder nesting avoids doing the same file twice. Recommended sequencing details are in the Sequencing section below.

**Primary recommendation:** Build a single `tool/check_architecture.dart` guard script (line-count + directory-size + README-presence, all three checks in one file, all mechanically exit-code driven), wire it into the existing `.github/workflows/ci.yml` right after the `Analyze` step, and use it as the acceptance test for all five plans in this phase — a plan is "done" when the guard passes for its slice, not just when `flutter analyze`/`flutter test` pass.

## Architectural Responsibility Map

This phase makes no changes to what any architectural tier is responsible for — it only reorganizes files within tiers. The map below documents which tier owns each of the three house rules, so the planner can see that nothing here crosses a tier boundary.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| File-length limit (150 lines) | All hand-written tiers (domain/data/infrastructure/application/presentation/core) | — | A cross-cutting code-quality rule, not owned by any one tier |
| Directory nesting by responsibility | domain/finance, data/finance (this phase's scope) | presentation (already compliant post-goals-slice) | Isar model/DAO/repository triads in data+domain are the only tiers still over the 10-file cap |
| README per nest | presentation/, application/ (per phase scope) | domain/, data/, infrastructure/ (not required by this phase, but same convention could extend later) | Phase scope explicitly limits the README requirement to presentation/ and application/ |
| CI enforcement (guard script) | Build/CI tooling (`tool/`, `.github/workflows/`) | — | New standalone dev-tooling tier; not part of the runtime `lib/` architecture at all |
| Pure computation extraction (aggregation, mapping, next-occurrence logic) | Application (cubits) → Domain (pure functions/services) | Data (mappers) | Moving business math out of cubits and into pure functions is a data/application boundary clarification, not a new tier |

## Project Constraints (from CLAUDE.md)

These are binding on every plan in this phase:

- Tech stack is locked: Flutter + `isar_community` + BLoC/Cubit + GetIt/`injectable` + `go_router`. No Riverpod, `provider`, `freezed`, `get` (GetX), or any package on CLAUDE.md's "What NOT to Use" table.
- No package may phone out — privacy-first, fully offline. (Not a live risk in this phase: no new dependency is expected to be needed at all.)
- Prefer **zero new dependencies**. This phase's own research (below) confirms zero new pubspec dependencies are required — the CI guard is a plain Dart script, not a package.
- All code/comments/enums in English; UI text stays PT-BR/EN via the existing l10n pipeline — untouched by this phase.
- `analysis_options.yaml` extends `very_good_analysis` with `lib/generated/**`, `lib/config/di/injection.config.dart`, and `**/*.g.dart` excluded from analysis — the same exclusion list must be reused verbatim by the new guard script so hand-written vs. generated stays consistent between `flutter analyze` and the new check.
- GSD workflow enforcement: work must go through `/gsd-execute-phase`, not ad hoc edits.

<phase_requirements>
## Phase Requirements

No formal requirement IDs exist for this phase (internal quality work, per ROADMAP.md). The five success criteria function as the requirement set:

| ID | Description | Research Support |
|----|-------------|------------------|
| SC-1 | No hand-written file under lib/ exceeds 150 lines (generated files exempt) | Standard Stack (no lint exists) + Architecture Patterns (decomposition recipes) + Code Examples (guard script) |
| SC-2 | No directory under lib/ holds more than 10 related source files | Architecture Patterns (folder nesting proposal for domain/finance, data/finance) + Code Examples (guard script) |
| SC-3 | Every feature directory under lib/presentation/ and lib/application/ contains a README.md | Don't Hand-Roll (README template) + Code Examples (guard script) + Open Questions (nest-scope definition) |
| SC-4 | Full test suite passes unchanged (pure refactor) | Common Pitfalls + Validation Architecture |
| SC-5 | `flutter analyze` reports no new errors/warnings | Validation Architecture |
</phase_requirements>

## Standard Stack

### Core (already installed, unchanged)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `very_good_analysis` | 10.2.0 | Base lint ruleset | Already the project's linter; this phase adds no new lint package |
| Dart SDK | `>=3.7.0 <4.0.0` (CI pins Flutter 3.41.4 / Dart 3.11.1) | Runs the guard script | `dart run tool/check_architecture.dart` needs no package, just the SDK already required to build the app |

### Supporting — none required
No new dev-dependency is needed for the guard script. `dart:io` (`Directory`, `File`) and `dart:convert` (only if JSON output is wanted) are sufficient for line counting, directory walking, and README-presence checking — all part of the Dart SDK.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-written `tool/check_architecture.dart` | `dart_code_metrics` | **Rejected** — repo archived 2023-07-16 by its owner; free tier discontinued; successor is a paid commercial product (DCM). Violates CLAUDE.md's "no abandoned packages" rule and the zero-new-dependency preference. `[VERIFIED: WebSearch — GitHub archive notice + DCM pricing page]` |
| Hand-written `tool/check_architecture.dart` | `dart_code_linter` (DCL) | **Rejected for this purpose** — actively maintained (published 12 days before this research date, Dart SDK `>=3.5.0 <4.0.0`, compatible), but its 70+ rules are complexity/nesting/parameter-count metrics; **no rule for max lines-per-file or max files-per-directory exists in its rule set.** `[VERIFIED: pub.dev package page fetch, 2026-08-11]` |
| Hand-written `tool/check_architecture.dart` | A shell script (`bash` + `wc -l` + `find`) | Viable alternative, not rejected — but a Dart script is preferred because: (a) it runs identically on any dev machine without assuming a POSIX shell, (b) the same `analysis_options.yaml` exclude globs can be reused via simple string matching instead of re-deriving bash glob patterns, (c) it can be unit-tested with `package:test` like any other project code. Either approach satisfies SC-1/SC-2/SC-3; Dart is recommended, not mandatory. |

**Installation:** none.

**Version verification:**
```bash
# Confirms DCL's current state (ran 2026-08-11):
# pub.dev/packages/dart_code_linter → "Published 12 days ago" (v4.1.9),
# Dart SDK constraint >=3.5.0 <4.0.0, analyzer >=10.0.0 <15.0.0 — compatible
# with this project's Dart 3.11.1, but has no file-length rule.
```

## Architecture Patterns

### System Architecture Diagram

This phase does not add a data-flow diagram — no runtime behavior changes. The relevant "flow" is the CI enforcement pipeline:

```
git push / PR
      │
      ▼
flutter pub get → build_runner build → flutter gen-l10n   (existing steps, unchanged)
      │
      ▼
flutter analyze --fatal-warnings                            (existing step, unchanged)
      │
      ▼
dart run tool/check_architecture.dart   ◄── NEW STEP (this phase)
   ├─ walk lib/, exclude *.g.dart, injection.config.dart, lib/generated/**
   ├─ per file: line count > 150 ⇒ violation
   ├─ per directory: hand-written .dart file count > 10 ⇒ violation
   ├─ per directory (presentation/, application/ scope): missing README.md ⇒ violation
   └─ print violation table, exit 1 if any violation, exit 0 otherwise
      │
      ▼
flutter test --coverage                                     (existing step, unchanged — SC-4)
      │
      ▼
Verify offline guarantee (grep pubspec.yaml)                (existing step, unchanged)
```

### Recommended Project Structure (target state after this phase)

```
lib/
├── domain/finance/
│   ├── transaction/       # transaction.dart, transaction_type.dart, transaction_repository.dart
│   ├── budget/             # budget.dart, budget_repository.dart
│   ├── goal/               # savings_goal.dart, savings_goal_contribution.dart, goal_repository.dart
│   ├── debt/                # debt.dart, debt_direction.dart, debt_repository.dart
│   ├── recurring/          # recurring_payment.dart, recurring_cycle.dart, recurring_payment_repository.dart
│   └── category/           # transaction_category.dart, transaction_category_repository.dart
├── data/finance/
│   ├── transaction/        # transaction_model.dart(+.g.dart), transaction_dao.dart, transaction_mapper.dart
│   ├── budget/              # budget_model.dart(+.g.dart), budget_dao.dart, budget_mapper.dart
│   ├── goal/                 # savings_goal_model.dart(+.g.dart), savings_goal_dao.dart, goal_mapper.dart
│   ├── debt/                  # debt_model.dart(+.g.dart), debt_dao.dart, debt_mapper.dart
│   ├── recurring/            # recurring_payment_model.dart(+.g.dart), recurring_payment_dao.dart, recurring_payment_mapper.dart
│   └── category/            # transaction_category_model.dart(+.g.dart), transaction_category_dao.dart, transaction_category_mapper.dart
├── presentation/tasks/form/
│   ├── screens/             # task_form_screen.dart split into field-group widgets
│   ├── widgets/             # (existing) field-group cards
│   └── gtd/                 # (already compliant — reference implementation)
└── presentation/finance/
    ├── goals/                # (already compliant — reference implementation)
    ├── transactions/         # NEW — extracted from screens/ + widgets/ catch-alls (optional, see Open Questions)
    ├── budgets/               # NEW — likewise
    ├── debts/                  # NEW — likewise
    ├── recurring/              # NEW — likewise
    └── dashboard/               # NEW — likewise
tool/
└── check_architecture.dart   # NEW — the CI guard (Standard Stack above)
```

The `data/finance` and `domain/finance` restructuring is the concrete deliverable for 6-04 (research question 4). The `presentation/finance/{transactions,budgets,...}` split is **optional** — the roadmap's scope note says `presentation/finance/screens` (8 files) and `presentation/finance/widgets` (6 files) are *already under* the 10-file cap post-goals-extraction, so splitting them further is not required by SC-2. It is offered here only as a structural option if the planner wants presentation to mirror the same per-entity nesting as data/domain for consistency; treat as discretionary, not required.

### Pattern 1: Screens Own State, Widgets Take Data + Callbacks
**What:** Every route-level `screens/*.dart` file is a `StatefulWidget` that owns `TextEditingController`s, `FocusNode`s, and the injected Cubit. Every file under `widgets/*.dart` is a `StatelessWidget` (or a small `StatefulWidget` only for a self-contained UI concern like an expand/collapse card) that receives plain values and `VoidCallback`/`ValueChanged<T>` parameters — never a Cubit, never a controller it didn't create itself.
**When to use:** All twelve remaining presentation screens (6-01, 6-02).
**Verified in this repo:**
```
// Source: lib/presentation/finance/goals/README.md, "Conventions in this slice"
"Screens own cubits; widgets never do. Widgets take domain objects and
callbacks, so each is renderable in isolation and in widget tests."
```

### Pattern 2: Sheets/Dialogs Own Their Own Controllers (documented crash precedent)
**What:** A bottom sheet or dialog invoked via `showModalBottomSheet`/`showDialog` must be its own `StatefulWidget` that creates its `TextEditingController`(s) in `initState`/field initializers and disposes them in `State.dispose()`. It returns a value via `Navigator.pop(value)`. The **caller** awaits the popped value, then calls the cubit — never inside the sheet, never with `unawaited(...)`.
**When to use:** Any of the twelve screens that open a sheet or dialog for a sub-form (e.g. `debt_form_screen.dart`, `recurring_payment_form_screen.dart` if they have inline add/edit sheets — verify per-file during 6-02 planning).
**Why this is not optional style guidance — it shipped as two real crashes:**
```
// Source: lib/presentation/finance/goals/README.md
"Controllers created in a caller's method scope and disposed right after
`await showModalBottomSheet` returns are disposed while the dismiss
transition is still animating, producing 'TextEditingController used after
being disposed' and cascading into the InheritedElement._dependents.isEmpty
assertion — a full red-screen crash. It shipped twice: once in the budget
limit sheet (fixed in ae397ae) and again in the contribution sheet
(Phase 03 UAT test 5)."
```
Regression tests exist for both: `test/presentation/finance/budget_limit_sheet_test.dart`, `test/presentation/finance/goal_contribution_sheet_test.dart`. **Any 6-02 plan that touches a screen containing an inline sheet must check for this exact bug shape while splitting it out**, since splitting a screen is precisely the kind of edit that risks re-introducing it (moving controller creation to the wrong scope).

### Pattern 3: Pure-Function Extraction for Business Logic Inside Cubits/Repositories/DAOs
**What:** When a class method's bulk is computation rather than orchestration (aggregation math, enum translation, query-condition building, entity construction), extract that computation to a **top-level pure function** in a sibling file, taking all required state as explicit parameters. The class method shrinks to: fetch → call the pure function → emit/return. This sidesteps Dart's file-scoped privacy entirely (top-level functions don't need access to another class's private fields) and is directly modeled on this repo's own precedent.
**When to use:** `task_list_cubit.dart` (227), `home_dashboard_cubit.dart` (202), `budget_cubit.dart` (155), `item_dao.dart` (178).
**Reference implementation in this repo (the pattern this generalizes from):**
```dart
// Source: lib/presentation/tasks/form/gtd/gtd_tree_clarify.dart
// clarifySpec takes (GtdNode, GtdTreeContext) — a plain function, not a method —
// and is unit-tested directly with no widget pumping:
// test/presentation/tasks/gtd_decision_tree_test.dart
GtdNodeSpec? clarifySpec(GtdNode node, GtdTreeContext ctx) { ... }
```
**Concrete application to the four files in scope:**

| File | What to extract | New file | Est. lines saved |
|------|------------------|----------|-------------------|
| `task_list_cubit.dart` | The recurring-task next-occurrence `Item` construction inside `completeItem()` (lines ~150-179) | `application/tasks/task_list/recurring_completion.dart` — `Item buildNextOccurrence(Item completed, DateTime nextDate)` | ~25 |
| `home_dashboard_cubit.dart` | The balance/net-worth/category-spend aggregation math inside `_reload()` (lines ~95-172) | `application/finance/dashboard/dashboard_aggregator.dart` — pure functions `computeBalance(List<Transaction>)`, `computeNetWorth(...)`, `computeCategorySpend(...)` | ~60-70 |
| `budget_cubit.dart` | The spend/limit map-merge logic inside `_reload()` (lines ~90-145) | `application/finance/budget/budget_aggregator.dart` — `Map<int, ({int limitCents, int spentCents})> mergeBudgetData(...)` | ~40 |
| `item_dao.dart` | The `.optional()` chain inside `filterItems()` (lines 45-109) — this is pure Isar `QueryBuilder` composition, no private state needed | `data/tasks/item_query_builder.dart` — top-level function operating on the public `QueryBuilder` type returned by `.filter()` | ~55 |

After these four extractions, re-measure: `budget_cubit.dart` (155 → ~115) clears the limit alone. `task_list_cubit.dart` (227 → ~200) and `item_dao.dart` (178 → ~125) still need one more seam each — for `task_list_cubit.dart`, also extract `_currentItems()` state-derivation and/or split CRUD (`createItem`/`updateItem`/`softDelete`/`restoreItem`) from query (`search`/`applyFilter`/`_reload`) documentation blocks (the doc comments are ~40% of this file's bulk; trimming duplicate doc explanation without losing the "why", not just code, is a legitimate way to close the remaining gap — verify during planning rather than assuming). `home_dashboard_cubit.dart` (202 → ~130-140) should clear after the aggregator extraction alone.

**A pure-function extraction is not always achievable without touching private state** — see `item_repository_impl.dart` below (227 lines), where every method needs `_dao`/`_mapper`, which are private instance fields. For that file specifically:

### Pattern 4: `part`/`part of` as the Named Exception for Single-Class Files That Resist Function Extraction
> **CORRECTION (2026-08-11, after plan `6-05` execution).** The original wording of
> this pattern was **wrong on a language fact** and is corrected below. It claimed
> `part`/`part of` can split "one logical class" across files. It cannot — Dart has no
> partial-class syntax. `part`/`part of` splits a *library* across files; a single class
> body must live in one file. The executor for plan `6-05` caught this with a minimal
> compile test before implementing, and used the actual Dart-supported equivalent:
> a private `mixin` declared in the part file (with abstract getters for the shared
> private fields), applied to the main class via `with`. That preserves every property
> this pattern actually needs — same-library private access, one class, one DI
> registration, zero call-site changes — and is what shipped in
> `item_repository_impl.dart` + `item_repository_impl_queries.dart`.
>
> Read the rest of this section as describing the *goal*; the mixin-in-a-part-file is the
> *mechanism*.

**What:** Dart's `part`/`part of` directive splits **one library** across multiple physical files that share the same library scope, so private members remain accessible across the split. A single class body cannot be split this way; to spread a class's methods across part files, declare a private `mixin` in the part file and apply it with `with`. This is the same directive `isar_community_generator` already uses for `*.g.dart` files in this codebase (see e.g. `lib/data/finance/transaction_model.dart` → `part 'transaction_model.g.dart';`).
**When to use — narrowly:** Only for classes where (a) every method needs the same private instance fields, (b) the class is a single DI-registered unit whose public interface must not change (splitting into two cooperating classes would change the dependency graph the app is built on), and (c) pure-function extraction has already been tried and is insufficient. `item_repository_impl.dart` (227 lines, implements `ItemRepository`, registered `@LazySingleton(as: ItemRepository)`) is the clearest candidate in this codebase: 10 methods, each needing `_dao` and `_mapper`, mostly try/catch boilerplate around one DAO call. Recommended split: `item_repository_impl.dart` (`part` — CRUD: create/get/update/softDelete/restoreItem, ~110 lines) + `item_repository_impl_queries.dart` (`part of` — search/filter/getSubtasks/getSubtaskCounts/getDistinctGtdContexts/watchChanges, ~100 lines).
**When NOT to use:** Presentation widgets (Pattern 1/2 above already give a clean seam via composition — sibling files with separate widget classes are strictly better because each becomes independently testable and independently readable in an IDE outline). Do not use `part`/`part of` as a general substitute for decomposition; it is the exception for the specific single-class, all-methods-need-private-state case, not the default.
**Confidence:** `[ASSUMED]` — the DAO/repository split proposed here is my synthesis from reading the actual files, not a documented team convention. Flag for confirmation during planning; the alternative (accept `item_repository_impl.dart` as a small, principled exemption like `currencies.dart`, see Don't Hand-Roll below) is also defensible.

### Anti-Patterns to Avoid
- **Splitting a flat data table by line-count into arbitrary chunks** (e.g. `currencies_a_to_m.dart`, `currencies_n_to_z.dart`): destroys the ability to `Ctrl+F` for a currency code, adds an import for no readability gain. See `## Don't Hand-Roll` for the recommended exemption mechanism.
- **Moving controller creation to a "shared" location during a split**: the #1 concrete risk of this phase (see Common Pitfalls) — a screen split must preserve exactly which widget creates and disposes each `TextEditingController`.
- **Splitting `data/finance/finance_mappers.dart` and moving files in the same commit**: do the split (6-03) and the folder move (6-04) as two mechanically distinct steps so `flutter analyze` isolates which change broke an import, if any.
- **Using `part`/`part of` as a default decomposition tool**: reserve it for the one documented exception (Pattern 4); overuse defeats the "unmistakable architecture" goal because IDE-level file boundaries stop mapping to conceptual boundaries.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| File-length / directory-size enforcement | A hand-rolled analyzer plugin, or paying for DCM | `tool/check_architecture.dart` (plain Dart script, see Code Examples) | No existing package covers this; a plugin is far more machinery than the problem needs; DCM is commercial and unmaintained-for-free |
| `copyWith` "not provided vs. explicitly null" sentinel | Re-deriving the `_Absent`/`clearField` pattern per entity (it is already duplicated six times: `item.dart`, `transaction.dart`, `debt.dart`, `recurring_payment.dart`, `transaction_category.dart`, `savings_goal.dart`) `[VERIFIED: grep -rl clearField lib/domain/]` | Extract once to `lib/core/utils/copy_with_sentinel.dart` (public `class AbsentSentinel` + `const Object clearField`), import from all six entities | Removes ~15-19 duplicated lines from six files, is a genuine DRY win, and directly helps `item.dart` clear 150 lines (see Standard Stack seam below) — a rare case where a refactor purely *for* the line-limit rule also improves the code on its own merits |

**Key insight:** In this codebase the "don't hand-roll" risk is not about pulling in a third-party dependency (there is none to pull) — it is about *not* reinventing the file-length checker as a bespoke `analyzer` plugin package when a 60-line script does the job with zero new dependencies and zero plugin-API surface to maintain against future Dart SDK changes.

## Split-or-Exempt Recommendations (research question 3's open items)

These three files were explicitly flagged by the project owner as needing a defensible per-file call, not a mechanical split. Read in full before planning; here is the recommendation with a concrete seam for each.

| File | Lines | Nature | Recommendation | Seam (if split) |
|------|------:|--------|-----------------|------------------|
| `data/finance/finance_mappers.dart` | 327 | Six independent `class XMapper { toDomain(); toModel(); }` pairs concatenated in one file, zero shared state between them | **SPLIT** — clean, low-risk, high-value | One file per mapper class: `transaction_mapper.dart`, `transaction_category_mapper.dart`, `budget_mapper.dart`, `goal_mapper.dart`, `debt_mapper.dart`, `recurring_payment_mapper.dart`. Each is 30-70 lines. This also sets up 6-04's folder nesting for free (see Sequencing). |
| `core/constants/currencies.dart` | 203 | A single `static const List<Currency> all` literal (ISO 4217 table) plus a derived `priorityCodes` list | **EXEMPT** — splitting by line range destroys grep-ability and adds import overhead for zero benefit; this is exactly the "flat declarative data table" case the house rules should have a principled escape hatch for | If the planner still wants a seam: split `priorityCodes`/"priority currencies" (11 entries, ~15 lines) from the alphabetical full list (150+ entries) into `currencies.dart` + `priority_currencies.dart` — but note this is a much weaker justification than the mapper split, since the two lists are logically one dataset artificially separated by a size limit, not by responsibility. Recommend exemption over this split. |
| `domain/tasks/item.dart` | 219 | One cohesive immutable entity: field declarations (~90 lines) + a large `copyWith` (~75 lines) + the `_Absent`/`clearField` sentinel boilerplate (~19 lines) + `eisenhowerQuadrant` getter | **SPLIT** — but not by breaking the entity's fields apart (that *would* hurt cohesion); split by extracting the two genuinely separable concerns that happen to live in the same file: (1) the sentinel (shared across 6 files, see Don't Hand-Roll), (2) `copyWith` itself | 1. Move `clearField`/`_Absent` to `core/utils/copy_with_sentinel.dart` (shared). 2. Move `copyWith` to `domain/tasks/item_copy_with.dart` as `extension ItemCopyWith on Item { Item copyWith(...) {...} }` — valid because every `Item` field is already public/final, so an extension method needs no access to private state, and `item.copyWith(...)` call sites are byte-for-byte unchanged (Dart extension method syntax is identical to instance method syntax at the call site). Net effect: `item.dart` drops to ~110-130 lines (constructor + fields + `eisenhowerQuadrant`), `item_copy_with.dart` is ~80 lines. Zero behavior change, verified pattern (extension methods on public-field classes are standard idiomatic Dart, not a novel technique). `[ASSUMED: exact resulting line counts — verify by doing the split, not by this estimate]` |

**Recording exemptions so they are principled, not ad hoc:** add a single allowlist file `tool/architecture_exemptions.dart` (or a `.txt`/`.yaml` list, planner's choice) containing `{path: justification}` pairs. The guard script skips files present in this list but **still prints them in a "documented exemptions" section of its output** so the exemption remains visible on every CI run, not silently swallowed. Example entry: `'lib/core/constants/currencies.dart': 'Flat ISO 4217 data table; splitting by line range fragments a single semantic unit — see 6-RESEARCH.md Split-or-Exempt table.'`. This directly answers research question 1's "should the guard support exemptions" — yes, via an explicit, git-tracked, justified allowlist, never via inline `// ignore:` comments (those are invisible to a reviewer scanning the codebase for exemptions).

## Common Pitfalls

### Pitfall 1: Controller-Scope Regression During Screen Splits
**What goes wrong:** Splitting a screen into `screens/x_screen.dart` + `widgets/x_form_fields.dart` moves a `TextEditingController` to the wrong owner — e.g., creating it in the extracted widget instead of the screen, or creating it in a sheet-opening method instead of the sheet's own `State`.
**Why it happens:** It is the natural first instinct to pass `TextEditingController`s down as constructor parameters from wherever code is being moved *from*, without re-examining who should actually own the controller's lifecycle after the split.
**How to avoid:** Apply Pattern 1/2 explicitly per file *before* touching code — write down "this controller is owned by X" for every controller in the screen, then do the mechanical move.
**Warning signs:** "TextEditingController used after being disposed" in test output or on-device; `_dependents.isEmpty` assertion (this exact crash shipped twice already in this codebase, see Pattern 2).

### Pitfall 2: Directory Move Breaks `part`/`.g.dart` Pairing
**What goes wrong:** Moving `transaction_model.dart` to `data/finance/transaction/transaction_model.dart` without moving `transaction_model.g.dart` alongside it (or without regenerating it) leaves a dangling `part 'transaction_model.g.dart';` directive that the analyzer cannot resolve.
**Why it happens:** `.g.dart` files are excluded from `git status` attention (they're generated) and easy to forget when doing a `git mv`.
**How to avoid:** Either (a) `git mv` both the `.dart` and its `.g.dart` together in the same command, or (b) `git rm` the `.g.dart` explicitly and rerun `dart run build_runner build --delete-conflicting-outputs` after every batch of moves — the CI workflow already does this as its "Run code generation" step, so a broken pairing that slips past a local check will still be caught in CI, but a fast local rerun is worth doing before pushing. `[VERIFIED: read lib/data/finance/transaction_model.dart — part directive is path-relative and generated based on the source file's own location, so regeneration after a move produces the correct pairing automatically]`

### Pitfall 3: `injection.config.dart` Goes Stale After a Directory Move
**What goes wrong:** `injection.config.dart` (generated by `injectable_generator`) contains hardcoded import paths like `import 'package:agenda/data/finance/budget_dao.dart' as _i337;`. Moving `budget_dao.dart` to `data/finance/budget/budget_dao.dart` without regenerating this file leaves the DI graph pointing at a path that no longer exists.
**Why it happens:** Same root cause as Pitfall 2 — a generated file that's easy to forget.
**How to avoid:** Rerun `dart run build_runner build --delete-conflicting-outputs` after every folder-move batch, then run `test/config/di/di_test.dart` specifically (it is the DI smoke test already in this repo) before running the full suite — it fails fast and cheaply if any registration is broken.
**Warning signs:** `flutter analyze` passing (import errors inside a `.g.dart`/generated file are often not surfaced the same way) but the app crashing at `GetIt` resolution time, or `di_test.dart` failing.

### Pitfall 4: Thin Widget-Test Coverage Hides Regressions in Split Screens
**What goes wrong:** Of the twelve screens in scope for 6-01/6-02, several have **zero dedicated widget test** today: `task_detail_screen.dart` (563 lines, no test file), `project_screen.dart` (185, no test), `transaction_form_screen.dart` (587, no test), `recurring_payment_form_screen.dart` (431, no test), `debt_form_screen.dart` (327, no test — only its budget/goal sheet siblings have tests), `finance_dashboard_screen.dart` (269, no screen-level test, only sub-widgets `spending_pie_chart_test.dart`), `budget_overview_screen.dart` (236, no screen-level test, only `budget_limit_sheet_test.dart`), `debt_list_screen.dart`, `recurring_payment_screen.dart`. `[VERIFIED: find test/ -name '*.dart' — 37 test files total, 10 under test/presentation/, cross-checked against the 12 in-scope screens]`
**Why it happens:** Widget test coverage for finance forms was deprioritized during Phase 3 execution in favor of shipping velocity; this is a known, pre-existing gap, not something introduced by this phase.
**How to avoid:** Since `flutter test` passing is criterion SC-4 but cannot catch a regression in a file with no test, treat the test suite as necessary but not sufficient for the untested screens. Recommend a manual on-device or `flutter run` smoke pass (open the screen, fill the form, save, confirm no crash) for every screen split that has zero existing test coverage, mirroring how Phase 03 UAT was done "via adb" per STATE.md. This is not a formal gate the CI guard can check — it's a process recommendation for the plan-checker/human-verify step.
**Warning signs:** A screen split "passes" `flutter analyze` and the (unrelated) test suite but crashes on first manual open.

## Runtime State Inventory

This phase moves files and splits classes; it does not rename any `@Collection` class, enum value, DI token, or Isar field. Applying the canonical question ("after every file is updated, what runtime systems still have the old string cached, stored, or registered?") explicitly:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no Isar collection/field names change. Collection names derive from `@Collection()` class names (`TransactionModel`, `BudgetModel`, etc.), which are untouched; only their *file location* moves. | None |
| Live service config | None — this is an offline app with no external services (no n8n/Datadog/Tailscale-equivalent surface exists in this stack). | None |
| OS-registered state | None — no scheduled tasks, no pm2/systemd units (Phase 6 predates Phase 4's notification scheduling). | None |
| Secrets/env vars | None — no secrets exist in this project (offline, no `.env`, no SOPS). | None |
| Build artifacts | **Found:** `*.g.dart` files (Isar model parts) and `injection.config.dart` (DI graph) will go stale on any file move until `build_runner` is rerun. See Pitfalls 2 and 3 above. | Rerun `dart run build_runner build --delete-conflicting-outputs` after every move batch (code edit + regeneration, not a data migration — no persisted data exists yet in a dev/CI environment, and existing on-device Isar files are unaffected since collection names don't change). |

## Code Examples

### The CI Guard Script (all three checks: line-count, directory-size, README-presence)
```dart
// Source: original — no existing package covers this; written for this phase.
// Location: tool/check_architecture.dart
// Run: dart run tool/check_architecture.dart
//
// Exit 0 = compliant, Exit 1 = violations found (violation list printed).

import 'dart:io';

const maxLinesPerFile = 150;
const maxFilesPerDirectory = 10;

// Mirror analysis_options.yaml's analyzer.exclude list exactly.
bool isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path == 'lib/config/di/injection.config.dart' ||
    path.startsWith('lib/generated/');

// Directories exempt from the README check (pure org umbrellas with zero
// direct .dart files — see Open Questions for the counting-method discussion
// this constant resolves). Populate during 6-05 planning.
const readmeExemptDirs = <String>{
  // e.g. 'lib/presentation', 'lib/application',
};

// Files exempted from the 150-line cap, each with a required justification
// (see Split-or-Exempt Recommendations). Keep this list short and reviewed.
const lineLimitExemptions = <String, String>{
  // 'lib/core/constants/currencies.dart':
  //     'Flat ISO 4217 data table — see 6-RESEARCH.md',
};

void main() {
  final violations = <String>[];
  final exemptionsUsed = <String>[];
  final libDir = Directory('lib');

  final dartFilesByDir = <String, List<File>>{};

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (isGenerated(path)) continue;

    dartFilesByDir.putIfAbsent(entity.parent.path, () => []).add(entity);

    if (lineLimitExemptions.containsKey(path)) {
      exemptionsUsed.add('$path — ${lineLimitExemptions[path]}');
      continue;
    }

    final lineCount = entity.readAsLinesSync().length;
    if (lineCount > maxLinesPerFile) {
      violations.add('LINES  $path: $lineCount > $maxLinesPerFile');
    }
  }

  dartFilesByDir.forEach((dir, files) {
    if (files.length > maxFilesPerDirectory) {
      violations.add(
        'FILES  $dir: ${files.length} hand-written files > $maxFilesPerDirectory',
      );
    }
  });

  final scopedDirs = [
    ...Directory('lib/presentation').listSync(recursive: true),
    ...Directory('lib/application').listSync(recursive: true),
  ].whereType<Directory>();

  for (final dir in scopedDirs) {
    final path = dir.path.replaceAll(r'\', '/');
    if (readmeExemptDirs.contains(path)) continue;
    final readme = File('$path/README.md');
    if (!readme.existsSync()) {
      violations.add('README $path: missing README.md');
    }
  }

  if (exemptionsUsed.isNotEmpty) {
    stdout.writeln('Documented exemptions in effect:');
    for (final e in exemptionsUsed) {
      stdout.writeln('  - $e');
    }
    stdout.writeln();
  }

  if (violations.isEmpty) {
    stdout.writeln('Architecture guard: PASS');
    exit(0);
  }

  stderr.writeln('Architecture guard: FAIL (${violations.length} violation(s))');
  for (final v in violations) {
    stderr.writeln('  - $v');
  }
  exit(1);
}
```
**Why this shape:** mirrors `analysis_options.yaml`'s existing exclude list exactly (same three patterns), uses only `dart:io` (zero dependencies), and produces the same "actionable violation list" style the existing CI `Verify offline guarantee` step already uses (grep + explicit error message + `exit 1`).

### CI Workflow Integration (append after the existing `Analyze` step)
```yaml
# Source: existing .github/workflows/ci.yml, insertion point shown
      - name: Analyze
        run: flutter analyze --no-fatal-infos --fatal-warnings

      - name: Architecture guard          # NEW STEP
        run: dart run tool/check_architecture.dart

      - name: Test
        run: flutter test --no-pub --coverage
```
`[VERIFIED: read .github/workflows/ci.yml in full — this is the only workflow that runs on push/PR; deploy.yml is an unrelated Jekyll docs-site pipeline scoped to `landing/**` and is out of scope]`

### `copyWith` Extension Extraction Pattern (for `item.dart`, applies equally to the five finance entities if they ever grow past 150 lines)
```dart
// Source: pattern synthesized from lib/domain/tasks/item.dart — not yet applied.
// New file: lib/domain/tasks/item_copy_with.dart
import 'package:agenda/core/utils/copy_with_sentinel.dart';
import 'package:agenda/domain/tasks/item.dart';
// ...other field-type imports as needed (Priority, SizeCategory, etc.)

extension ItemCopyWith on Item {
  Item copyWith({
    int? id,
    // ...identical parameter list to the original method...
  }) {
    return Item(
      id: id ?? this.id,
      // ...identical body...
    );
  }
}
```
Call sites (`item.copyWith(title: 'x')` in `task_list_cubit.dart` etc.) require **zero changes** — extension method call syntax is identical to instance method call syntax in Dart.

## State of the Art

Not applicable in the usual sense (no external API/library version drift is involved). The one relevant "old approach → current approach" shift is internal to this project:

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Large monolithic screen/cubit files, no file-length convention | 150-line cap, nested-by-responsibility folders, README per nest | House rules adopted 2026-08-11 (STATE.md), first applied to the goals slice same day | 21 files and 2 directories still need migration — this phase's entire scope |
| No CI check for structure | This phase adds `tool/check_architecture.dart` to CI | This phase | Regressions (a new screen shipped at 300 lines) get caught automatically going forward, not just at the next audit |

**Deprecated/outdated:** `dart_code_metrics` as a free tool — confirmed discontinued (archived 2023-07-16); do not reference it in any plan as if it were installable for free today.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Every directory under `lib/presentation/` and `lib/application/` (including generic `screens/`/`widgets/` leaf folders, not just feature-root folders) needs its own `README.md` — this is the literal reading of the roadmap's "2 of 30" baseline, which matches `find lib/presentation lib/application -type d \| wc -l` exactly | Open Questions, Code Examples (`readmeExemptDirs`) | If wrong, 6-05 either over-produces thin one-line READMEs in leaf folders (low cost — see Open Questions) or under-produces if the intended scope is narrower (harder to detect, since the guard would then need pruning) |
| A2 | Thin one-paragraph READMEs are an acceptable satisfaction of SC-3 for generic `screens/`/`widgets/` leaf directories (as opposed to requiring the same depth of documentation as `form/README.md` or `goals/README.md`) | Open Questions | Low — cosmetic only; a plan-checker can request more detail without any architectural rework |
| A3 | `item_repository_impl.dart`'s CRUD/query split via `part`/`part of` (Pattern 4) is the right seam — this is my synthesis from reading the file, not a pattern the team has used before in this codebase | Architecture Patterns, Pattern 4 | Medium — if the planner prefers a different seam (e.g. accepting it as a principled exemption like `currencies.dart`), Pattern 4's specific 110/100-line split need not be followed; the file could instead be added to `lineLimitExemptions` with a justification |
| A4 | The exact line counts after each proposed extraction (e.g. "`item.dart` drops to ~110-130 lines") are estimates from reading the files, not measured after doing the split | Split-or-Exempt Recommendations, Architecture Patterns table | Low — worst case a file needs one additional small seam beyond what's proposed; does not invalidate the seam itself |
| A5 | No new widget tests are *required* by this phase (SC-4 only requires the *existing* suite to pass unchanged) — the recommendation to manually smoke-test untested screens (Pitfall 4) is additive risk mitigation, not a scope requirement | Common Pitfalls, Pitfall 4 | Low — if the planner disagrees and wants new smoke tests written as part of this phase, that is additional scope beyond "pure refactor," worth flagging back to the user rather than assumed silently |

## Open Questions

1. **What exactly counts as a "feature directory" for the README requirement (SC-3)?**
   - What we know: The roadmap's measured baseline ("2 of 30 feature nests carry a README") matches exactly `find lib/presentation lib/application -type d | wc -l` = 30, and the two existing READMEs (`form/`, `goals/`) are at the same nesting depth as several *other* dirs that are pure catch-alls with zero direct `.dart` files (e.g. `lib/presentation`, `lib/application`, `lib/presentation/finance`, `lib/application/finance`, `lib/application/tasks`, `lib/application/shared`, `lib/presentation/tasks` — 7 of the 30 directories contain **no** `.dart` files directly, only subdirectories). `[VERIFIED: find lib/presentation lib/application -maxdepth 1 -name '*.dart' returned empty for these 7 paths]`
   - What's unclear: Whether the intended rule is "every directory, full stop" (30 total, matches the roadmap number exactly, simplest to enforce mechanically) or "every directory that directly contains implementation files" (23 dirs, a more semantically meaningful but harder-to-defend-as-matching-the-baseline rule).
   - Recommendation: Adopt the literal "every directory" rule (A1 above) for CI-checkability — it is trivially mechanical (`Directory.listSync(recursive: true).whereType<Directory>()`, no "does this directory have direct files" branching), matches the committed roadmap baseline exactly, and the cost of a thin README in a `screens/`/`widgets/` leaf is one paragraph, not a maintenance burden. Confirm with the user/planner before 6-05 locks this in, since it is the one place this research diverges from a strictly "minimum necessary" interpretation.

2. **Should `presentation/finance/screens/` and `presentation/finance/widgets/` be split into per-entity subfolders (mirroring the proposed `data/finance/` and `domain/finance/` nesting) even though they're already under the 10-file cap?**
   - What we know: The roadmap explicitly descopes this ("presentation/finance/screens is now 8 and presentation/finance/widgets is 6 — both fell under the limit ... so they are no longer in scope").
   - What's unclear: Whether "no longer in scope" means "do not touch" or "not mandatory but still consistent with the pattern the goals slice established."
   - Recommendation: Treat as out of scope per the roadmap's own words — do not add this to any 6-0x plan unless the user explicitly asks for full presentation/finance parity with the goals slice's per-entity structure. Noted here only so the planner doesn't reintroduce it as accidental scope creep.

3. **Is `budget_cubit.dart` (155 lines) actually going to need the aggregator extraction, or would trimming comments alone suffice?**
   - What we know: 155 is only 5 lines over the limit; the aggregator extraction proposed in Pattern 3 removes ~40 lines, more than needed.
   - What's unclear: Whether the planner prefers the "proper" seam (matches the pattern used for the other two cubits, keeps the file's *shape* consistent across the codebase) or a lighter touch (trim verbose inline comments only).
   - Recommendation: Use the aggregator extraction anyway, even though it's more than strictly necessary — consistency with `home_dashboard_cubit.dart`'s treatment (same underlying pattern: fetch → aggregate → emit) is worth more than minimizing diff size, and a future contributor reading both cubits benefits from the same shape.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Entire phase (build, test, analyze) | ✓ | 3.41.4 (stable) | — |
| Dart SDK | `tool/check_architecture.dart`, build_runner | ✓ | 3.11.1 | — |
| `build_runner` | Regenerating `.g.dart`/`injection.config.dart` after moves | ✓ (already a dev_dependency, `^2.13.1`) | — | — |
| GitHub Actions (`ubuntu-latest`, `subosito/flutter-action@v2`) | CI guard integration | ✓ (existing workflow) | Flutter 3.41.4 pinned in workflow | — |

No missing dependencies. This phase introduces no new external tool requirement.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `bloc_test` 10.0.0 + `mocktail` 1.0.5 (existing, unchanged) |
| Config file | none dedicated — `pubspec.yaml` `dev_dependencies` + `analysis_options.yaml` |
| Quick run command | `flutter test test/<changed_dir>/` (targeted, per file touched) |
| Full suite command | `flutter test --no-pub --coverage` |

### Phase Success Criteria → Verification Command Map
| Criterion | Behavior | Verification Type | Automated Command | Exists Today? |
|-----------|----------|--------------------|--------------------|----------------|
| SC-1 | No hand-written file exceeds 150 lines | static check | `dart run tool/check_architecture.dart` | ❌ — build in 6-05 (Wave 0 gap) |
| SC-2 | No directory exceeds 10 hand-written files | static check | `dart run tool/check_architecture.dart` (same script, second check) | ❌ — build in 6-05 |
| SC-3 | Every presentation/application feature dir has README.md | static check | `dart run tool/check_architecture.dart` (same script, third check) | ❌ — build in 6-05 |
| SC-4 | Full test suite passes unchanged | regression | `flutter test --no-pub --coverage` | ✅ — 230 tests passing today, confirmed by running the suite during this research |
| SC-5 | `flutter analyze` reports no new errors/warnings | static check | `flutter analyze --no-fatal-infos --fatal-warnings` | ✅ — confirmed clean today |

### Sampling Rate
- **Per plan/task commit:** `flutter analyze` + `flutter test` targeted at the touched directory (fast feedback on the split just performed).
- **Per wave merge:** `dart run tool/check_architecture.dart` + `flutter test --no-pub --coverage` (full suite) — the guard script only becomes meaningful once 6-05 lands, so earlier waves rely on manual line-count spot checks (`wc -l <file>`) until the guard exists; see Sequencing below for why 6-05 is last.
- **Phase gate:** All five checks in the table above green, plus the manual/on-device smoke pass recommended in Pitfall 4 for the screens with zero existing test coverage.

### Wave 0 Gaps
- [ ] `tool/check_architecture.dart` — does not exist yet; build as the first task of 6-05, but note it can be *written* early (even Wave 0 of the whole phase) and simply not *enforced in CI* until the codebase is compliant, so it doesn't block earlier waves' CI runs. Recommend writing it early (informational-only run, not `--fatal`) so every subsequent plan gets immediate feedback on its own file-count/line-count progress instead of waiting until 6-05.
- [ ] `tool/architecture_exemptions.dart` (or equivalent allowlist file) — needed before the guard is CI-enforced, since `currencies.dart` (and possibly `item_repository_impl.dart`, per Assumption A3) needs to be in it from day one of enforcement or the guard immediately fails on files this phase is choosing not to split.

*(No new `tests/` directory or fixture gaps — this phase adds no new runtime behavior to test, only a new dev-tool script, which is itself simple enough to verify by running it against the current tree and checking its exit code / printed violation list matches the known-current 21-files/2-directories/28-READMEs baseline.)*

## Security Domain

`workflow.nyquist_validation` is enabled in `.planning/config.json`, and `security_enforcement` is not set to `false`, so this section is included per the template's default. However, this phase makes **no changes to attack surface**: no new input parsing, no new persistence, no new external interface. It is a pure internal-structure refactor of an already-offline, already-local-only application.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | Not touched — app lock is Phase 5 scope |
| V3 Session Management | No | N/A — no sessions in this offline app |
| V4 Access Control | No | N/A — single-user local app |
| V5 Input Validation | No change | Existing validation in `ItemRepositoryImpl`/form screens is *moved*, not altered — verified by SC-4 (behavior-unchanged test suite) |
| V6 Cryptography | No | Not touched — no crypto exists yet (Phase 5 scope for PIN/biometric storage) |

### Known Threat Patterns for this stack
Not applicable to this phase. No new code path is introduced that touches user input handling, persistence boundaries, or platform permission surfaces. The one thing worth a sentence: `tool/check_architecture.dart` runs at CI/dev-time only, never ships in the app bundle, so it has zero runtime attack surface regardless of how it's written.

## Sources

### Primary (HIGH confidence)
- `.github/workflows/ci.yml` — read in full, existing CI pipeline structure
- `analysis_options.yaml` — read in full, existing lint config and exclude globs
- `lib/presentation/tasks/form/README.md`, `lib/presentation/finance/goals/README.md` — read in full, the two existing compliant slices that define the target convention
- `lib/presentation/tasks/form/gtd/gtd_models.dart`, `gtd_tree_clarify.dart` — read in full, the pure-function decomposition precedent
- `test/presentation/tasks/gtd_decision_tree_test.dart` — read in full, the test style the GTD decomposition unlocked
- `lib/data/finance/finance_mappers.dart`, `lib/core/constants/currencies.dart`, `lib/domain/tasks/item.dart` — read in full, the three split-or-exempt files
- `lib/application/tasks/task_list/task_list_cubit.dart`, `lib/application/finance/dashboard/home_dashboard_cubit.dart`, `lib/application/finance/budget/budget_cubit.dart`, `lib/infrastructure/tasks/item_repository_impl.dart`, `lib/data/tasks/item_dao.dart` — read in full
- `.planning/ROADMAP.md` (Phase 6 section, full) and `.planning/STATE.md` — read in full, scope baseline and decision history
- `flutter test` run in this repo during research: 230/230 passing, confirmed live
- `wc -l` / `find` runs against the live repo tree for every file-count and directory-count claim in this document

### Secondary (MEDIUM confidence)
- pub.dev `dart_code_linter` package page, fetched 2026-08-11 via WebFetch — maintenance status, Dart SDK compatibility, rule-set scope
- WebSearch: `dart_code_metrics` discontinuation/DCM commercialization — cross-referenced across GitHub releases page, GitPlanet, dcm.dev, and a codemagic-ci-cd deprecation discussion; consistent across all sources

### Tertiary (LOW confidence)
- None — no unverified claims were left in the document without a source or `[ASSUMED]` tag.

## Metadata

**Confidence breakdown:**
- Standard stack (no lint package exists; guard script approach): HIGH — verified directly against pub.dev and GitHub archive status, not training-data recall
- Architecture patterns (screen/cubit/DAO decomposition seams): MEDIUM-HIGH — the two established patterns (Pattern 1, Pattern 2) are directly cited from this repo's own README precedent; the four new extraction seams (Pattern 3, Pattern 4) are this research's own synthesis from reading the actual files, flagged `[ASSUMED]` where line-count outcomes are estimated
- Pitfalls: HIGH — Pitfalls 1-3 are either documented repo history (crash precedent) or directly verified from reading the Isar/injectable generated-file structure; Pitfall 4 is a direct count of existing test files against in-scope screens

**Research date:** 2026-08-11
**Valid until:** No external time pressure — this is an internal-codebase phase with no third-party version drift risk. Re-verify only if `dart_code_linter`/`dart_code_metrics` status is cited again in a future phase (30-day guidance for that specific claim; the rest of this document doesn't decay).
