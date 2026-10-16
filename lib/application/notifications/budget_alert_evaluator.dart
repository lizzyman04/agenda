import 'dart:async';

import 'package:agenda/application/notifications/budget_month.dart';
import 'package:agenda/application/notifications/debounced_single_flight.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/domain/finance/budget/budget_repository.dart';
import 'package:agenda/domain/finance/category/transaction_category_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:agenda/domain/notifications/alert_state_store.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/notification_prefs_repository.dart';
import 'package:agenda/domain/notifications/planning/budget_threshold.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';
import 'package:agenda/infrastructure/notifications/sync/immediate_alert_dispatcher.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Raises the 80% and 100% budget alerts when spending or a limit changes
/// (D-05).
///
/// Alerts follow changes: nothing runs on a schedule and nothing is
/// evaluated at start. Each category fires each threshold at most once per
/// calendar month; the fired markers live in the [AlertStateStore], and are
/// written before the alert is dispatched so a crash cannot repeat it. A
/// jump straight past 100% raises only the 100% alert and marks 80% too.
/// While the kind is switched off nothing is dispatched and no marker is
/// written, so enabling it later still yields the alert (T-04-14-03).
@lazySingleton
class BudgetAlertEvaluator {
  BudgetAlertEvaluator(
    this._transactions,
    this._budgets,
    this._categories,
    this._alerts,
    this._dispatcher,
    this._prefs,
    this._store,
  );

  /// Quiet period after the last change before an evaluation starts.
  @visibleForTesting
  static Duration debounceDuration = const Duration(milliseconds: 300);

  final TransactionRepository _transactions;
  final BudgetRepository _budgets;
  final TransactionCategoryRepository _categories;
  final AlertStateStore _alerts;
  final ImmediateAlertDispatcher _dispatcher;
  final NotificationPrefsRepository _prefs;
  final SharedPreferences _store;

  late final DebouncedSingleFlight _flight = DebouncedSingleFlight(
    evaluate,
    () => debounceDuration,
  );
  final List<StreamSubscription<void>> _subscriptions = [];
  bool _started = false;

  bool get _enabled => _prefs.load().isEnabled(NotificationKind.budgetAlert);

  /// Subscribes to transaction and budget changes (debounced, single-flight).
  Future<void> start() async {
    if (_started) return;
    _started = true;
    for (final source in [
      _transactions.watchChanges(),
      _budgets.watchChanges(),
    ]) {
      _subscriptions.add(
        source.listen((_) => _flight.request(), onError: (Object _) {}),
      );
    }
  }

  /// Evaluates the current month and dispatches any newly crossed threshold.
  Future<void> evaluate({DateTime? now}) async {
    if (!_enabled) return;
    final at = now ?? DateTime.now();
    final month = await _loadMonth(at);
    if (month == null) return;
    final keys = await _alerts.keys();
    for (final MapEntry(key: categoryId, value: line) in month.spend.entries) {
      final name = month.names[categoryId];
      if (name == null || categoryId < 0) continue;
      if (categoryId > maxNotificationEntityId) continue;
      final threshold = crossedBudgetThreshold(
        spentCents: line.spentCents,
        limitCents: line.limitCents,
      );
      if (threshold == null) continue;
      final k80 = budgetAlertKey(at.year, at.month, categoryId, 80);
      final k100 = budgetAlertKey(at.year, at.month, categoryId, 100);
      if (threshold == 100) {
        if (keys.contains(k100)) continue;
        await _alerts.addAll([k100, k80]);
      } else {
        if (keys.contains(k80) || keys.contains(k100)) continue;
        await _alerts.add(k80);
      }
      final alert = plannedBudgetAlert(
        categoryId: categoryId,
        name: name,
        threshold: threshold,
        at: at,
      );
      await _dispatcher.dispatch(alert, now: at);
    }
  }

  Future<BudgetMonth?> _loadMonth(DateTime at) => loadBudgetMonth(
    transactions: _transactions,
    budgets: _budgets,
    categories: _categories,
    month: at.month,
    year: at.year,
    english: _store.getString(StorageKeys.locale) == 'en',
  );

  /// Stops listening. Safe to call more than once.
  Future<void> dispose() async {
    _flight.dispose();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }
}
