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
import 'package:agenda/domain/notifications/planning/stale_alert_keys.dart';
import 'package:agenda/domain/notifications/rules/notification_id.dart';
import 'package:agenda/infrastructure/notifications/sync/immediate_alert_dispatcher.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Raises the 80% and 100% budget alerts when spending or a limit changes
/// (D-05), once per category per threshold per calendar month.
///
/// Markers are written before dispatching, so a crash cannot repeat an alert.
/// While the kind is off nothing is dispatched and no marker is written, so
/// enabling it later still yields the alert (T-04-14-03).
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

  /// Prunes stale markers, seeds the month silently, then subscribes to
  /// transaction and budget changes (debounced, single-flight).
  Future<void> start({DateTime? now}) async {
    if (_started) return;
    _started = true;
    final at = now ?? DateTime.now();
    try {
      await _alerts.removeWhere((key) => isStaleAlertKey(key, at));
      await _seedIfNeeded(at);
    } on Object {
      // Seeding is best effort: alerts must still follow later changes.
    }
    _subscriptions.addAll([
      for (final source in [
        _transactions.watchChanges(),
        _budgets.watchChanges(),
      ])
        source.listen((_) => _flight.request(), onError: (Object _) {}),
    ]);
  }

  /// Forgets every budget marker and seeds the month again, silently, so
  /// imported overspend raises no alert storm (T-04-14-02).
  Future<void> reseedAfterImport({DateTime? now}) async {
    await _alerts.removeWhere(
      (key) => key.startsWith('b:') || key.startsWith('seeded:'),
    );
    await _seedIfNeeded(now ?? DateTime.now());
  }

  /// Marks every threshold already crossed this month without dispatching.
  /// Skipped while the kind is off or once the month is seeded.
  Future<void> _seedIfNeeded(DateTime at) async {
    if (!_enabled) return;
    final seeded = budgetSeededKey(at.year, at.month);
    if (await _alerts.contains(seeded)) return;
    final month = await _loadMonth(at);
    if (month == null) return;
    await _alerts.addAll({
      ...crossedBudgetKeys(month, at.year, at.month),
      seeded,
    });
  }

  /// Evaluates the current month and dispatches any newly crossed threshold.
  Future<void> evaluate({DateTime? now}) async {
    if (!_enabled) return;
    final at = now ?? DateTime.now();
    final month = await _loadMonth(at);
    if (month == null) return;
    final keys = await _alerts.keys();
    for (final MapEntry(key: categoryId, value: threshold)
        in crossedThresholds(month).entries) {
      final name = month.names[categoryId];
      if (name == null || categoryId < 0) continue;
      if (categoryId > maxNotificationEntityId) continue;
      final fresh = newBudgetKeys(
        existing: keys,
        year: at.year,
        month: at.month,
        categoryId: categoryId,
        threshold: threshold,
      );
      if (fresh.isEmpty) continue;
      await _alerts.addAll(fresh);
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
    await Future.wait([for (final s in _subscriptions) s.cancel()]);
    _subscriptions.clear();
  }
}
