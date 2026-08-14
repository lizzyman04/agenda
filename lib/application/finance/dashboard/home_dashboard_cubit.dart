import 'dart:async';

import 'package:agenda/application/finance/dashboard/dashboard_aggregator.dart';
import 'package:agenda/application/finance/dashboard/home_dashboard_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/category/transaction_category_repository.dart';
import 'package:agenda/domain/finance/debt/debt_repository.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Orchestrates finance dashboard reloads: fetches repository data, then
/// delegates D-07/D-08/D-09 aggregation math to `dashboard_aggregator.dart`.
///
/// Subscribes to TransactionRepository.watchChanges() — reloads when
/// transactions change. No N+1 Isar queries (T-03-03-01).
///
/// Factory (not singleton) — one per home dashboard screen.
@injectable
class HomeDashboardCubit extends Cubit<HomeDashboardState> {
  HomeDashboardCubit(
    this._transactionRepository,
    this._goalRepository,
    this._debtRepository,
    this._categoryRepository,
  ) : super(const HomeDashboardInitial());

  final TransactionRepository _transactionRepository;
  final GoalRepository _goalRepository;
  final DebtRepository _debtRepository;
  final TransactionCategoryRepository _categoryRepository;

  StreamSubscription<void>? _txWatchSub;
  DateTime _selectedMonth = DateTime.now();

  /// Subscribes to transaction changes and loads the initial dashboard data.
  ///
  /// Idempotent — rebuilding the dashboard tab only reloads, it never opens
  /// a second watch subscription that would leak the first.
  Future<void> start() async {
    if (_txWatchSub != null) {
      await _reload();
      return;
    }
    _txWatchSub = _transactionRepository
        .watchChanges()
        .listen((_) async => _reload());
    await _reload();
  }

  /// Switches the chart to [month] and re-computes categorySpend (D-10).
  Future<void> selectMonth(DateTime month) async {
    _selectedMonth = DateTime(month.year, month.month);
    await _reload();
  }

  /// Loads repository data, delegates aggregation to dashboard_aggregator.dart
  /// (D-07/D-08/D-09), then emits [HomeDashboardLoaded].
  Future<void> _reload() async {
    if (isClosed) return;

    // Uncapped on purpose (CR-04). Everything this cubit produces is a
    // TOTAL, never a display list, so it must see every non-deleted row.
    // The capped read (getTransactions) keeps only the newest 500 — summing
    // that yields a silently WRONG balance rather than an obviously missing
    // one, which is exactly how the original defect stayed invisible.
    // Do not "optimise" this back to the capped query.
    final txResult =
        await _transactionRepository.getAllTransactionsForAggregates();
    if (isClosed) return;
    final allTx = _unwrap(txResult);
    if (allTx == null) return;

    final balance = computeBalance(allTx);

    // Active goals; tagged-tx amounts are computed from allTx (no N+1)
    final goalsResult = await _goalRepository.getActiveGoals();
    if (isClosed) return;
    final goals = _unwrap(goalsResult);
    if (goals == null) return;

    final taggedByGoal = computeTaggedByGoal(allTx);
    final goalsSavedTotal = computeGoalsSavedTotal(goals, taggedByGoal);

    final debtsResult = await _debtRepository.getDebts();
    if (isClosed) return;
    final debts = _unwrap(debtsResult);
    if (debts == null) return;

    final debtTotal = computeDebtTotal(debts);
    final netWorth = computeNetWorth(
      balanceCents: balance,
      goalsSavedTotalCents: goalsSavedTotal,
      debtTotalCents: debtTotal,
    );

    final categorySpend = computeCategorySpend(
      allTx,
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    );

    // Category labels for chart display
    final catResult = await _categoryRepository.getAll();
    if (isClosed) return;
    final categories = _unwrap(catResult);
    if (categories == null) return;

    emit(HomeDashboardLoaded(
      balanceCents: balance,
      netWorthCents: netWorth,
      selectedMonth: _selectedMonth,
      categorySpend: categorySpend,
      categories: categories,
    ));
  }

  /// Unwraps a list [result], emitting [HomeDashboardError] and returning
  /// null when it failed — callers `return` on null.
  ///
  /// Identical error path to the four inline switches it replaces; factored
  /// out only so `_reload` and its CR-04 rationale fit the 150-line cap.
  List<T>? _unwrap<T>(Result<List<T>> result) {
    switch (result) {
      case Err<List<T>>(:final failure):
        emit(HomeDashboardError(failure));
        return null;
      case Success<List<T>>(:final value):
        return value;
    }
  }

  @override
  Future<void> close() async {
    await _txWatchSub?.cancel();
    return super.close();
  }
}
