import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/debt/debt_repository.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:agenda/domain/notifications/alert_state_store.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/planner_input.dart';
import 'package:agenda/domain/notifications/notification_prefs_repository.dart';
import 'package:agenda/domain/notifications/quotes/quotes_catalog.dart';
import 'package:agenda/domain/notifications/rules/day_math.dart';
import 'package:agenda/domain/tasks/item_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

T _ok<T>(Result<T> result) => (result as Success<T>).value;

/// Reads everything the planners need into one [PlannerInput].
///
/// Reads are uncapped planning reads, never the capped display queries. The
/// first repository failure aborts the load, so the caller can leave the
/// existing schedule alone (T-04-12-01).
@lazySingleton
class SnapshotLoader {
  SnapshotLoader(
    this._items,
    this._debts,
    this._goals,
    this._payments,
    this._transactions,
    this._prefs,
    this._alerts,
    this._store,
  );

  final ItemRepository _items;
  final DebtRepository _debts;
  final GoalRepository _goals;
  final RecurringPaymentRepository _payments;
  final TransactionRepository _transactions;
  final NotificationPrefsRepository _prefs;
  final AlertStateStore _alerts;
  final SharedPreferences _store;

  AsyncResult<PlannerInput> load({
    required DateTime now,
    required int slotBudget,
  }) async {
    final today = startOfDay(now);
    final soonest = await _items.getRemindableItems(
      from: today,
      limit: slotBudget * 2,
    );
    if (soonest case Err(:final failure)) return Err(failure);
    final window = await _items.getItemsDueInWindow(
      from: today,
      toExclusive: addDays(today, AppConstants.plannerHorizonDays),
    );
    if (window case Err(:final failure)) return Err(failure);
    final debts = await _debts.getDebts();
    if (debts case Err(:final failure)) return Err(failure);
    final goals = await _goals.getActiveGoals();
    if (goals case Err(:final failure)) return Err(failure);
    final transactions = await _transactions.getAllTransactionsForAggregates();
    if (transactions case Err(:final failure)) return Err(failure);
    final payments = await _payments.getPayments();
    if (payments case Err(:final failure)) return Err(failure);

    final taggedByGoal = _sumByGoal(_ok(transactions));
    final prefs = _prefs.load();
    final localeCode =
        _store.getString(StorageKeys.locale) == 'en' ? 'en' : 'pt';
    return Success(
      PlannerInput(
        now: now,
        prefs: prefs,
        localeCode: localeCode,
        items: _ok(soonest),
        windowItems: _ok(window),
        debts: _ok(debts),
        goals: [
          for (final goal in _ok(goals))
            GoalProgress(
              goal: goal,
              savedCents: goal.amountSavedCents(taggedByGoal[goal.id] ?? 0),
            ),
        ],
        payments: _ok(payments),
        quotes:
            prefs.isEnabled(NotificationKind.motivationalQuote)
                ? quotesFor(localeCode)
                : const [],
        firedAlertKeys: await _alerts.keys(),
        slotBudget: slotBudget,
      ),
    );
  }

  static Map<int, int> _sumByGoal(List<Transaction> transactions) {
    final sums = <int, int>{};
    for (final tx in transactions) {
      final goalId = tx.linkedGoalId;
      if (goalId == null) continue;
      sums[goalId] = (sums[goalId] ?? 0) + tx.amountCents;
    }
    return sums;
  }
}
