---
phase: 03-finance-core
reviewed: 2026-08-15T06:47:41Z
depth: standard
scope: delta
prior_review: .planning/phases/03-finance-core/03-REVIEW-pre-gap-closure.md
files_reviewed: 22
files_reviewed_list:
  - lib/data/finance/transaction/transaction_dao.dart
  - lib/domain/finance/transaction/transaction_repository.dart
  - lib/infrastructure/finance/transaction_repository_impl.dart
  - lib/application/finance/dashboard/home_dashboard_cubit.dart
  - lib/application/finance/debt/debt_cubit.dart
  - lib/presentation/finance/screens/debt_list_screen.dart
  - lib/data/finance/recurring/recurring_payment_dao.dart
  - lib/domain/finance/recurring/recurring_payment_repository.dart
  - lib/infrastructure/finance/recurring_payment_repository_impl.dart
  - lib/application/finance/recurring/recurring_payment_cubit.dart
  - lib/application/finance/recurring/recurring_payment_state.dart
  - lib/presentation/finance/screens/recurring_payment_screen.dart
  - lib/presentation/finance/widgets/recurring/recurring_payment_card.dart
  - lib/presentation/tasks/screens/task_detail_screen.dart
  - lib/presentation/finance/widgets/budget/budget_limit_sheet.dart
  - lib/config/l10n/app_en.arb
  - lib/config/l10n/app_pt_BR.arb
  - test/presentation/finance/debt_list_undo_test.dart
  - test/presentation/finance/recurring_payment_visibility_test.dart
  - test/presentation/tasks/task_detail_undo_test.dart
  - test/application/finance/home_dashboard_cubit_test.dart
  - test/data/finance/transaction_dao_ordering_test.dart
findings:
  critical: 1
  warning: 8
  info: 0
  total: 9
status: issues_found
---

# Phase 3: Code Review Report (delta — gap closure 03-09 … 03-12)

**Reviewed:** 2026-08-15T06:47:41Z
**Depth:** standard (delta)
**Files Reviewed:** 22
**Status:** issues_found

## Summary

Four of the five fixes hold. `flutter analyze` reports 65 issues (exactly the
budget, zero errors, zero `lines_longer_than_80_chars`) and `flutter test`
passes 297/297, so nothing below is a build or suite failure — every finding is
a behavioural or maintainability defect that the green suite does not catch.

**Fix verification:**

| Prior ID | Plan | Verdict |
|---|---|---|
| CR-01 debt delete unrecoverable | 03-10 | **Closed** |
| CR-02 recurring pause is a one-way trap | 03-11 | **Closed** (reversibility); one remedy item from the finding skipped — WR-D4 |
| CR-03 task-detail undo on a popped route | 03-12 | **Closed** |
| CR-04 500-row cap on transaction reads | 03-09 | **Partially closed** — BL-01 |
| WR-07 budget sheet re-implements the parser | 03-12 | **Partially closed** — WR-D1 / WR-D2 |

Detail:

- **CR-01 — closed.** `DebtCubit.restoreDebt` (`debt_cubit.dart:76-103`) is
  correct end to end, and I traced every link rather than trusting the shape:
  `DebtRepositoryImpl.getDebt` goes through `DebtDao.findById` (a raw
  `collection.get`, *not* the `deletedAtIsNull()`-filtered `findAll`), so a
  tombstoned row is genuinely readable; `Debt.copyWith` uses the `clearField`
  sentinel (`debt.dart:72-86`) so `deletedAt: null` really clears rather than
  reading as "not provided"; `DebtMapper.toModel` writes `deletedAt` back, so
  the `put` persists the cleared tombstone; and `updateDebt`'s own
  `copyWith(updatedAt:)` cannot re-set it. `debt_list_screen.dart:46-47`
  captures `cubit` and `messenger` before the row can unmount, and
  `hideCurrentSnackBar()` precedes `showSnackBar` so a second swipe replaces
  rather than queues. `debt_list_undo_test.dart:124-127,162-166` actually taps
  Undo and asserts the *second* delete's id is the one restored — the case that
  a queued-SnackBar bug would fail.
- **CR-02 — closed for reversibility.** `recurring_payment_dao.dart:37-43` no
  longer filters `isActive`, sorts active-first *before* `.limit(500)` (so the
  cap cannot evict a live payment in favour of a paused one), and still filters
  `deletedAtIsNull()`. `getPayments()` has exactly one consumer
  (`recurring_payment_cubit.dart:65`), so the rename cannot have silently
  changed some other total's meaning — I grepped for every call site.
  `recurring_payment_card.dart:51-89` dims the row but keeps the toggle at full
  opacity, and the label is localized. Reversible.
- **CR-03 — closed.** `task_detail_screen.dart:49-52` resolves the cubit, the
  messenger *and* both strings into locals before `Navigator.pop()`; the
  `SnackBarAction` closure (line 69) touches only the captured cubit. The new
  test pushes a real route, asserts `find.byType(TaskDetailScreen)` is gone, and
  then taps Undo — the exact sequence the old tests never performed.
  `TaskListCubit` is app-scoped (`app.dart:68`) and its `close()` cancels the
  undo timer, so the captured cubit cannot be closed under the SnackBar.
- **CR-04 — partially closed.** The dashboard path is genuinely fixed
  (`findAllForAggregates` is uncapped, `home_dashboard_cubit.dart:69-70` uses
  it, and the list read now sorts before capping). But two other reads that also
  feed money totals were left capped and unsorted — see **BL-01**.
- **WR-07 — partially closed.** `budget_limit_sheet.dart:60` now calls the
  shared `parseAmountCentsOrNull`, and the sheet no longer pops on a rejected
  value. The error the user is supposed to see, however, is almost certainly
  invisible — see **WR-D1**.

The new defects below are concentrated in the seams the fixes touched: the
reads CR-04's fix did not cover, the feedback path WR-07's fix added, and the
recurring-payment slice CR-02's fix half-remediated.

Findings marked *(dependency)* live in a file outside the submitted list but are
reachable only through, and caused only by, a file in it.

## Critical Issues

### BL-01: CR-04 is only half closed — budget spend and goal progress still aggregate from a capped, unsorted read

**File:** `lib/data/finance/transaction/transaction_dao.dart:51-63` and
`68-75`, consumed by `lib/application/finance/budget/budget_cubit.dart:78-88`
*(dependency)* and `lib/application/finance/goal/goal_cubit.dart:94-103`
*(dependency)*

**Issue:** The fix split the *list* read from the *aggregate* read and cleaned
up `findAll`/`findAllForAggregates`, but `findByMonth` and `findByLinkedGoal`
were left exactly as CR-04 described them: `.limit(500)` with no `sortBy`. Both
are aggregate reads, not display lists:

- `BudgetCubit._reload` (line 78) calls `getByMonth(month, year)` and folds the
  result into per-category spend, which drives the budget progress bars and the
  over-limit warning.
- `GoalCubit._refreshGoal` (line 94) calls `getByLinkedGoal(goal.id)` and folds
  it into `taggedCents`, which is the tagged half of `amountSavedCents` and of
  `progressPercent`.

Because there is no sort, Isar returns rows in id order and the cap keeps the
*oldest* 500 — so past the threshold each figure silently omits the user's most
recent activity and drifts further with every new row, which is the identical
failure mode and identical invisibility that made CR-04 critical. A budget bar
that under-reports spend is worse than one that reports nothing: it tells the
user they are under a limit they have already blown.

The exposure is narrower than CR-04's (500 expense rows *in one month*, or 500
transactions tagged to *one goal*, versus 500 rows overall), but it is not
theoretical, and nothing in the code, the tests or the UI would reveal it.

Worse, the class doc that plan 03-09 added at
`transaction_dao.dart:5-11` now actively misdescribes the file:

> "List queries additionally apply .limit(500) — with the single, deliberate
> exception of `findAllForAggregates`, which must stay uncapped so dashboard
> totals are exact"

`findByMonth` and `findByLinkedGoal` are not list queries, and their totals are
not exact. A future reader who trusts that comment will conclude the aggregate
problem is fully solved.

**Fix:** Treat these two as the aggregate reads they are — drop the cap, and add
a sort only where order is consumed:

```dart
/// Returns EVERY active expense in [month]/[year] — deliberately uncapped.
/// Feeds BudgetCubit's per-category spend, which is a TOTAL: a capped read
/// makes it silently low rather than obviously incomplete (CR-04).
Future<List<TransactionModel>> findByMonth(int month, int year) async {
  final from = DateTime(year, month);
  final to = DateTime(year, month + 1);
  return _collection
      .filter()
      .deletedAtIsNull()
      .and()
      .typeEqualTo(TransactionType.expense)
      .and()
      .dateBetween(from, to, includeUpper: false)
      .findAll();
}

/// Returns EVERY active transaction tagged with [goalId] — uncapped, same
/// reason: goal progress is a total, not a page.
Future<List<TransactionModel>> findByLinkedGoal(int goalId) async =>
    _collection
        .filter()
        .linkedGoalIdEqualTo(goalId)
        .and()
        .deletedAtIsNull()
        .findAll();
```

and correct the class doc so "the single, deliberate exception" is no longer
claimed. Add the assertion to `transaction_dao_ordering_test.dart` alongside the
existing `findAllForAggregates` one (see WR-D6 — the current source-text tests
cannot see either method).

## Warnings

### WR-D1: the budget sheet's new validation SnackBar renders behind the sheet that triggered it

**File:** `lib/presentation/finance/widgets/budget/budget_limit_sheet.dart:61-69`

**Issue:** `_submit` reports a rejected amount with
`ScaffoldMessenger.of(context).showSnackBar(...)` from inside the builder of a
`showModalBottomSheet` route (`budget_overview_screen.dart:40-51`). The
`ScaffoldMessenger` found by that lookup is the app-level one created by
`MaterialApp`; its SnackBar is laid out inside the `Scaffold` underneath, while
the modal sheet route and its barrier sit above the whole `Scaffold` in the
`Navigator`. A `SnackBarBehavior.floating` bar is anchored at the bottom of the
screen — precisely the region the sheet occupies (more so with the keyboard
open, since `autofocus: true` guarantees it is). So the user types `1.250,00`,
taps Salvar, and observes: nothing happens.

That is the *same symptom* WR-07 recorded ("the sheet closes and no limit is
saved, with no error shown at all"), minus the silent close. The class doc at
lines 16-18 asserts the sheet "shows a validation error"; in practice it shows
one the user cannot see. Note the deferred-parser comment at lines 55-59 makes
the PT-BR thousands-separator input the *expected* way to hit this branch, so it
is the common path, not the exotic one.

**Fix:** Keep the feedback inside the sheet, where it is on top of the stack:

```dart
String? _errorText;

void _submit() {
  final limitCents = parseAmountCentsOrNull(_controller.text);
  if (limitCents == null) {
    setState(() => _errorText = AppLocalizations.of(context).errorAmountRequired);
    return;
  }
  Navigator.of(context).pop(limitCents);
}
```
and pass `errorText: _errorText` into the `TextField`'s `InputDecoration`
(clearing it in `onChanged`). This also removes the `ScaffoldMessenger` lookup
from a route that is about to be popped.

### WR-D2: the branch WR-07's fix added is the one branch with no test

**File:** `test/presentation/finance/budget_limit_sheet_test.dart:91-120`
*(dependency)* against
`lib/presentation/finance/widgets/budget/budget_limit_sheet.dart:60-70`

**Issue:** The existing sheet test enters `'250,00'` and asserts `setLimit` is
called — the happy path, which behaved identically before the fix. Nothing
exercises `parseAmountCentsOrNull` returning null: not that the sheet stays
open, not that `setLimit` is *not* called, not that any error surface appears.
Every one of the three fix plans in this wave shipped a regression test that
fails against the pre-fix code; this one did not, which is why WR-D1 could slip
through with a green suite.

**Fix:** Add a widget test that enters `'1.250,00'`, taps the save button, and
asserts `find.byType(TextField)` is still present, `setLimit` was never called,
and the error surface is findable (after WR-D1, `errorText` — assert on the
rendered `l10n.errorAmountRequired`). Follow the file's existing "never
`pumpAndSettle` here" note.

### WR-D3: the recurring card localizes the paused label but leaves its subtitle hardcoded PT-BR

**File:** `lib/presentation/finance/widgets/recurring/recurring_payment_card.dart:37-39,64-69`
(with `lib/presentation/finance/widgets/recurring/recurring_payment_schedule_fields.dart:79-87`
*(dependency)*)

**Issue:** Plan 03-11 edited this widget specifically to route the active/paused
label through `AppLocalizations` — and left the line directly above it as
`'${cycleLabel(payment.cycle)} · Próximo: $nextDueLabel'`. Three separate
locale defects on that one line:

1. `Próximo:` is a hardcoded PT-BR literal in a widget that already holds
   `final l10n = AppLocalizations.of(context)` two lines up.
2. `cycleLabel` is documented as "PT-BR label" and returns `'Mensal'`,
   `'Diário'`… unconditionally for every locale.
3. `DateFormat('dd/MM/yyyy')` is constructed with no locale, ignoring the
   `locale` field the widget already receives and uses for `formatAmount`.

With the app in EN the row reads "Mensal · Próximo: 10/09/2026" directly under
the correctly-localized "Paused" — an inconsistency inside a single card.
CLAUDE.md makes localization of UI text a hard requirement, and the ARB files
already gained three keys in this wave, so the mechanism was right there.

**Fix:** Add `recurringNextDue` (with a `{date}` placeholder) and six cycle keys
to `app_en.arb` / `app_pt.arb` / `app_pt_BR.arb`, regenerate, and make
`cycleLabel` take `AppLocalizations`:

```dart
String cycleLabel(AppLocalizations l10n, RecurringCycle cycle) =>
    switch (cycle) {
      RecurringCycle.daily => l10n.cycleDaily,
      // …
    };

final nextDueLabel =
    DateFormat.yMd(locale.toLanguageTag()).format(payment.nextDueDate);
subtitle: Text('${cycleLabel(l10n, payment.cycle)} · '
    '${l10n.recurringNextDue(nextDueLabel)}'),
```
`recurring_payment_schedule_fields.dart:45` is the other call site and already
has an `l10n` in scope.

### WR-D4: recurring payments still cannot be deleted — the whole soft-delete chain is unreachable dead code

**File:** `lib/application/finance/recurring/recurring_payment_cubit.dart:50-58`,
`lib/domain/finance/recurring/recurring_payment_repository.dart:32-34`,
`lib/infrastructure/finance/recurring_payment_repository_impl.dart:95-109`,
`lib/data/finance/recurring/recurring_payment_dao.dart:50-57`

**Issue:** CR-02 named this explicitly ("Also wire `softDelete` to a swipe (with
undo, per CR-01) or delete the unused method") and 03-11 did neither.
`grep -rn "softDelete" lib/presentation/` returns no recurring-payment hit:
`RecurringPaymentScreen` has a tap-to-edit, a FAB and a pause toggle, and no
delete affordance of any kind. Four layers of soft-delete plumbing therefore
exist with zero callers.

Two costs. First, functional: a user who cancels a subscription has no way to
remove it — the best available action is pausing, so the list accumulates dead
rows forever, and the only reason that is not data loss is that it is data
*accretion*. Second, structural: the CR-02 fix now depends on
`deletedAtIsNull()` being the real delete filter (see the DAO doc at lines
23-28), but nothing in the app can ever set `deletedAt` on this collection, so
that filter is untested by construction and no one will notice if it breaks.

**Fix:** Wire it, following the pattern this wave just built twice — wrap
`RecurringPaymentCard` in a `Dismissible` and route `onDismissed` through a
`_handleDelete` that mirrors `debt_list_screen.dart:42-74` (capture cubit +
messenger, `hideCurrentSnackBar`, `persist: false`, undo action). That also
needs a `restorePayment` on the cubit, composed exactly like `restoreDebt`
(`getPayment` → `copyWith(deletedAt: null)` → `updatePayment`; the
`clearField` sentinel is already in `RecurringPayment.copyWith`). If delete is
deliberately out of scope for phase 3, delete the four unused methods instead
and say so in the slice README — do not leave an unreachable delete path in a
finance app.

### WR-D5: `updatePayment` skips the `categoryId` validation that `createPayment` enforces

**File:** `lib/infrastructure/finance/recurring_payment_repository_impl.dart:76-93`

**Issue:** `createPayment` rejects `title.isEmpty`, `amountCents <= 0` *and*
`categoryId <= 0` (lines 28-40). `updatePayment` checks only the first two. So a
payment can be created with a valid category and then updated to
`categoryId: 0`, which persists a row whose category cannot resolve — the
charts and forms all look it up by id and fall back to `#0` or a null category.
`TransactionRepositoryImpl` gets this right: its `updateTransaction`
(lines 107-116) repeats both checks from `createTransaction`. This is the one
repository in the finance slice where create and update disagree, which is
exactly the sort of asymmetry a reader will assume is intentional.

**Fix:** Add the missing guard so the two paths enforce the same invariant:

```dart
if (payment.categoryId <= 0) {
  return const Err(
    ValidationFailure('categoryId must be a valid reference'),
  );
}
```

### WR-D6: the new DAO "query shape" tests assert on source text and cannot see the defect they are meant to guard

**File:** `test/data/finance/transaction_dao_ordering_test.dart:93-103,195-240`
and `test/presentation/finance/recurring_payment_visibility_test.dart:81-91,98-151`

**Issue:** Both suites read the DAO file with `File(path).readAsStringSync()`
and assert on substring positions. Three concrete weaknesses:

1. **They pin one method and imply the file.** `transaction_dao_ordering_test`
   asserts `findAll()` sorts before capping and `findAllForAggregates()` has no
   `.limit(`. Every assertion passes against the file as it stands today —
   with BL-01 live in `findByMonth` and `findByLinkedGoal` two methods below.
   The suite's own header claims it "pins the fix"; it pins a third of it.
2. **`_methodBody` assumes an expression body.** It slices from the signature to
   the first `;`. Convert `findAll()` to a block body (as `findByMonth` already
   is) and the "body" becomes the first statement only — the sort assertion
   would fail on correct code, or, with a differently-ordered block, pass on
   incorrect code. `findByMonth` cannot be asserted with this helper at all,
   which may be why it was not.
3. **Substring matching is not semantics.** `body.contains('sortByDateDesc()')`
   is satisfied by the token appearing anywhere in the slice, including inside a
   trailing comment.

These are the only tests standing behind CR-04's and CR-02's query shape, so
their limits are load-bearing.

**Fix:** Short term, extend the source assertions to `findByMonth` and
`findByLinkedGoal` (after BL-01: assert `.limit(` is absent from both) and make
`_methodBody` brace-aware, or match on a normalized whitespace-stripped
signature-to-`findAll()` slice. Medium term, this project's repeated
"no infrastructure for a real Isar instance in a test" note is now the reason
three critical findings have text-matching coverage instead of behavioural
coverage — stand up a single `initializeIsarCore` + temp-directory test helper
and assert the returned rows, which makes all six of these assertions real and
the `_methodBody` helper unnecessary.

### WR-D7: cubit docs claim "a fresh instance per screen" while `app.dart` provides one instance for the app's lifetime

**File:** `lib/application/finance/debt/debt_cubit.dart:15,92-94`,
`lib/application/finance/recurring/recurring_payment_cubit.dart:17`
(against `lib/app.dart:37-47` *(dependency)*)

**Issue:** Both class docs end with "Factory (not singleton) — a fresh instance
per debt screen / per recurring payment screen". The `@injectable` registration
is indeed a factory, but `app.dart` calls `getIt<DebtCubit>()` once inside a
`BlocProvider` mounted *above* `MaterialApp`, so exactly one instance exists per
app launch and it is never closed while the app runs — as
`debt_list_screen.dart:34` and `recurring_payment_screen.dart:35` both note in
their own comments. The docs and the wiring say opposite things about lifetime
in the same feature.

This is not cosmetic: `restoreDebt`'s new comment at lines 92-93 ("the cubit can
be closed while the two awaits above are in flight — the undo snackbar outlives
the screen that owns this cubit") is reasoning from the wrong model. The guard
it justifies is harmless and worth keeping, but the next person to reason about
lifetime here — for instance when fixing WR-01's leaked subscriptions, which
depends entirely on these cubits being app-scoped — will start from a false
premise. Same wrong premise sits in `lib/application/finance/debt/README.md`
("Factory, not singleton — a fresh instance per debt screen").

**Fix:** Correct both class docs and the slice READMEs to state the real
lifetime, and re-word the `restoreDebt` comment to the accurate reason:

```dart
/// Registered as a factory, but `app.dart` provides a single instance
/// ABOVE MaterialApp, so one cubit serves the whole session and every
/// pushed route inherits it. The isClosed guard below is defensive: it
/// costs nothing and keeps the method safe if the provider is ever
/// scoped to a route.
```

### WR-D8: a failed debt undo is indistinguishable from a successful one — the user gets no signal at all

**File:** `lib/application/finance/debt/debt_cubit.dart:77-85`

**Issue:** `restoreDebt` bails out silently on any `Err` from `getDebt`, with
the comment "Debt not found — silently ignore (already permanently deleted)".
But `DebtRepositoryImpl.getDebt` (lines 42-53) returns
`Err(DatabaseFailure(...))` for *both* "not found" and a thrown Isar error —
the two are indistinguishable at this call site, and neither is
"already permanently deleted", because nothing in this app hard-deletes a debt.
So the realistic trigger is a transient read failure, and the user experience is:
tap Desfazer, the SnackBar disappears, the debt does not come back, no error, no
retry. The undo path added for CR-01 is precisely where a silent failure is
least acceptable, since by then the row is already off screen.

**Fix:** Surface it, or at minimum stop asserting the wrong cause:

```dart
case Err<Debt>(:final failure):
  // Not-found and read-failure are indistinguishable here, so treat
  // both as a failed undo rather than assuming the row is gone.
  if (!isClosed) emit(DebtError(failure));
  return;
```
Better still, give `DebtRepository` a typed `NotFoundFailure` so the two can be
told apart, and show a "could not undo" SnackBar rather than replacing the whole
list with `Center(child: Text(failure.message))` (the WR-03 error-surface
problem, still open).

## Carried Over — still open from the archived report

These are **not** new findings. They are recorded here so the delta report does
not lose the open record from
`.planning/phases/03-finance-core/03-REVIEW-pre-gap-closure.md`, which remains
the authoritative description of each. Status re-verified against the current
tree.

| ID | One-line description | Status |
|---|---|---|
| CR-04 | 500-row cap on transaction reads | **Partially closed** — dashboard fixed by 03-09; `findByMonth` / `findByLinkedGoal` still capped (now tracked as BL-01) |
| WR-01 | `start()` not idempotent — a leaked watch subscription per tab revisit | Open — `transaction_cubit.dart:33`, `budget_cubit.dart:37`, `debt_cubit.dart:24`, `goal_list_cubit.dart:24` still overwrite `_watchSubscription`; only `HomeDashboardCubit` guards |
| WR-02 | `GoalCubit` emits after every await with no `isClosed` guard | Open |
| WR-03 | Forms report success regardless of whether the write succeeded | Open — and the two undo paths added this wave (`debt_list_screen.dart:50`, `task_detail_screen.dart:54`) fire-and-forget the delete the same way |
| WR-04 | Budget empty-state CTA is an inert button | Open |
| WR-05 | Dashboard hides real data behind a zero-balance heuristic | Open |
| WR-06 | Charts always render PT-BR category names, ignoring the locale | Open — WR-D3 is the same class of defect in a different widget |
| WR-07 | Budget sheet re-implemented the amount parser | **Partially closed** — shared parser now called (`budget_limit_sheet.dart:60`); the rejection is surfaced but not visibly (WR-D1) and not tested (WR-D2) |
| WR-08 | Money pre-fill uses ad-hoc double arithmetic instead of `formatCentsForInput` | Open — still inline at `budget_limit_sheet.dart:39-45`, in the file 03-12 edited |
| WR-09 | Goal form resolves a throw-away `GoalCubit` per save, swallows the failure | Open |
| WR-10 | Hardcoded PT-BR `'Pago'` / `'Pendente'` in the debt card | Open — `debt_card.dart:101` |
| WR-11 | `MigrationRunner` records a version bump for a migration case that does not exist | Open |
| IN-01 | `mergeBudgetData`'s backfill loop is unreachable | Open |
| IN-02 | `restoreTransaction` has no cubit unit test | Open — still covered only indirectly by `transaction_list_undo_test.dart` |
| IN-03 | `app_pt.arb` and `app_pt_BR.arb` are identical with two different roles | Open — the three new keys were added to both by hand this wave, which is the maintenance cost the finding predicted; still nothing enforces it |

No prior finding was made materially worse by this wave.

---

_Reviewed: 2026-08-15T06:47:41Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard (delta scope)_
