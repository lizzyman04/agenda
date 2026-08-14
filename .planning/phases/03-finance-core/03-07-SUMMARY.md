---
phase: 03-finance-core
plan: 07
subsystem: finance
gap_closure: true
tags: [finance, transactions, snackbar, undo, widget-tests, uat-gap]
requires:
  - TransactionCubit.softDelete / restoreTransaction
  - TransactionLoaded.categories (from plan 03-06)
  - AppConstants.undoSnackbarDuration
provides:
  - undo SnackBar that always belongs to the most recent delete
  - regression coverage for two deletes inside one undo window
affects:
  - lib/presentation/finance/screens/transaction_list_screen.dart (_handleDelete only)
tech-stack:
  added: []
  patterns:
    - "Destructive actions capture one ScaffoldMessenger local, hideCurrentSnackBar() then showSnackBar()"
    - "Widget tests drive a shrinking list through a StreamController, emitting a List.of(...) copy per state"
    - "Widget tests pin an explicit locale; this suite's default is en"
key-files:
  created:
    - test/presentation/finance/transaction_list_undo_test.dart
  modified:
    - lib/presentation/finance/screens/transaction_list_screen.dart
    - lib/presentation/finance/screens/README.md
    - .planning/phases/03-finance-core/03-UAT.md
decisions:
  - "One captured `messenger` local rather than resolving ScaffoldMessenger.of(context) twice — makes it unambiguous that the hide and the show target the same messenger"
  - "The explanatory comment avoids the literal string `persist: false` so the acceptance grep for the auto-dismiss fix still returns exactly one match"
  - "UAT test 3's gap flipped to `resolved` but the test-level tallies were left for phase verification — tests 2 and 9 were closed the same way by 03-06/03-08"
metrics:
  duration: ~20min
  tasks: 2
  files_changed: 3
  tests_before: 279
  tests_after: 281
  completed: 2026-08-14
---

# Phase 03 Plan 07: Undo SnackBar Lifecycle Summary

`_handleDelete` now hides the current SnackBar before showing its own, so a
second swipe-delete inside the undo window replaces the first prompt instead
of queueing behind it — closing the last open half of UAT test 3.

## What Was Built

**Task 1 — the fix.** `_handleDelete` captures
`final messenger = ScaffoldMessenger.of(context);` alongside the cubit, then
calls `messenger.hideCurrentSnackBar()` before `messenger.showSnackBar(...)`.
The SnackBar body is otherwise unchanged: same `transactionDeleted` content,
same `AppConstants.undoSnackbarDuration`, same `persist: false` with its
comment, same floating behaviour, same `restoreTransaction(tx.id)` action.
`cubit.softDelete(tx.id)` still fires before the SnackBar.

A six-line English comment sits above the hide call and records why it is
there: `ScaffoldMessenger` queues FIFO, so without it the second swipe waits
behind the first, the visible SnackBar keeps the FIRST delete's action closure,
and Desfazer restores the wrong transaction while a stale queued SnackBar
follows. The comment explicitly separates this from the `persist: false`
auto-dismiss fix immediately below it, so a future reader does not conflate the
two defects or delete either as redundant.

`lib/presentation/finance/screens/README.md` gained the line count (140 → 148)
and a new slice convention: an undo SnackBar hides the current one before
showing itself, so the visible undo always belongs to the most recent action.

**Task 2 — the regression test.**
`test/presentation/finance/transaction_list_undo_test.dart`, two tests,
`bloc_test` + `mocktail` only, no `mockito`/`provider`/`get`.

The harness drives a `MockTransactionCubit` through a
`StreamController<TransactionState>`: a mutable `remaining` list seeded with
ids 7 and 8, a `softDelete` stub that actually removes the id and pushes a
fresh `TransactionLoaded`, and `whenListen(..., initialState: snapshot())`.
Every emission carries a `List.of(remaining)` **copy** — `TransactionLoaded` is
`Equatable` over `transactions`, so re-emitting the same mutated list would
make consecutive states compare equal and leave the `Dismissible` rebuilt after
dismissal. No "dismissed Dismissible is still part of the tree" assertion
surfaced, and no assertion was weakened to route around one.

Test 1 swipes `tx-7`, asserts one SnackBar, pumps one second (well inside the
five-second window), swipes `tx-8`, asserts still exactly one SnackBar, taps
Undo, then asserts `restoreTransaction(8)` was called once,
`verifyNever(restoreTransaction(7))`, and that no SnackBar remains. Test 2
covers a single isolated delete — the guard against a fix that hides so eagerly
the normal path breaks.

## Verification — measured, not restated

Every number below was measured on the tree at `2c7a7a5`, with each gate run
unpiped so the exit code is the command's own.

| Gate | Result |
|------|--------|
| `dart run tool/check_architecture.dart` | **exit 0**, "Architecture guard: PASS" |
| `flutter analyze --no-fatal-infos --fatal-warnings` | **exit 0**, **65 issues** — baseline unchanged, zero from the new file |
| `flutter test --no-pub` | **exit 0**, **281/281 passing** (279 before this plan, +2) |
| `flutter test --no-pub test/presentation/finance/transaction_list_undo_test.dart` | **exit 0**, 2/2 |
| `awk 'END{print NR}' transaction_list_screen.dart` | **148**, ≤ 150, and the README row reads 148 |

Acceptance greps: `hideCurrentSnackBar` one match (line 53, before the
`showSnackBar` on line 54); `persist: false` one match;
`AppConstants.undoSnackbarDuration` one match;
`restoreTransaction(tx.id)` one match.
`git diff --stat test/presentation/undo_snackbar_auto_dismiss_test.dart` is
empty — the `d102f2b` fix and its three tests are untouched and still pass
inside the 281.

### Mutation check (performed, not assumed)

The `messenger.hideCurrentSnackBar();` line was deleted with `sed`, the file
backed up first, and the new test re-run. It went **red**, exit 1, `+1 -1`:

```
No matching calls. All calls: ... [VERIFIED] MockTransactionCubit.softDelete(7),
[VERIFIED] MockTransactionCubit.softDelete(8),
MockTransactionCubit.restoreTransaction(7)
```

failing at `verify(() => cubit.restoreTransaction(8)).called(1)`. That call
list is the user's reported symptom verbatim: both deletes happened, and the
undo the user could see restored **7**, the earlier transaction, not **8**, the
one just swiped. The second test (single isolated delete) stayed green, which
is exactly right — that path never had a predecessor SnackBar to queue behind.
The file was then restored from the backup and `git diff --stat` on it is
empty, confirming the tree is byte-identical to the committed `8a349d4`
version.

## Deviations from Plan

### Corrected baselines (stale numbers in the plan)

The plan was written before wave 1 merged, so three of its figures were stale
and the dispatch brief's re-measured values were used instead:

| Plan said | Actual on merged main |
|---|---|
| file is "around 124 lines" | 140 before, 148 after |
| `_handleDelete` at lines 41-59 | 43-61 |
| test baseline 275, accept ≥ 277 | 279 before, **281** after |

The 150-line cap was the binding constraint: 10 lines of headroom, not 26. No
extraction was needed — the change landed in 8 lines (one local, six comment
lines, one hide call), finishing at 148 with 2 lines to spare. Any future
addition to this file should extract rather than append.

**1. [Rule 3 - Blocking] Comment reworded to avoid a false `persist: false` grep match**
- **Found during:** Task 1
- **Issue:** The first draft of the explanatory comment contained the literal
  string `` `persist: false` ``, which made
  `grep -n "persist: false"` return **two** matches and break Task 1's
  acceptance criterion that the auto-dismiss fix still shows exactly one.
- **Fix:** Reworded to "the auto-dismiss fix below" — same meaning, no literal.
  Shortened from seven comment lines to six as a side effect, buying one more
  line of cap headroom.
- **Files modified:** `lib/presentation/finance/screens/transaction_list_screen.dart`
- **Commit:** `8a349d4`

**2. [Rule 2 - Missing critical] Planning artifacts brought into line with reality**
- **Found during:** post-task state updates
- **Issue:** `03-UAT.md` still carried test 3's queueing gap as `status: failed`
  with an open `missing:` list, and `ROADMAP.md` had 03-06 and 03-08 unchecked
  despite both being merged with SUMMARYs on disk.
- **Fix:** Test 3's gap flipped to `resolved` with a `resolved:` field, a
  host-side-only `caveat:`, the artifact note updated from "still-open" to
  "FIXED in 8a349d4", the gap-level `resolved:` counter 2 → 3, and all three
  gap-closure plans checked off in ROADMAP. Test-level tallies (`issues: 3`)
  were deliberately left for phase verification to recompute, matching how
  03-06 and 03-08 left them.
- **Files modified:** `.planning/phases/03-finance-core/03-UAT.md`, `.planning/ROADMAP.md`
- **Commit:** final docs commit

No other deviations. No architectural changes, no auth gates, no checkpoints.

## Known Stubs

None introduced. The pre-existing `'#<id>'` category fallback in this file is
the genuine no-such-category path documented by 03-06, not a stub.

## Threat Flags

None. The plan's `T-03-07-01` (undo window as the only recovery path before a
soft delete is treated as gone) is the defect this plan closes, and it is now
locked by the Task 2 regression test. No new network, auth, file-access or
schema surface was introduced.

## Caveats

Host-side verification only — no Android device was attached. This folds into
the same pending on-device re-test that the `d102f2b` auto-dismiss fix is
waiting on (the Infinix X6831). The `flutter test` reproduction is
deterministic, so the logic is proven; what hardware would add is confirmation
that real touch timing on a real 5-second window behaves the same.
