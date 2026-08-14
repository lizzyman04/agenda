---
phase: 03-finance-core
plan: 11
status: complete
completed: 2026-08-15
closes: [CR-02]
requirements: [FIN-06]
key_files:
  modified:
    - lib/data/finance/recurring/recurring_payment_dao.dart
    - lib/domain/finance/recurring/recurring_payment_repository.dart
    - lib/infrastructure/finance/recurring_payment_repository_impl.dart
    - lib/application/finance/recurring/recurring_payment_cubit.dart
    - lib/application/finance/recurring/recurring_payment_state.dart
    - lib/application/finance/recurring/README.md
    - lib/presentation/finance/screens/recurring_payment_screen.dart
    - lib/presentation/finance/screens/README.md
    - lib/presentation/finance/widgets/recurring/recurring_payment_card.dart
    - lib/presentation/finance/widgets/recurring/README.md
    - lib/config/l10n/app_en.arb
    - lib/config/l10n/app_pt.arb
    - lib/config/l10n/app_pt_BR.arb
    - lib/generated/l10n/app_localizations.dart
    - lib/generated/l10n/app_localizations_en.dart
    - lib/generated/l10n/app_localizations_pt.dart
    - test/widget_test.dart
  created:
    - test/presentation/finance/recurring_payment_visibility_test.dart
commits:
  - ebf71ff  # wip: carries task 1 (see deviation 1)
  - c5594ec  # feat(03-11): make a paused recurring payment look paused (CR-02)
  - 915ef27  # test(03-11): prove a paused recurring payment stays visible and resumable
gates:
  architecture_guard: "exit 0"
  analyze: "exit 0, 65 infos, 0 lines_longer_than_80_chars"
  tests: "295/295 passing (289 baseline + 6)"
---

# 03-11: Stop a paused recurring payment from disappearing

Closes **CR-02** (Critical) from `03-REVIEW.md`.

## What was wrong

`recurring_payment_screen.dart` wires each card's `SwitchListTile` to
`updatePayment(payment.copyWith(isActive: !payment.isActive))`. The only
query behind that screen was `RecurringPaymentDao.findAll()`, filtered
`.isActiveEqualTo(true).and().deletedAtIsNull().limit(500)`.

So pausing a subscription removed it from the one list that renders it —
and the toggle that would switch it back is only drawn for rows that query
still returns. The payment vanished with no screen anywhere able to bring
it back. `RecurringPaymentCubit.softDelete` has no caller at all, so this
toggle was the app's only reachable delete, and an undocumented and
unrecoverable one.

## What changed

**The list query stopped conflating "paused" with "deleted."** `findAll()`
drops `.isActiveEqualTo(true)` and keeps `.deletedAtIsNull()` — `deletedAt`
is the delete flag, `isActive` is a pause flag, and the DAO's class doc now
says so. It also gained `sortByIsActiveDesc().thenByNextDueDate()` before
its `.limit(500)`, carrying 03-09's lesson that an unsorted cap selects in
id order: without the sort the cap could evict an active payment in favour
of a paused one.

**`getActivePayments` was renamed to `getPayments`** through the domain
interface, the impl, the cubit and the `test/widget_test.dart` stub. A name
promising "active" while returning paused rows is exactly how an aggregate
silently starts counting the wrong thing. The rename forces every call site
through a compile error. Verified afterwards by grep: exactly one consumer
exists (`recurring_payment_cubit.dart:65`), so nothing silently changed
meaning and no `findActive()` companion was needed — the plan's contingency
for that case did not fire.

**A paused row now reads as paused.** The card wraps its `ListTile` in
`Opacity(0.55)` and swaps `Icons.repeat` for `Icons.pause_circle_outline`.
The `SwitchListTile` is deliberately left **outside** that `Opacity` and at
full strength: it is the only control anywhere that can resume the payment,
so dimming it along with the row would make the recovery path look
disabled. That reasoning is now a convention in the slice README.

**The toggle label went through `AppLocalizations`.** It was
`payment.isActive ? 'Ativo' : 'Pausado'` — hardcoded PT-BR that stayed
Portuguese under the `en` locale. `recurringActive` / `recurringPaused`
were added to all three ARB files and `flutter gen-l10n` re-run. All three
files hold 459 keys, checked by parsing them as JSON rather than by eye.

## Verification

Each gate command run unpiped, on the committed tree:

| Gate | Result |
|---|---|
| `dart run tool/check_architecture.dart` | exit 0 |
| `flutter analyze --no-fatal-infos --fatal-warnings` | exit 0, **65 infos** (budget held) |
| `flutter analyze --no-fatal-infos \| grep -c lines_longer_than_80_chars` | **0** |
| `flutter test --no-pub` | exit 0, **295/295** (289 baseline + 6 new) |

`recurring_payment_card.dart` 86 → 95 lines, `recurring_payment_screen.dart`
95 → 98, `recurring_payment_state.dart` 41 → 43. All well under the 150 cap;
three README line counts updated.

### Test strategy, and its honest limit

This project still has no infrastructure for opening a real Isar instance in
a test, so the fix is pinned at the two levels CR-04's suite established:

1. **DAO query shape, asserted from source** — the read-the-real-file
   pattern already used by `transaction_dao_ordering_test.dart` and
   `l10n_test.dart`. Three tests: no `isActiveEqualTo`, `deletedAtIsNull()`
   still present, sort before cap.
2. **The screen, against a mocked cubit** — three tests: a paused payment is
   listed, dimmed and labelled; an active one is neither; the toggle asks
   for `isActive: true`.

Level 2 cannot see the DAO — a mocked cubit emits state directly — so
level 1 is what actually carries the mutation check for the query. This is
weaker than a behavioural test against real Isar and is called out here for
the same reason 03-09 called it out: a source-text assertion pins the code
as written, not the behaviour as executed.

### Mutation checks — both actually run, red observed

**A. Restored `.isActiveEqualTo(true).and()` to `findAll()`:**

```
CR-02 · DAO query shape findAll() does not filter on isActive [E]
  Expected: false
    Actual: <true>
```

**B. Pinned the card at `opacity: 1` and its label at `recurringActive`:**

```
a paused payment stays visible and reads as paused [E]
  Expected: exactly one matching candidate
    Actual: _TextWidgetFinder:<Found 0 widgets with text "Paused": []>
```

Both reverted. See deviation 2 for what the second revert cost.

## Deviations from plan

**1. Task 1 arrived in a WIP commit, not from its own executor.** The
executor that ran Task 1 was stopped by a `/gsd-pause-work` request seconds
before it ran its own gate, leaving six modified files and no SUMMARY. The
orchestrator gated that partial tree by hand (green) and committed it as
`ebf71ff` rather than discarding it. Resuming, its diff was read before any
new work — the `getActivePayments` → `getPayments` rename had already
propagated through five files and redoing it would have fought a completed
change.

**2. `git checkout --` silently reverted more than the mutation.** Undoing
mutation B with `git checkout -- <card>` reset the file to commit `c5594ec`
— which predates the test key added *after* that commit — so the revert
also deleted the `Key('recurring-dim-…')` the new tests depend on. Caught by
grepping the file rather than trusting the checkout. **Reverting a mutation
with `git checkout` only restores the last commit, not the working state**;
when uncommitted work sits on top of the mutated line, the mutation has to
be undone by hand.

**3. The card carried a duplicate of a label the README claimed was
shared.** `recurring_payment_card.dart` defined a private `_cycleLabel`
switch that was a verbatim copy of the `cycleLabel()` already exported by
`recurring_payment_schedule_fields.dart:80` — while the slice README
asserted the two shared one label "so the list and the form can never
disagree". They could. The card now imports the shared one; the README's
stated convention is true rather than aspirational. Removing the duplicate
also freed the eight lines the paused styling needed.

**4. Two stale doc comments corrected outside the plan's file list.**
`RecurringPaymentLoaded.payments` still read "Active (isActive=true,
non-deleted)" and `RecurringPaymentScreen`'s class doc still said "the list
of active recurring payments". Both described the pre-fix behaviour, and a
doc comment that contradicts the code it sits on is how CR-02 gets
reintroduced.

**5. An `Opacity` needed a key for the test to read it.** `find.byType(Opacity)`
inside a `Card` matched several widgets — Material builds its own — and threw
`Bad state: Too many elements`. The card's `Opacity` now carries
`Key('recurring-dim-${payment.id}')`, with a comment saying why.

## Known stubs

None.

## Deferred

Logged to `deferred-items.md`:

- `cycleLabel()` returns hardcoded PT-BR (`'Diário'`, `'Mensal'`, …) and the
  card's subtitle hardcodes the `'Próximo:'` prefix. Same defect class as
  the toggle label this plan fixed, but wider — six cycle keys plus a prefix
  across three ARB files, affecting the recurring *form* as well as the list
  card. Localizing the toggle was in scope; localizing the cycle vocabulary
  is its own task.

## Self-Check: PASSED

All commit hashes resolve in `git log`. `grep isActiveEqualTo` returns
nothing in the DAO. `grep -rn getActivePayments lib/ test/` returns two
hits, both doc comments recording the rename (`recurring_payment_repository.dart:21`
and `application/finance/recurring/README.md:32`) — **no call site
survives**. `grep -c mockito` on the new test file returns 0.

## Carried forward

Wave 3 has one plan left — **03-12** (CR-03 + WR-07). Its new test baseline
is **295**, not 289. The analyze budget is unchanged at 65 and the long-line
count is still 0.

Still true of every fix in this phase: **none has run on hardware.** The
mutation checks are strong, but a mutation check is not a device pass.
