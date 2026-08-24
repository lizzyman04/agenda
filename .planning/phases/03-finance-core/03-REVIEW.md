---
phase: 03-finance-core
reviewed: 2026-08-24T03:36:08Z
depth: standard
scope: delta
prior_review: .planning/phases/03-finance-core/03-REVIEW-pre-BL01-closure.md
files_reviewed: 7
files_reviewed_list:
  - lib/data/finance/transaction/transaction_dao.dart
  - test/data/finance/transaction_dao_aggregate_completeness_test.dart
  - test/support/isar_test_harness.dart
  - test/support/isar_test_harness_test.dart
  - test/support/_warm_isar_core_test.dart
  - .github/workflows/ci.yml
  - .gitignore
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 03: Code Review Report (Delta — 03-13/03-14, BL-01 closure)

**Reviewed:** 2026-08-24T03:36:08Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found (no Critical findings; 2 Warnings, 3 Info)

## Summary

This delta review covers only the files touched by plans 03-13 (real-Isar test harness +
CI pre-warm) and 03-14 (uncap `findByMonth`/`findByLinkedGoal`, closing BL-01). The core
fix is correct and does what it claims:

- `transaction_dao.dart`: `.limit(500)` was removed from `findByMonth` and
  `findByLinkedGoal` and nothing else in the filter chains changed (verified against
  `git diff d8febb3..HEAD` line-by-line). `findAll` remains the only capped list query,
  still sorted-then-capped. `findAllForAggregates` is unchanged. A full sweep of every DAO
  in `lib/` (`grep -rn "\.limit("`) found no other unsorted-cap-feeding-an-aggregate
  instance inside `transaction_dao.dart` itself — the fix is complete for this file. The
  other DAOs that still carry `.limit(500)` (`budget_dao.dart`, `debt_dao.dart`,
  `savings_goal_dao.dart`, `recurring_payment_dao.dart`,
  `transaction_category_dao.dart`, `item_dao.dart`) are out of this delta's scope — they
  were not touched by 03-13/03-14 and were already reviewed in prior passes; not
  re-litigated here.
- The class doc comment no longer claims a "single, deliberate exception" and correctly
  names all three uncapped methods.
- `transaction_dao_aggregate_completeness_test.dart` is a genuinely behavioral test: it
  seeds rows directly into a real Isar collection via `IsarTestHarness`, calls the DAO's
  actual methods, and asserts on returned row counts/fields — not on DAO source text. It
  does not repeat the WR-D6 mistake that made `transaction_dao_ordering_test.dart`
  toothless for this defect class. The RED/GREEN and mutation-check evidence quoted in the
  03-14 SUMMARY is consistent with the diff actually applied.
- `.github/workflows/ci.yml`'s pre-warm step is a `flutter test -j 1` invocation (not
  `dart run`), correctly positioned before the main `Test` step, and does not duplicate
  `flutter pub get`. `.gitignore`'s three new entries correctly keep the downloaded native
  binary untracked (confirmed: not present in `git ls-files`).

The one place with a real, if narrow, gap is `IsarTestHarness` itself: its `open()`/
`close()` pair does not defend against its own documented misuse paths — a mid-`open()`
failure leaks the temp directory it just created, and nothing guards against a second
`open()` call on an already-open instance. Neither is exercised by any of the four current
call sites (all single open/close per test), so nothing is broken *today*, but the harness
is explicitly designed as shared infrastructure for future DAO tests (`item_dao_test.dart`
is called out in both plans as the next consumer), and these gaps are exactly the kind of
thing a future author copy-pasting the `setUp`/`tearDown` pattern won't notice until CI
starts leaking temp directories intermittently.

## Warnings

### WR-01: `IsarTestHarness.open()` leaks its temp directory if `Isar.open()` throws

**File:** `test/support/isar_test_harness.dart:140-145`
**Issue:** The temp directory is created and then `Isar.open()` is awaited before either
`_tempDir` or `_isar` is assigned:

```dart
final dir = Directory.systemTemp.createTempSync('agenda_isar_test_');
final name = 'test_${DateTime.now().microsecondsSinceEpoch}';
final isar = await Isar.open(schemas, directory: dir.path, name: name);
_tempDir = dir;
_isar = isar;
return isar;
```

If `Isar.open()` throws (schema conflict, corrupted/partial native binary, disk error,
instance-name collision — see WR-02 below for how a collision could arise), the exception
propagates to the caller but `_tempDir` is never set. `close()` — called from `tearDown`/
`addTearDown` exactly as every current consumer does — then finds `_tempDir == null` and
has nothing to delete. The directory `createTempSync` just created is orphaned under
`Directory.systemTemp` for the lifetime of the machine (or until an external temp-cleaner
runs), silently defeating the "leaves no file behind" guarantee this harness's own
doc comment and Task 2's acceptance criteria specifically set out to prove — just only in
the failure path, which the current self-tests do not exercise.

**Fix:** Assign `_tempDir = dir;` immediately after creating the directory, before
awaiting `Isar.open()`, so a failed open still leaves `close()` able to clean it up:

```dart
final dir = Directory.systemTemp.createTempSync('agenda_isar_test_');
_tempDir = dir; // set before the awaited open, so close() can clean up on failure
final name = 'test_${DateTime.now().microsecondsSinceEpoch}';
final isar = await Isar.open(schemas, directory: dir.path, name: name);
_isar = isar;
return isar;
```

### WR-02: `IsarTestHarness.open()` has no guard against being called twice on the same instance

**File:** `test/support/isar_test_harness.dart:135-146`
**Issue:** Nothing prevents a caller from invoking `open()` a second time on a harness
instance that already has `_isar`/`_tempDir` set. The second call silently overwrites both
fields, orphaning the first Isar instance (never closed — its temp directory and any
lock/data files it holds are never released) and its temp directory (never deleted, same
leak class as WR-01 but reachable by misuse rather than by a thrown exception). The doc
comment says "Safe to call once per harness instance," which documents the constraint but
does not enforce it — nothing throws or asserts if it's violated.

This is not exercised by any of the four current call sites (`isar_test_harness_test.dart`,
`_warm_isar_core_test.dart`, `transaction_dao_aggregate_completeness_test.dart` — each
opens exactly once per harness instance), so nothing is broken today. But the harness is
explicitly built as shared infrastructure for future test files (both plans call out
`item_dao_test.dart`'s empty stub as the next consumer), and a future author who calls
`open()` again inside a loop, a retry, or a second `test()` body sharing one `late`
harness variable without an intervening `close()` will get a silent resource leak with no
error signal — exactly the kind of thing that causes flaky, hard-to-diagnose CI failures
weeks later, not an immediate visible break.

**Fix:** Add a defensive check at the top of `open()`:

```dart
Future<Isar> open(List<CollectionSchema<dynamic>> schemas) async {
  assert(
    _isar == null,
    'IsarTestHarness.open() called twice without an intervening close() — '
    'call close() first or use a fresh IsarTestHarness instance.',
  );
  ...
```

## Info

### IN-01: Instance name derived from wall-clock time risks collision on coarse-resolution clocks

**File:** `test/support/isar_test_harness.dart:141`
**Issue:** `'test_${DateTime.now().microsecondsSinceEpoch}'` is used to guarantee two
harness instances opened in the same process never collide on Isar's instance name. This
holds on platforms where `DateTime.now()` genuinely has microsecond resolution, but is not
guaranteed everywhere (some platforms/backends expose only millisecond resolution while
Dart still reports a `microsecondsSinceEpoch` value, just not one that changes every
microsecond). Two harnesses opened back-to-back fast enough on such a platform could
compute the same `name` and collide. The project's CI runs on `ubuntu-latest`, which is
unlikely to hit this, but the harness explicitly documents itself as intended for local
dev use too (the doc comment's own "Local-dev note" on multi-platform concurrency).
**Fix:** Use a monotonically-incrementing counter instead of wall-clock time for the name
suffix, which cannot collide regardless of clock resolution:

```dart
int _instanceCounter = 0;
...
final name = 'test_${_instanceCounter++}';
```

### IN-02: `isar_test_harness_test.dart`'s second test doesn't use `addTearDown` like the first

**File:** `test/support/isar_test_harness_test.dart:51-61`
**Issue:** The first test (`'opens a real Isar, writes a row, and reads it back'`) calls
`addTearDown(harness.close)` immediately after `open()`, so cleanup runs even if a later
assertion fails. The second test (`'close() removes the temp directory'`) does not follow
the same pattern — it calls `await harness.close();` as a plain statement at the end. If
the `expect(dir.existsSync(), isTrue)` assertion on line 56 fails, `close()` on line 58 is
never reached, and the harness's Isar instance/temp directory from that run leaks. Low
impact (this is the harness's own self-test, and the assertion is unlikely to fail once
`open()` succeeds), but it's an avoidable inconsistency in the file whose whole purpose is
to demonstrate the harness's cleanup guarantee.
**Fix:** Add `addTearDown(harness.close);` right after `open()` in the second test too,
matching the first test's pattern (and drop the manual `await harness.close();` call, or
leave it as a redundant explicit check before teardown — either works as long as teardown
also runs on failure).

### IN-03: Sibling DAOs still carry unsorted `.limit(500)` (out of scope, not a regression)

**File:** `lib/data/finance/budget/budget_dao.dart:48`,
`lib/data/finance/debt/debt_dao.dart:24`,
`lib/data/finance/goal/savings_goal_dao.dart:25`,
`lib/data/finance/recurring/recurring_payment_dao.dart:42`,
`lib/data/finance/category/transaction_category_dao.dart:25,34`,
`lib/data/tasks/item_dao.dart:27,35,43,66`
**Issue:** Noted here only for completeness per this review's specific instruction to hunt
for a "third instance" of the unsorted-cap defect class. None of these files were touched
by 03-13/03-14 and all were already reviewed in prior passes (per `03-REVIEW-pre-BL01-closure.md`
covering `recurring_payment_dao.dart`, and earlier phase reviews for the rest); this is not
a new finding, just confirmation that the sweep was done and turned up nothing new inside
the files actually in scope for this delta. Not raising a severity for these — they are
outside this review's file list and were not re-audited for whether any of them silently
feed an order-independent aggregate the way `findByMonth`/`findByLinkedGoal` did.
**Fix:** N/A for this review. If a future pass wants full confidence, verify each of these
call sites' consumers are genuinely paginated/display lists and not aggregate sums.

---

_Reviewed: 2026-08-24T03:36:08Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
