---
phase: 03-finance-core
reviewed: 2026-08-14T16:59:51Z
depth: standard
files_reviewed: 73
files_reviewed_list:
  - lib/app.dart
  - lib/application/finance/budget/budget_cubit.dart
  - lib/application/finance/budget/budget_state.dart
  - lib/application/finance/dashboard/home_dashboard_cubit.dart
  - lib/application/finance/dashboard/home_dashboard_state.dart
  - lib/application/finance/debt/debt_cubit.dart
  - lib/application/finance/debt/debt_state.dart
  - lib/application/finance/goal/goal_cubit.dart
  - lib/application/finance/goal/goal_list_cubit.dart
  - lib/application/finance/goal/goal_list_state.dart
  - lib/application/finance/goal/goal_state.dart
  - lib/application/finance/recurring/recurring_payment_cubit.dart
  - lib/application/finance/recurring/recurring_payment_state.dart
  - lib/application/finance/transaction/README.md
  - lib/application/finance/transaction/transaction_cubit.dart
  - lib/application/finance/transaction/transaction_state.dart
  - lib/config/di/finance_module.dart
  - lib/config/di/injection.config.dart
  - lib/config/l10n/app_en.arb
  - lib/config/l10n/app_pt.arb
  - lib/config/l10n/app_pt_BR.arb
  - lib/core/config/app_config.dart
  - lib/core/constants/currencies.dart
  - lib/core/constants/finance_colors.dart
  - lib/core/utils/amount_formatter.dart
  - lib/data/database/migration_runner.dart
  - lib/generated/l10n/app_localizations.dart
  - lib/generated/l10n/app_localizations_en.dart
  - lib/generated/l10n/app_localizations_pt.dart
  - lib/infrastructure/finance/budget_repository_impl.dart
  - lib/infrastructure/finance/debt_repository_impl.dart
  - lib/infrastructure/finance/goal_repository_impl.dart
  - lib/infrastructure/finance/recurring_payment_repository_impl.dart
  - lib/infrastructure/finance/transaction_category_repository_impl.dart
  - lib/infrastructure/finance/transaction_repository_impl.dart
  - lib/main.dart
  - lib/presentation/finance/screens/budget_overview_screen.dart
  - lib/presentation/finance/screens/debt_form_screen.dart
  - lib/presentation/finance/screens/debt_list_screen.dart
  - lib/presentation/finance/screens/finance_dashboard_screen.dart
  - lib/presentation/finance/screens/README.md
  - lib/presentation/finance/screens/recurring_payment_form_screen.dart
  - lib/presentation/finance/screens/recurring_payment_screen.dart
  - lib/presentation/finance/screens/transaction_form_screen.dart
  - lib/presentation/finance/screens/transaction_list_screen.dart
  - lib/presentation/finance/widgets/budget_progress_bar.dart
  - lib/presentation/finance/widgets/dashboard_summary_card.dart
  - lib/presentation/finance/widgets/finance_empty_state.dart
  - lib/presentation/finance/widgets/README.md
  - lib/presentation/finance/widgets/spending_bar_chart.dart
  - lib/presentation/finance/widgets/spending_pie_chart.dart
  - lib/presentation/finance/widgets/transaction_card.dart
  - lib/presentation/tasks/screens/task_detail_screen.dart
  - lib/presentation/tasks/widgets/detail/README.md
  - lib/presentation/tasks/widgets/detail/task_detail_finance_chip.dart
  - test/application/finance/budget_cubit_test.dart
  - test/application/finance/debt_cubit_test.dart
  - test/application/finance/goal_cubit_test.dart
  - test/application/finance/home_dashboard_cubit_test.dart
  - test/application/finance/transaction_cubit_test.dart
  - test/core/utils/amount_formatter_test.dart
  - test/data/database/migration_runner_test.dart
  - test/data/finance/savings_goal_mapper_test.dart
  - test/data/finance/transaction_mapper_test.dart
  - test/domain/finance/savings_goal_test.dart
  - test/domain/finance/transaction_test.dart
  - test/presentation/finance/finance_empty_state_test.dart
  - test/presentation/finance/spending_pie_chart_test.dart
  - test/presentation/finance/transaction_card_test.dart
  - test/presentation/finance/transaction_list_screen_test.dart
  - test/presentation/finance/transaction_list_undo_test.dart
  - test/presentation/tasks/task_detail_screen_test.dart
  - test/presentation/undo_snackbar_auto_dismiss_test.dart
findings:
  critical: 4
  warning: 11
  info: 3
  total: 18
status: issues_found
---

# Phase 3: Code Review Report

**Reviewed:** 2026-08-14T16:59:51Z
**Depth:** standard
**Files Reviewed:** 73
**Status:** issues_found

## Summary

The three UAT defects this phase closed (undo SnackBar queueing, undo auto-dismiss,
category-name resolution) are genuinely fixed and regression-tested, and the
`TransactionLoaded.categories` addition is correct — `props` covers it, and every
sibling finance state's `props` covers every field it renders. Cubit `close()`
overrides cancel their subscriptions, `isClosed` guards bracket the awaits in five of
six list cubits, and the `clearField` sentinel in `Transaction.copyWith` makes
`restoreTransaction`'s `deletedAt: null` actually clear the tombstone.

The defects are concentrated in three places the fixed defects did not touch:

1. **Recovery paths that only exist for transactions.** Debts are swipe-deleted with
   no confirm, no SnackBar, no undo and no `restoreDebt` anywhere in the code base
   (CR-01). Recurring payments have a toggle that hides them from the only screen
   that lists them, permanently (CR-02). Task-detail undo calls `context.read` on a
   route that has already been popped (CR-03).
2. **A silent 500-row ceiling** on every transaction query, with no ordering, which
   caps the list *and* every derived figure: balance, net worth, category charts, goal
   progress (CR-04).
3. **`start()` lifecycle**, which is idempotent in `HomeDashboardCubit` and in none of
   the other four watch-backed cubits (WR-01), so every tab revisit leaks a live Isar
   subscription onto an app-scoped cubit.

Findings marked *(dependency)* live in a file outside the submitted list but are
reachable only through, and caused only by, a file in it; they are cited because
dropping them would leave the reviewed file's behaviour misdescribed.

## Critical Issues

### CR-01: Deleting a debt is unrecoverable — no confirm, no undo, no restore path

**File:** `lib/presentation/finance/screens/debt_list_screen.dart:73-74`
(with `lib/application/finance/debt/debt_cubit.dart:63-69` and
`lib/presentation/finance/widgets/debt/debt_card.dart:44,49` *(dependency)*)

**Issue:** `DebtCard` is a `Dismissible` with `onDismissed: (_) => onDelete()` and no
`confirmDismiss`; the list wires that straight to
`ctx.read<DebtCubit>().softDelete(debt.id)`. There is no confirmation dialog, no
SnackBar, and `DebtCubit` exposes no restore method — `grep -rn "restore" lib/` finds
restore only for transactions and tasks. Failure path: the user scrolls the Dívidas
tab, a horizontal drag lands on a card, the debt disappears, and the row (title,
amount, counterparty, due date, paid history) is gone for good. The row is only
soft-deleted in Isar, so the data is still on disk and unreachable from any screen —
which is worse than a hard delete, because nothing tells the user it is recoverable.
Compare `transaction_list_screen.dart:43-69`, which gets this right.

**Fix:** Mirror the transaction pattern — add `restoreDebt` to `DebtCubit` (the
`Debt.copyWith` sentinel already supports `deletedAt: null`) and show the undo
SnackBar from the list:

```dart
// debt_cubit.dart
Future<void> restoreDebt(int id) async {
  final getResult = await _repository.getDebt(id);
  if (getResult is! Success<Debt>) return;
  final restored = getResult.value.copyWith(
    deletedAt: null,
    updatedAt: DateTime.now(),
  );
  final result = await _repository.updateDebt(restored);
  if (result is Err<Debt>) emit(DebtError(result.failure));
}

// debt_list_screen.dart
void _handleDelete(BuildContext context, Debt debt) {
  final cubit = context.read<DebtCubit>();
  final messenger = ScaffoldMessenger.of(context);
  cubit.softDelete(debt.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context).debtDeleted),
      duration: AppConstants.undoSnackbarDuration,
      persist: false,
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: AppLocalizations.of(context).undo,
        onPressed: () => cubit.restoreDebt(debt.id),
      ),
    ));
}
```

### CR-02: The recurring-payment "active" switch is a one-way trap

**File:** `lib/presentation/finance/screens/recurring_payment_screen.dart:73-76`
(with `lib/data/finance/recurring/recurring_payment_dao.dart:22-29` *(dependency)*
and `lib/infrastructure/finance/recurring_payment_repository_impl.dart:66-73`)

**Issue:** The card's toggle calls
`updatePayment(payment.copyWith(isActive: !payment.isActive))`. The only query behind
this screen is `RecurringPaymentDao.findAll()`, which filters
`.isActiveEqualTo(true)`. So flipping the switch off writes `isActive = false`, the
reload drops the row, and there is no "show inactive" filter, no archive screen and no
other caller of `getActivePayments`. Failure path: the user pauses a subscription for
one month; the row vanishes and can never be turned back on, because the toggle that
would re-activate it is only rendered for rows the query no longer returns. The record
is stranded in Isar exactly like CR-01.

Related dead code in the same feature: `RecurringPaymentCubit.softDelete`
(`recurring_payment_cubit.dart:47-54`) has no caller in `lib/presentation/` — the
list has no delete affordance at all, so the toggle is the de-facto delete.

**Fix:** Either query all non-deleted payments and render inactive rows in a muted
state (so the toggle stays reversible), or drop the toggle from the list and expose
`isActive` only inside `RecurringPaymentFormScreen`, which can still be reached for an
inactive payment. Minimum change:

```dart
// recurring_payment_dao.dart — return everything not soft-deleted
Future<List<RecurringPaymentModel>> findAll() async =>
    _collection.filter().deletedAtIsNull().limit(500).findAll();
```
and let the screen sort/dim by `isActive`. Also wire `softDelete` to a swipe (with
undo, per CR-01) or delete the unused method.

### CR-03: Task-detail undo reads a provider from a popped route — restore never runs

**File:** `lib/presentation/tasks/screens/task_detail_screen.dart:41-57`

**Issue:** `_confirmDelete` pops the route at line 42 and then hands the SnackBar an
action closure that calls `context.read<TaskListCubit>()` at line 55 — `context` is
the `TaskDetailScreen` element, which is unmounted as soon as the pop transition ends
(~300 ms), long before the 5 s undo window expires. When the user taps "Desfazer",
`context.read` performs an ancestor lookup on a defunct element: in debug/profile that
trips `_debugCheckStateIsActiveForAncestorLookup` and throws
*"Looking up a deactivated widget's ancestor is unsafe"*, so `restoreItem` is never
called and the task stays soft-deleted with no other recovery UI. In release it
survives only by reading a defunct element's retained inherited map — undefined
behaviour, not a guarantee. `ScaffoldMessenger.of(context)` on line 43 is the same
anti-pattern; it happens to work only because it executes synchronously in the same
frame as the pop.

The existing tests miss this: `undo_snackbar_auto_dismiss_test.dart:196-211` and
`task_detail_screen_test.dart:194-209` both let the SnackBar expire without ever
tapping Undo. `transaction_list_screen.dart:44-45` shows the correct pattern
(capture `cubit` and `messenger` before the navigation).

**Fix:**

```dart
if (confirmed == true && context.mounted) {
  final cubit = context.read<TaskListCubit>();
  final messenger = ScaffoldMessenger.of(context);
  unawaited(cubit.softDelete(item.id));
  Navigator.of(context).pop();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      duration: AppConstants.undoSnackbarDuration,
      persist: false,
      behavior: SnackBarBehavior.floating,
      content: Text(l10n.taskDeleted),
      action: SnackBarAction(
        label: l10n.undo,
        onPressed: () => unawaited(cubit.restoreItem(item.id)),
      ),
    ));
}
```
Add a regression test that taps `l10n.undo` after the pop and verifies
`restoreItem` is called.

### CR-04: 500-row cap with no ordering silently truncates the list and every money total

**File:** `lib/data/finance/transaction/transaction_dao.dart:22-26` *(dependency)*,
consumed by `lib/infrastructure/finance/transaction_repository_impl.dart:63-70` and
`lib/application/finance/dashboard/home_dashboard_cubit.dart:68,80,95,117`

**Issue:** `findAll()` is `.filter().deletedAtIsNull().limit(500).findAll()` — no
`sortBy`, so Isar returns rows in id (insertion) order and the cap keeps the **oldest**
500. Every consumer of `getTransactions()` inherits it:
`computeBalance` (D-07 balance), `computeTaggedByGoal` → `computeGoalsSavedTotal` →
`computeNetWorth` (D-08 net worth), `computeCategorySpend` (D-09 charts) and the
Transações list itself. Failure path: a user who records ~2 transactions a day crosses
500 rows in under a year; from that moment every new transaction is invisible in the
list and contributes nothing to the balance, so the headline figure on the Resumo tab
is simply wrong and drifts further every day, with no warning, no pagination and no
"showing 500 of N" hint. `findByMonth` and `findByLinkedGoal` carry the same cap, so a
heavy month or a heavily-tagged goal is under-counted the same way.

Secondary defect from the same missing `sortBy`: the list renders oldest-first, so a
newly added transaction appears at the very bottom.

**Fix:** Sort descending by date and either drop the cap for aggregate queries or
aggregate in Isar. Minimum viable change:

```dart
/// Returns active transactions, newest first.
Future<List<TransactionModel>> findAll() async => _collection
    .filter()
    .deletedAtIsNull()
    .sortByDateDesc()
    .findAll();
```
If a cap must stay for the *list*, give the dashboard its own uncapped aggregate query
(or `.sum()` / `.count()` on the Isar side) so balance and net worth are never computed
from a truncated set.

## Warnings

### WR-01: `start()` is not idempotent — a leaked watch subscription per tab revisit

**File:** `lib/application/finance/transaction/transaction_cubit.dart:45-48`,
`lib/application/finance/budget/budget_cubit.dart:38-41`,
`lib/application/finance/debt/debt_cubit.dart:25-28`,
`lib/application/finance/goal/goal_list_cubit.dart:25-28`

**Issue:** All four cubits are provided **above** `MaterialApp` (`app.dart:34-49`), so
one instance lives for the whole app session. Their screens are `TabBarView` children
of `FinanceDashboardScreen` (`finance_dashboard_screen.dart:43-51`); `TabBarView`
disposes non-adjacent pages, so returning to a tab re-runs `initState` →
`context.read<XCubit>().start()` (e.g. `transaction_list_screen.dart:30`). Each call
overwrites `_watchSubscription` **without cancelling the previous one**, so after k
visits there are k live `watchLazy()` listeners on the same cubit. Every subsequent
write then fires k concurrent `_reload()` calls; the emits race, so the state that
lands last is not necessarily the newest query result, and `close()` cancels only the
most recent subscription. `HomeDashboardCubit.start()` (lines 45-54) already has the
correct guard — the other four were not updated to match.

**Fix:** Apply the `HomeDashboardCubit` guard to each:

```dart
Future<void> start() async {
  if (_watchSubscription != null) {
    await _reload();
    return;
  }
  _watchSubscription = _repository.watchChanges().listen((_) async => _reload());
  await _reload();
}
```

### WR-02: `GoalCubit` emits after every await with no `isClosed` guard

**File:** `lib/application/finance/goal/goal_cubit.dart:29-41`, `93-105`
(provider that closes it: `lib/presentation/finance/goals/screens/goal_detail_screen.dart:26`
*(dependency)*)

**Issue:** `GoalDetailScreen` creates the cubit inside a `BlocProvider` and kicks off
`loadGoal(goalId)` fire-and-forget; `BlocProvider` closes the cubit when the route is
popped. `loadGoal` emits at lines 30, 35 and (via `_refreshGoal`) 98/104 after awaiting
two repository calls, with no `isClosed` check anywhere in the file — every other
finance cubit guards this. Failure path: open a goal, press back before the two Isar
queries return; `emit` on a closed cubit throws
`StateError: Cannot emit new states after calling close`, and because the call chain is
unawaited it surfaces as an unhandled async error. The same window exists for
`addContribution` and `updateGoal`.

**Fix:** Guard every emit boundary, matching `transaction_cubit.dart:108-121`:

```dart
Future<void> _refreshGoal(SavingsGoal goal) async {
  if (isClosed) return;
  final txResult = await _transactionRepository.getByLinkedGoal(goal.id);
  if (isClosed) return;
  ...
}
```
(and the equivalent `if (isClosed) return;` after the awaits in `loadGoal`,
`addContribution`, `updateGoal`, `createGoal`, `softDeleteGoal`).

### WR-03: Forms report success regardless of whether the write succeeded

**File:** `lib/presentation/finance/widgets/transaction/transaction_form_submit.dart:56-58`
*(dependency)*, `lib/presentation/finance/screens/debt_form_screen.dart:92-95`,
`lib/presentation/finance/screens/recurring_payment_form_screen.dart:102-104`

**Issue:** `submitTransactionForm` awaits `cubit.createTransaction(tx)` and then
`return true` unconditionally — the cubit swallows the `Result` and only emits
`TransactionError`. The screen (`transaction_form_screen.dart:114`) reads that `true`
and pops. Failure path: the write returns `Err(DatabaseFailure)`; the form closes as if
saved, and the user lands on the Transações tab which has been replaced wholesale by
`Center(child: Text(failure.message))` — a raw, unlocalised English/internal string
(`'createTransaction failed: ...'`, `transaction_list_screen.dart:81-82`). The debt and
recurring forms pop unconditionally in the same way. Compounding this, every finance
list screen renders its `*Error` state as a terminal dead end: no retry button, and the
list only comes back if some *other* write happens to fire the watch stream.

**Fix:** Return the persistence result and keep the form open on failure:

```dart
final result = isEditing
    ? await cubit.updateTransaction(tx)   // make the cubit return Result<Transaction>
    : await cubit.createTransaction(tx);
if (result is Err) {
  showTransactionFormError(context, l10n.errorSaveFailed);
  return false;
}
return true;
```
and give the error branch of each list screen a retry action that calls
`cubit.reload()`.

### WR-04: Budget empty-state CTA is an inert button

**File:** `lib/presentation/finance/screens/budget_overview_screen.dart:74-80`

**Issue:** When `categories.isEmpty`, the screen renders a `FinanceEmptyState` whose
CTA is labelled `l10n.setBudgetLimit` and wired to `onCta: () {}` with the comment
"No categories yet — inform user". Failure path: the user taps a prominent filled
button and nothing happens at all — no sheet, no message, no navigation. A CTA that
cannot act should not be rendered as a CTA.

**Fix:** Give `FinanceEmptyState` optional CTA parameters and omit the button here, or
point it at something real (e.g. the category-management screen when it exists):

```dart
FinanceEmptyState(
  icon: Icons.donut_large_outlined,
  heading: l10n.emptyBudgets,
  body: l10n.emptyBudgetsNoCategoriesBody, // explains why no action is offered
)
```

### WR-05: Dashboard hides real data behind a zero-balance heuristic

**File:** `lib/presentation/finance/widgets/dashboard/dashboard_tab.dart:66-78`
*(dependency)*

**Issue:** `hasNoData = balanceCents == 0 && netWorthCents == 0 && categorySpend.isEmpty`
is used as a proxy for "the user has never entered anything". Failure path: a user who
logged 5 000,00 of income and 5 000,00 of expenses last month, has no goals or debts,
and has not spent yet this month gets `balance == 0`, `netWorth == 0` and an empty
current-month spend map — so the Resumo tab shows the "add your first transaction"
empty state and hides the summary card and month navigation, with the real (correct)
zero balance nowhere on screen. The user cannot navigate to last month's chart from
there either, because the month header is inside the branch that was skipped.

**Fix:** Derive emptiness from the data set, not from the aggregates — e.g. carry a
`hasAnyTransaction` flag on `HomeDashboardLoaded` (`allTx.isNotEmpty` in
`home_dashboard_cubit.dart:76`) and branch on that.

### WR-06: Charts always render PT-BR category names, ignoring the active locale

**File:** `lib/presentation/finance/widgets/spending_pie_chart.dart:59-64`,
`lib/presentation/finance/widgets/spending_bar_chart.dart:42-51`

**Issue:** Both `_categoryName` and `_shortName` return `c.namePtBr` unconditionally,
even though `TransactionCategory.nameEn` is populated for all 13 seeded categories
(`migration_runner.dart:65-83`) and both widgets already receive `locale`. Failure
path: switch the app to EN; the transaction list correctly shows "Food"
(`resolveCategoryDisplay`, `transaction_list_screen.dart:124-128`) while the pie legend
and bar axis right above it still say "Alimentação" — a direct violation of the
EN-toggle requirement in CLAUDE.md and an internal inconsistency on one screen.

**Fix:** Reuse the existing helper instead of duplicating the lookup:

```dart
String _categoryName(int categoryId) => resolveCategoryDisplay(
      categories.where((c) => c.id == categoryId).firstOrNull,
      preferEnglish: locale.languageCode == 'en',
      fallback: '#$categoryId',
    );
```

### WR-07: Budget sheet re-implements the amount parser instead of calling the shared one

**File:** `lib/presentation/finance/widgets/budget/budget_limit_sheet.dart:51-58`
*(dependency)*

**Issue:** `_submit` inlines
`replaceAll(',', '.')` → `replaceAll(RegExp(r'[^\d.]'), '')` → `double.tryParse` →
`* 100).round()` — a byte-for-byte copy of `parseAmountCentsOrNull`
(`lib/core/utils/amount_parser.dart`), which exists precisely to be the single home for
that expression. This is a *new* fifth copy of the known thousands-separator /
leading-minus bug, in a file the dedup pass missed, so any fix to `amount_parser.dart`
will silently not reach budget limits. Failure path today: typing `1.250,00` as a
monthly limit yields `1.250.00` → `double.tryParse` null → `Navigator.pop(null)` → the
sheet closes and **no limit is saved, with no error shown at all** (`budget_overview_screen.dart:53`
only acts when `limitCents != null`).

**Fix:** Call the shared parser and surface the failure:

```dart
void _submit() => Navigator.of(context).pop(
      parseAmountCentsOrNull(_controller.text),
    );
```
plus a visible validation message in `_openLimitSheet` when the result is `null`.

### WR-08: Money pre-fill uses ad-hoc double arithmetic instead of `formatCentsForInput`

**File:** `lib/presentation/finance/screens/debt_form_screen.dart:38-42`
(also `lib/presentation/finance/goals/screens/goal_form_screen.dart:37-39` and
`lib/presentation/finance/widgets/budget/budget_limit_sheet.dart:38-41` *(dependency)*)

**Issue:** `(debt.amountCents / 100).toStringAsFixed(2).replaceAll('.', ',')` is raw
double arithmetic on money in three files, while
`formatCentsForInput` (`amount_parser.dart`) — already imported into the transaction
and recurring forms — does exactly this. Beyond the duplication, the behaviour differs:
`formatCentsForInput` returns `''` for `cents <= 0`, the inline version returns
`'0,00'`, so an edit form for a zero/invalid amount pre-fills a value that then parses
back to `null` and is rejected. Every money value in this phase is integer cents by
design; each hand-rolled `/ 100` is a place a rounding change can silently
misrepresent a balance.

**Fix:** `final amountStr = debt == null ? '' : formatCentsForInput(debt.amountCents);`
in all three call sites.

### WR-09: Goal form resolves a throw-away `GoalCubit` per save, swallows the failure, and leaves the detail screen stale

**File:** `lib/presentation/finance/goals/screens/goal_form_screen.dart:86-98`
*(dependency)*, against `lib/application/finance/goal/goal_cubit.dart:59-76`

**Issue:** Three problems in twelve lines. (1) `getIt<GoalCubit>()` is a
**factory** registration (`injection.config.dart:171`), so each save builds a brand-new
cubit that is never `close()`d — a leak per save. (2) The create branch wraps the call
in `try { ... } catch (_) { /* fallback: already covered by BlocProvider in parent */ }`
— an empty catch whose comment is wrong (no parent provides a `GoalCubit` on this
route), so a create failure is swallowed and the form still pops as success. (3) In
edit mode the mutation goes through the detached cubit, while `GoalDetailScreen`'s own
`GoalCubit` has no `watchChanges` subscription and nobody re-calls `loadGoal` — so
returning from the edit form shows the **old** title/target until the screen is
rebuilt from scratch.

**Fix:** Provide the cubit for the route (`BlocProvider.value` from the detail screen,
or a `BlocProvider` around `GoalFormScreen`), drop the empty catch, check the result
before popping, and have the detail screen `loadGoal(goalId)` again after the form
route returns.

### WR-10: Hardcoded PT-BR strings in the debt card bypass AppLocalizations

**File:** `lib/presentation/finance/widgets/debt/debt_card.dart:99-101` *(dependency)*

**Issue:** `Text(debt.isPaid ? 'Pago' : 'Pendente')` — literal strings in a widget that
already holds `final l10n = AppLocalizations.of(context)` and uses it two lines above
for `toPay`/`toReceive`. Failure path: with the app in EN, the Dívidas list shows
"To pay" next to "Pendente" on the same card. CLAUDE.md makes localisation of all UI
text a hard requirement, and both ARB files already carry the full key set.

**Fix:** Add `debtPaid`/`debtPending` to `app_en.arb`, `app_pt.arb` and
`app_pt_BR.arb`, regenerate, and use
`Text(debt.isPaid ? l10n.debtPaid : l10n.debtPending)`.

### WR-11: MigrationRunner records a version bump for a migration case that does not exist

**File:** `lib/data/database/migration_runner.dart:31-52`

**Issue:** `_runMigration` is a `switch` with cases 1-3 and no `default`; an
unhandled `toVersion` falls through and returns normally, after which `run` writes that
version to prefs (line 33). Failure path: a future change bumps
`AppConfig.schemaVersion` to 4 but forgets the migration block — the runner records
version 4, the data transformation never happens, and because `run` short-circuits on
`current >= target` it can **never** happen on any later launch either. The failure is
silent and permanent, on the one code path that is supposed to protect user data across
upgrades. `migration_runner_test.dart` does not cover an unknown version.

**Fix:** Fail loudly on an unmapped version:

```dart
static Future<void> _runMigration(Isar isar, int toVersion) async {
  switch (toVersion) {
    case 1:
    case 2:
      return;
    case 3:
      await _seedDefaultCategories(isar);
      return;
    default:
      throw StateError('No migration defined for schema version $toVersion');
  }
}
```
plus a test asserting the throw and that `setInt` is not called for that version.

## Info

### IN-01: `mergeBudgetData`'s backfill loop is unreachable

**File:** `lib/application/finance/budget/budget_aggregator.dart:38-44`

**Issue:** `allCategoryIds` (line 29) is the union of `spentMap.keys` and
`limitMap.keys`, and the loop at 31-36 writes an entry for every id in that union. Every
`budget.categoryId` is already in `limitMap`, so the `combined[...] ??=` at line 40 can
never assign. Dead code whose comment ("Also include categories with limits but no
spend") describes work the previous loop already did — a future reader will assume the
first loop does not cover that case.

**Fix:** Delete lines 38-44.

### IN-02: `restoreTransaction` — the one undo path that touches the DB — has no unit test

**File:** `test/application/finance/transaction_cubit_test.dart:69-175` against
`lib/application/finance/transaction/transaction_cubit.dart:86-104`

**Issue:** The suite covers `start`, `createTransaction` and `softDelete`, but not
`restoreTransaction`. Its correctness rests entirely on the `clearField` sentinel in
`Transaction.copyWith` — if that sentinel were ever refactored into a conventional
`deletedAt ?? this.deletedAt` copyWith, `copyWith(deletedAt: null)` would become a
no-op, undo would silently do nothing, and no test would fail.

**Fix:** Add a `blocTest` stubbing `getTransaction` with a soft-deleted transaction and
asserting the `Transaction` captured by `updateTransaction` has `deletedAt == null`,
plus one asserting the not-found branch emits nothing.

### IN-03: `app_pt.arb` and `app_pt_BR.arb` are identical, with two different roles

**File:** `lib/config/l10n/app_pt.arb`, `lib/config/l10n/app_pt_BR.arb`

**Issue:** Both files carry the same 100+ message keys with byte-identical values
(verified: zero value differences), differing only in `@@locale`. `l10n.yaml` names
`app_pt_BR.arb` as the template. Nothing enforces that the two stay in sync, so a
string added to only one produces a locale where the message silently falls back or
diverges — a maintenance trap that scales with every new key.

**Fix:** Keep `app_pt_BR.arb` as the sole PT template and delete `app_pt.arb` (Flutter
resolves `pt` to the `pt_BR` messages via the delegate's language-code fallback), or add
a CI check asserting the two key/value sets match.

---

_Reviewed: 2026-08-14T16:59:51Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
