import 'dart:async';

import 'package:agenda/domain/finance/debt/debt_repository.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:agenda/domain/notifications/notification_prefs_repository.dart';
import 'package:agenda/domain/notifications/notification_reconciler.dart';
import 'package:agenda/domain/tasks/item_repository.dart';
import 'package:agenda/infrastructure/notifications/sync/reconcile_runner.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Keeps the OS schedule equal to the planner's desired set.
///
/// Listens to every source the planners read (items, debts, goals,
/// transactions, recurring payments and the preferences), debounces bursts
/// and runs the [ReconcileRunner] single-flight: at most one run executes
/// and at most one more waits behind it (T-04-12-04). No error ever
/// escapes; a failed run simply leaves the schedule as it was.
@LazySingleton(as: NotificationReconciler)
class NotificationSyncCoordinator implements NotificationReconciler {
  NotificationSyncCoordinator(
    this._runner,
    this._items,
    this._debts,
    this._goals,
    this._transactions,
    this._payments,
    this._prefs,
  );

  /// Quiet period after the last request before a run starts.
  @visibleForTesting
  static Duration debounceDuration = const Duration(milliseconds: 400);

  final ReconcileRunner _runner;
  final ItemRepository _items;
  final DebtRepository _debts;
  final GoalRepository _goals;
  final TransactionRepository _transactions;
  final RecurringPaymentRepository _payments;
  final NotificationPrefsRepository _prefs;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  final StreamController<int> _truncated = StreamController<int>.broadcast();
  Timer? _timer;
  Future<void>? _active;
  Future<void>? _queued;
  ReconcileReason _latest = ReconcileReason.dataChange;
  bool _started = false;
  bool _disposed = false;

  @override
  Stream<int> get truncatedCount => _truncated.stream;

  @override
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    for (final source in [
      _items.watchChanges(),
      _debts.watchChanges(),
      _goals.watchChanges(),
      _transactions.watchChanges(),
      _payments.watchChanges(),
    ]) {
      _listen(source, ReconcileReason.dataChange);
    }
    _listen(_prefs.watch(), ReconcileReason.prefsChange);
    await reconcileNow(ReconcileReason.appStart);
  }

  void _listen(Stream<Object?> source, ReconcileReason reason) {
    _subscriptions.add(
      source.listen((_) => requestReconcile(reason), onError: (Object _) {}),
    );
  }

  @override
  void requestReconcile(ReconcileReason reason) {
    if (_disposed) return;
    _latest = reason;
    _timer?.cancel();
    _timer = Timer(debounceDuration, () => unawaited(_enqueue(_latest)));
  }

  @override
  Future<void> reconcileNow(ReconcileReason reason) {
    if (_disposed) return Future.value();
    _timer?.cancel();
    return _enqueue(reason);
  }

  /// Starts a run now, or queues exactly one behind the running one.
  Future<void> _enqueue(ReconcileReason reason) {
    _latest = reason;
    final active = _active;
    if (active == null) return _start();
    return _queued ??= active.then((_) {
      _queued = null;
      return _start();
    });
  }

  Future<void> _start() {
    if (_disposed) return Future.value();
    final run = _execute();
    _active = run;
    return run.whenComplete(() {
      if (identical(_active, run)) _active = null;
    });
  }

  Future<void> _execute() async {
    try {
      final report = await _runner.run(
        now: DateTime.now(),
        reason: _latest,
      );
      if (!report.aborted && !_truncated.isClosed) {
        _truncated.add(report.truncated);
      }
    } on Object catch (error) {
      debugPrint('Notification reconcile failed (${error.runtimeType})');
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _timer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _truncated.close();
  }
}
