---
phase: 03-finance-core
plan: 06
subsystem: finance
gap_closure: true
tags: [finance, transactions, categories, i18n, widget-tests, uat-gap]
requires:
  - TransactionCategoryRepository (domain/finance/category)
  - resolveCategoryDisplay (presentation/finance/transaction_form_logic.dart)
provides:
  - TransactionLoaded.categories
  - category-name resolution on the transaction list
  - single-render TransactionCard layout contract
affects:
  - TransactionCubit constructor signature (now two positional args)
  - every construction of TransactionLoaded (now requires `categories`)
tech-stack:
  added: []
  patterns:
    - "State carries its own lookup data (mirrors BudgetLoaded.categories)"
    - "Non-reactive repository loaded once per cubit lifetime, not per reload"
    - "Widget tests pin an explicit locale; this suite's default is en"
key-files:
  created:
    - test/presentation/finance/transaction_card_test.dart
    - test/presentation/finance/transaction_list_screen_test.dart
  modified:
    - lib/application/finance/transaction/transaction_state.dart
    - lib/application/finance/transaction/transaction_cubit.dart
    - lib/application/finance/transaction/README.md
    - lib/config/di/injection.config.dart
    - lib/presentation/finance/screens/transaction_list_screen.dart
    - lib/presentation/finance/screens/README.md
    - lib/presentation/finance/widgets/transaction_card.dart
    - lib/presentation/finance/widgets/README.md
    - test/application/finance/transaction_cubit_test.dart
    - test/presentation/undo_snackbar_auto_dismiss_test.dart
decisions:
  - "A category-repo Err degrades to the '#<id>' label fallback and still emits TransactionLoaded — never TransactionError, which would blank the whole list"
  - "Categories load once in start(); _reload() reuses the cached list because TransactionCategoryRepository is explicitly non-reactive"
  - "The non-empty TransactionLoaded arm delegates to a private _buildList method rather than a Builder, keeping the switch expression readable and the file under the 150-line cap"
metrics:
  duration: ~50min
  tasks: 3
  files_changed: 12
  tests_before: 268
  tests_after: 277
  completed: 2026-08-13
---

# Phase 03 Plan 06: Transaction Category Names Summary

Transaction cards now render the localized category name instead of a raw
`#<id>` stub, and each field renders exactly once — closing UAT test 2.

## What Was Built

`TransactionLoaded` gained a `categories` field, mirroring `BudgetLoaded`.
`TransactionCubit` takes `TransactionCategoryRepository` as its second
positional constructor argument and loads the category list once in
`start()`. The list screen builds a `categoryById` map per state and
resolves each transaction's `categoryId` through the pre-existing
`resolveCategoryDisplay` helper. `TransactionCard` was rewritten to a
one-place-per-field layout.

### Task 1 — State and cubit (`76f7a89`)

- `TransactionLoaded({required transactions, required categories})`, with
  `categories` in `props` so Equatable compares it.
- `TransactionCubit(this._repository, this._categoryRepository)`; a private
  `_categories` cache populated once in `start()` before the first
  `_reload()`.
- On `Err` from `getAll()`, `_categories` stays empty and the cubit still
  emits `TransactionLoaded`. A category-lookup failure must degrade to the
  `#<id>` fallback, not blank the transaction list.
- `injection.config.dart` regenerated via `build_runner`; the factory is now
  `TransactionCubit(gh<TransactionRepository>(), gh<TransactionCategoryRepository>())`.
  Only `injection.config.dart` changed — no Isar `.g.dart` churn.
- Repaired the 6 call sites the signature change broke (4 in
  `transaction_cubit_test.dart`, 2 in `undo_snackbar_auto_dismiss_test.dart`)
  in the same commit, so the suite never went red between tasks.

### Task 2 — Screen and card (`6066031`)

- Deleted the `_categoryName` stub whose comment read "For now, use a
  placeholder that works" and which always returned `'#${tx.categoryId}'`.
- The non-empty `TransactionLoaded` arm now destructures `categories` and
  delegates to a private `_buildList`, which builds the `categoryById`
  lookup once per state rather than once per `itemBuilder` call.
- Card layout contract: title = `categoryName`, subtitle = date alone,
  note = one `Chip`. Previously the title was `transaction.note ?? categoryName`
  and the subtitle was `'$categoryName · $formattedDate'`, so a note appeared
  twice and `#10` appeared twice.
- `hasNote` no longer compares the note against `categoryName` (a workaround
  for the collision that is now gone). It trims instead, so a whitespace-only
  note renders no empty chip.
- The `Dismissible` key `'tx-${transaction.id}'`, swipe direction,
  `FinanceColors` and `typeIcon` are untouched — the undo-snackbar suite
  drives the swipe through `find.byKey(const Key('tx-7'))`.

### Task 3 — Regression tests (`b22e87a`)

7 new tests across two files, using `bloc_test` + `mocktail`.

- `transaction_card_test.dart` (4): category as title, note exactly once,
  and no chip for a null or whitespace note.
- `transaction_list_screen_test.dart` (3): pt_BR resolution with
  `find.textContaining('#10')` asserted `findsNothing`, the orphaned-category
  `#10` fallback, and the `en` locale yielding `Food`.

Both `preferEnglish` branches are pinned, so swapping the two locales would
fail both tests.

## Verification

Measured in this worktree, not assumed:

| Gate | Baseline (`c10f314`) | After |
|------|---------------------|-------|
| `flutter test --no-pub` | 268 passing | **277 passing**, exit 0 |
| `flutter analyze --no-fatal-infos --fatal-warnings` | exit 0, 65 infos | exit 0, **65 infos** |
| `dart run tool/check_architecture.dart` | exit 0 | exit 0, PASS |

Line counts, all under the 150-line cap and matching their READMEs:
`transaction_cubit.dart` 128, `transaction_state.dart` 52,
`transaction_list_screen.dart` 140, `transaction_card.dart` 116.

No package was added to `pubspec.yaml`.

### Red-state proof

Both new test files were verified to genuinely fail against the pre-fix code,
by temporary local revert, then restored (`git diff --stat lib/` empty before
the Task 3 commit):

- Reverting the card title to `transaction.note ?? categoryName` made
  `'renders a note exactly once'` report `Found 2 widgets with text
  "Mercado semana"`.
- Replacing the resolution with the old `'#${tx.categoryId}'` stub made both
  the pt_BR and `en` resolution tests fail with `Found 0 widgets`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Worktree had no resolved package config**

- **Found during:** Baseline measurement, before Task 1
- **Issue:** `.dart_tool/` is gitignored, so a fresh worktree has none.
  `flutter test --no-pub` crashed with `Bad state: No element` in
  `testCompilerBuildNativeAssets` rather than running any test.
- **Fix:** Ran `flutter pub get` once in the worktree. No `pubspec.yaml` or
  `pubspec.lock` change — `pubspec.lock` is gitignored in this project.
- **Files modified:** none tracked
- **Commit:** n/a (environment setup)

**2. [Rule 1 - Bug] Missing Cupertino delegate failed the pt_BR widget tests**

- **Found during:** Task 3, first run of the new screen tests
- **Issue:** A `pt_BR` `MaterialApp` carrying only `GlobalMaterialLocalizations.delegate`
  emits "This application's locale, pt_BR, is not supported by all of its
  localization delegates — a CupertinoLocalizations delegate ... was not found."
  `flutter_test` records that warning as a pending exception, which failed the
  pt_BR test outright and tripped the `expect(tester.takeException(), isNull)`
  assertion in the fallback test. The `en` test was unaffected.
- **Fix:** Added `GlobalCupertinoLocalizations.delegate` to the new test
  harness, as the framework warning itself recommends.
- **Files modified:** `test/presentation/finance/transaction_list_screen_test.dart`
- **Commit:** `b22e87a`

### Deliberate additions

- **One extra cubit test beyond the plan.** The plan asked for
  `'start() emits TransactionLoaded carrying the loaded categories'` and said
  the Err-degradation behaviour could be confirmed by reading the branch.
  It is asserted instead:
  `'start() still emits TransactionLoaded when the category repo Errs'`.
  That is the T-03-06-02 mitigation and the plan's own truth #3, so it is
  worth a test rather than a reading. Suite total is 277, above the plan's
  275 floor.
- **`_buildList` helper instead of the plan's inline `Stack`.** A Dart switch
  expression arm cannot hold a statement, so building `categoryById` once per
  state needed either a `Builder` closure or a method. A private method is the
  cleaner of the two and left the screen at 140 lines, inside the cap. No new
  file was needed, so the plan's "extract into a helper file if it crosses the
  cap" contingency did not apply.

### Corrected stale documentation

`lib/presentation/finance/screens/README.md` claimed
`transaction_list_screen.dart` was 119 lines; it was 123 before this plan and
is 140 now. Corrected, as the plan instructed.

## Notes for Verification

- The plan's `key_links` regex for `injection.config.dart` expects a
  single-line factory. Injectable wrapped the two-argument factory across
  lines 210-214, so a single-line `grep` reads as a false negative. Use
  `grep -n -A3` — the plan's acceptance criteria already say so.
- UAT test 2 also names a **task-link chip showing a raw id** (UAT test 9).
  That is a different surface and belongs to plan 03-08, not this one.
- Not verified on a physical device. The `#<id>` → name fix is proven by
  widget test only; the phase's on-device UAT should re-run test 2.

## Known Stubs

None. The `_categoryName` stub this plan existed to remove is gone, and
`grep -n "_categoryName" lib/presentation/finance/screens/transaction_list_screen.dart`
returns no matches. The surviving `'#${tx.categoryId}'` string is a
deliberate orphaned-category fallback — the same one `spending_pie_chart.dart`
and `spending_bar_chart.dart` already use — and is covered by a test.

## Threat Flags

None. No new network, auth, file-access or schema surface. The plan's
`T-03-06-02` mitigation (orphaned `categoryId` must not throw) is implemented
via `resolveCategoryDisplay`'s `fallback` and covered by the
`'falls back to #<id>'` test.

## Self-Check: PASSED

- All 12 declared files verified present on disk (`ls`).
- All 3 task commits verified present in `git log`: `76f7a89`, `6066031`,
  `b22e87a`.
- `git diff --stat lib/` empty after the temporary red-state reverts,
  confirming no revert leaked into a commit.
- No file deletions in any of the three commits.
