---
quick_id: 260824-8k6
slug: fix-isartestharness-warnings-wr-01-wr-02
type: quick
created: 2026-08-24T04:09:49Z
source: .planning/phases/03-finance-core/03-REVIEW.md (WR-01, WR-02, IN-01, IN-02)
files_modified:
  - test/support/isar_test_harness.dart
  - test/support/isar_test_harness_test.dart
---

# Quick Task 260824-8k6: Close the IsarTestHarness review findings

## Objective

Close all four `IsarTestHarness` findings from the 03-13/03-14 delta code review. The harness
was built as shared test infrastructure and currently has exactly three call sites, none of
which exercise these paths — so nothing is broken today. The point is that the next consumer
(`item_dao_test.dart`'s empty stub is the named candidate) inherits them.

The four are causally linked, which is why they are fixed together rather than just the two
warnings: IN-01's name collision is one of the concrete ways `Isar.open()` can throw, and a
throw is exactly what WR-01 leaks on.

## Findings being closed

**WR-01 — `open()` leaks its temp directory if `Isar.open()` throws.**
`isar_test_harness.dart:140-145`. The directory is created, then `Isar.open()` is awaited
*before* `_tempDir` is assigned. If the open throws, the exception propagates but `_tempDir`
is still null, so `close()` — which every consumer calls from `tearDown`/`addTearDown` — finds
nothing to delete. The directory is orphaned under `Directory.systemTemp` for the lifetime of
the machine, silently defeating the "leaves no file behind" guarantee this harness's own doc
comment makes.

**WR-02 — `open()` has no guard against being called twice.**
`isar_test_harness.dart:135-146`. A second `open()` on the same instance silently overwrites
`_isar` and `_tempDir`, orphaning the first Isar instance (never closed, its lock/data files
never released) and its temp directory. The doc comment says "Safe to call once per harness
instance" but nothing enforces it. Reachable by ordinary misuse — a retry, a loop, or two
`test()` bodies sharing one `late` harness without an intervening `close()`.

**IN-01 — instance name derived from wall-clock time.**
`isar_test_harness.dart:141`. `'test_${DateTime.now().microsecondsSinceEpoch}'` assumes true
microsecond resolution. Not guaranteed on every platform; two harnesses opened back-to-back
could compute the same name and collide. A collision is one way to trigger the WR-01 throw.

**IN-02 — the harness's own second self-test can leak.**
`isar_test_harness_test.dart:51-61`. The first test uses `addTearDown(harness.close)`, so
cleanup runs even if an assertion fails. The second calls `await harness.close()` as a plain
trailing statement — if `expect(dir.existsSync(), isTrue)` fails, close never runs and the
directory leaks. Same class as WR-01, in the file whose job is to prove the harness is clean.

## Tasks

### Task 1 (RED first): Tests proving the leak and the double-open hole

Add tests to `test/support/isar_test_harness_test.dart` covering the failure paths that no
current test exercises:

1. **WR-01 — temp dir is recoverable after a failed open.** Drive `open()` into a throw and
   assert the harness still exposes a `tempDir` that `close()` then removes, leaving nothing
   behind. Obtain the throw honestly rather than by mocking the harness: passing a schema
   list that Isar rejects, or opening a second harness under a deliberately forced name
   collision, are both acceptable. Capture the directory path before asserting it is gone.
   If no reliable in-process way to make `Isar.open()` throw is available, state that plainly
   in the SUMMARY and instead assert the ordering invariant directly — that `tempDir` is
   non-null at the point `Isar.open()` is entered — rather than silently skipping the case.

2. **WR-02 — a second `open()` is refused.** Open a harness, then call `open()` again and
   expect a `StateError`. Assert the first instance is still the live one (`harness.isar` is
   unchanged and still usable) — the guard must refuse the second call, not half-apply it.

Both tests must use `addTearDown` for cleanup, per IN-02.

**Observe both FAIL against the current harness before Task 2.** Test 1 should show the
directory surviving; test 2 should show no throw. A test that passes before the fix proves
nothing — that is the exact failure mode that let the BL-01 defect class survive three
closure attempts in this phase.

<verify>
<automated>flutter test --no-pub test/support/isar_test_harness_test.dart</automated>
</verify>

<acceptance_criteria>
- Run against the UNMODIFIED harness, both new tests FAIL.
- Both new tests use `addTearDown` rather than a trailing `close()` call.
</acceptance_criteria>

<done>
Tests exist that fail against the current harness for both the temp-dir leak and the missing
double-open guard, with the failures observed and recorded rather than assumed.
</done>

### Task 2: Fix all four findings

In `test/support/isar_test_harness.dart`:

- **WR-01** — assign `_tempDir = dir;` immediately after `createTempSync`, before awaiting
  `Isar.open()`, so a failed open still leaves `close()` able to clean up.
- **WR-02** — throw a `StateError` at the top of `open()` if `_isar != null`, with a message
  that names the fix (`call close() before reopening, or use a fresh IsarTestHarness`).
  Update the doc comment from "Safe to call once per harness instance" to state that a second
  call throws.
- **IN-01** — replace the wall-clock instance name with a monotonically-incrementing static
  counter, so uniqueness does not depend on clock resolution.

In `test/support/isar_test_harness_test.dart`:

- **IN-02** — convert the existing `'close() removes the temp directory'` test to
  `addTearDown`, matching the first test. `close()` is already documented idempotent and safe
  to call twice, so an explicit mid-test `close()` plus a tear-down `close()` is fine; the
  point is that the tear-down runs even when an assertion fails.

Change nothing else. Do not alter the top-of-file doc comment's binary-acquisition,
concurrent-download-race, or `Platform.script` sections — those are load-bearing and were
settled across three plan revisions.

<verify>
<automated>flutter test --no-pub && flutter analyze --no-fatal-infos --fatal-warnings && dart run tool/check_architecture.dart</automated>
</verify>

<acceptance_criteria>
- Task 1's tests now pass.
- `grep -n "microsecondsSinceEpoch" test/support/isar_test_harness.dart` returns NO match.
- `_tempDir` is assigned before the `await Isar.open(...)` line.
- `open()` throws `StateError` when called twice.
- `flutter test --no-pub`: strictly more than 304 passing, exit 0.
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, no increase over the 65-issue budget, 0 `lines_longer_than_80_chars`.
- `dart run tool/check_architecture.dart`: exit 0 (harness file must stay under the 150-line cap).
</acceptance_criteria>

<done>
All four findings closed, the Task 1 tests that failed now pass, and all three gates hold at
their current baselines.
</done>

## Out of scope

- Anything in `lib/`. This task touches test infrastructure only.
- The empty `test/data/tasks/item_dao_test.dart` stub — the named future consumer of this
  harness, but a separate decision nobody has made yet.
- The harness's network-dependent `initializeIsarCore(download: true)` residual risk, which is
  documented and accepted.
