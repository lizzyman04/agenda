import 'dart:async';

import 'package:agenda/application/finance/dashboard/dashboard_aggregator.dart';
import 'package:agenda/application/finance/dashboard/home_dashboard_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/category/transaction_category_repository.dart';
import 'package:agenda/domain/finance/debt/debt.dart';
import 'package:agenda/domain/finance/debt/debt_repository.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
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

    // All non-deleted transactions (DAO applies deletedAtIsNull)
    final txResult = await _transactionRepository.getTransactions();
    if (isClosed) return;

    final List<Transaction> allTx;
    switch (txResult) {
      case Err<List<Transaction>>(:final failure):
        emit(HomeDashboardError(failure));
        return;
      case Success<List<Transaction>>(:final value):
        allTx = value;
    }

    final balance = computeBalance(allTx);

    // Active goals; tagged-tx amounts are computed from allTx (no N+1)
    final goalsResult = await _goalRepository.getActiveGoals();
    if (isClosed) return;

    final List<SavingsGoal> goals;
    switch (goalsResult) {
      case Err<List<SavingsGoal>>(:final failure):
        emit(HomeDashboardError(failure));
        return;
      case Success<List<SavingsGoal>>(:final value):
        goals = value;
    }

    final taggedByGoal = computeTaggedByGoal(allTx);
    final goalsSavedTotal = computeGoalsSavedTotal(goals, taggedByGoal);

    final debtsResult = await _debtRepository.getDebts();
    if (isClosed) return;

    final List<Debt> debts;
    switch (debtsResult) {
      case Err<List<Debt>>(:final failure):
        emit(HomeDashboardError(failure));
        return;
      case Success<List<Debt>>(:final value):
        debts = value;
    }

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

    final List<TransactionCategory> categories;
    switch (catResult) {
      case Err<List<TransactionCategory>>(:final failure):
        emit(HomeDashboardError(failure));
        return;
      case Success<List<TransactionCategory>>(:final value):
        categories = value;
    }

    emit(HomeDashboardLoaded(
      balanceCents: balance,
      netWorthCents: netWorth,
      selectedMonth: _selectedMonth,
      categorySpend: categorySpend,
      categories: categories,
    ));
  }

  @override
  Future<void> close() async {
    await _txWatchSub?.cancel();
    return super.close();
  }
}
