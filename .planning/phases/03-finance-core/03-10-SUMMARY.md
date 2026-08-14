---
phase: 03-finance-core
plan: 10
status: complete
completed: 2026-08-14
closes: [CR-01]
requirements: [FIN-07]  # plan frontmatter said FIN-05; see deviation 5
key_files:
  modified:
    - lib/application/finance/debt/debt_cubit.dart
    - lib/application/finance/debt/README.md
    - lib/presentation/finance/screens/debt_list_screen.dart
    - lib/presentation/finance/screens/README.md
    - lib/config/l10n/app_en.arb
    - lib/config/l10n/app_pt.arb
    - lib/config/l10n/app_pt_BR.arb
    - lib/generated/l10n/app_localizations.dart
    - lib/generated/l10n/app_localizations_en.dart
    - lib/generated/l10n/app_localizations_pt.dart
  created:
    - test/presentation/finance/debt_list_undo_test.dart
    - .planning/phases/03-finance-core/deferred-items.md
commits:
  - f68b89f  # feat(03-10): add DebtCubit.restoreDebt for the undo path
  - d892b5c  # fix(03-10): give the debt swipe an undo SnackBar (CR-01)
  - 659b0b8  # test(03-10): prove a swipe-deleted debt is recoverable
gates:
  architecture_guard: "exit 0"
  analyze: "exit 0, 65 infos"
  tests: "289/289 passing (287 baseline + 2)"
---

# 03-10: Make a swipe-deleted debt recoverable

Closes **CR-01** (Critical) from `03-REVIEW.md`.

## What was wrong

`debt_card.dart` wrapped each row in a `Dismissible` with
`onDismissed: (_) => onDelete()` and no `confirmDismiss`.
`debt_list_screen.dart` wired that straight to
`ctx.read<DebtCubit>().softDelete(debt.id)` — no SnackBar, no undo. And
`DebtCubit` had no restore method, nor did the repository or the DAO.

So one stray horizontal drag set `deletedAt` on a real debt and stranded the
row in Isar, unreachable from every screen in the app. There was no undo
window to miss; the recovery path had never been built. FIN-05 debts are
money owed and owing, which makes this the most damaging class of bug the
app can carry.

## What changed

**Restore is composed, not delegated.** `DebtCubit.restoreDebt(int id)` does
`getDebt` → `copyWith(deletedAt: null, updatedAt: now)` → `updateDebt`,
structurally mirroring `TransactionCubit.restoreTransaction`. `Debt.copyWith`
already defaults `deletedAt` to the `clearField` sentinel, so an explicit
`null` genuinely clears the tombstone rather than reading as "not provided" —
which is why no new repository or DAO method was needed. A missing record
returns silently: it is already permanently gone, and an error state would be
noise on an undo the user can no longer act on.

**The screen now follows the 03-07 house pattern exactly.** `_handleDelete`
captures both `cubit` and `messenger` into locals *before* anything can
unmount the context — that ordering is not cosmetic, it is the same class of
crash as the still-open CR-03. Then `hideCurrentSnackBar()` before
`showSnackBar(...)`, with `duration: AppConstants.undoSnackbarDuration`,
`persist: false`, `behavior: floating`, and an undo action calling
`restoreDebt` on the captured local.

`confirmDismiss` was deliberately **not** added. The plan's reasoning holds:
the undo SnackBar is the recovery mechanism, and a confirmation dialog would
tax every correct swipe to protect against the rare wrong one.

**New `debtDeleted` key added to all three ARB files** — `app_en`, `app_pt`
and `app_pt_BR` — and `flutter gen-l10n` re-run. The `undo` key already
existed and was reused.

## Verification

Each gate command run unpiped, on the committed tree:

| Gate | Result |
|---|---|
| `dart run tool/check_architecture.dart` | exit 0 |
| `flutter analyze --no-fatal-infos --fatal-warnings` | exit 0, **65 infos** (budget held; `lines_longer_than_80_chars` still 0) |
| `flutter test --no-pub` | exit 0, **289/289** (287 baseline + 2 new) |

`debt_cubit.dart` 93 → 127 lines, `debt_list_screen.dart` 93 → 130. Both
under the 150 cap, so no extraction was needed; both README line counts
updated.

### Mutation check — actually run, red observed

Replaced `onPressed: () => cubit.restoreDebt(debt.id)` with
`onPressed: () {}` and re-ran the new file. **Both** tests failed
(`+0 -2`), test 1 with:

```
No matching calls. All calls: MockDebtCubit.stream, MockDebtCubit.start(),
MockDebtCubit.state, MockDebtCubit.state, MockDebtCubit.stream,
[VERIFIED] MockDebtCubit.softDelete(4)
```

The mock recorded `softDelete(4)` and nothing else — precisely the CR-01
shape, where the delete lands and no restore ever follows. Reverted; `git
diff --stat` on `debt_list_screen.dart` came back empty.

## Deviations from plan

**1. [Rule 3 - Blocking] Two analyzer infos had to be designed out, not
inherited.** Copying `transaction_list_screen._handleDelete` verbatim pushed
analyze to **67 infos** — two over the load-bearing 65 budget — because the
original carries a `discarded_futures` on its bare `softDelete(...)` call and
a `cascade_invocations` on the `messenger.hide` / `messenger.show` pair. The
debt copy uses `unawaited(cubit.softDelete(debt.id))` and a `messenger
..hideCurrentSnackBar() ..showSnackBar(...)` cascade instead. No `// ignore:`
comment was used. This is worth flagging for the remaining wave-3 plans: the
house pattern being copied is itself two infos over-budget per copy site.

**2. [Rule 3 - Blocking] One more info from the new test file.**
`DateTime(2026, 9, 1)` in the debt fixture tripped
`avoid_redundant_argument_values` — day 1 is `DateTime`'s default. Caught by
gating **before** committing task 3, which is exactly the failure mode 03-09
hit from the opposite direction. Changed to `DateTime(2026, 9, 15)`.

**3. `isClosed` guard added where the surrounding cubit has none.** The plan
anticipated this. `DebtCubit`'s existing `createDebt`, `updateDebt`,
`togglePaid` and `softDelete` all `emit(DebtError(...))` after an await with
no `isClosed` check — only `_reload()` guards. `restoreDebt` guards, because
an undo SnackBar demonstrably outlives the screen that owns the cubit: the
user can navigate away and still tap Desfazer within the 5-second window.
The four unguarded siblings are warning **WR-02**'s subject and were left for
its plan rather than widened into here.

**4. `restoreDebt` reloads explicitly, matching `togglePaid`.** This cubit is
inconsistent — `togglePaid` calls `await _reload()` while `createDebt`,
`updateDebt` and `softDelete` trust the `watchChanges()` stream. The plan
directed matching `togglePaid`, which is also the right call on its own
merits: a restore is state the user is actively waiting to see reappear.

**5. Plan frontmatter cited the wrong requirement.** `03-10-PLAN.md` declares
`requirements: [FIN-05]`, and its objective repeats "FIN-05 debts are money
owed and owing". `REQUIREMENTS.md:29` defines **FIN-05** as *savings goals*;
debts are **FIN-07** (`REQUIREMENTS.md:31`). This SUMMARY records FIN-07.
Nothing was checked off in `REQUIREMENTS.md` either way — every FIN item is
still `Pending`, this is a gap-closure bug fix rather than feature delivery,
and phase 03 verification owns that sign-off.

## Known stubs

None.

## Deferred

Logged to `deferred-items.md`, both out of scope under the scope-boundary
rule:

- `debt_card.dart:101` renders the paid toggle as a hardcoded PT-BR literal
  (`'Pago'` / `'Pendente'`), so it stays Portuguese under the `en` locale.
  Pre-existing and untouched by CR-01, but it is the same hardcoded-string
  defect class this project already tracks.
- `transaction_list_screen.dart:46,54` still carries the two analyzer infos
  described in deviation 1. Applying the same `unawaited` + cascade treatment
  there would drop the project baseline from 65 to 63.

## Self-Check: PASSED

All three files exist on disk, all three commit hashes resolve in
`git log --all`, and the acceptance greps hold: `restoreDebt` present in both
`debt_cubit.dart` and `debt_list_screen.dart`, `hideCurrentSnackBar` and
`persist: false` each present once in the screen.

## Carried forward

Wave 3 has two plans left — 03-11 (CR-02) and 03-12 (CR-03 + WR-07). The new
test baseline for them is **289**, not 287. The analyze budget is unchanged
at 65.
