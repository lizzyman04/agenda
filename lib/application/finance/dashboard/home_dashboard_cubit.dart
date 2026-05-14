import 'dart:async';

import 'package:agenda/application/finance/dashboard/home_dashboard_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/debt.dart';
import 'package:agenda/domain/finance/debt_direction.dart';
import 'package:agenda/domain/finance/debt_repository.dart';
import 'package:agenda/domain/finance/goal_repository.dart';
import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/domain/finance/transaction_category.dart';
import 'package:agenda/domain/finance/transaction_category_repository.dart';
import 'package:agenda/domain/finance/transaction_repository.dart';
import 'package:agenda/domain/finance/transaction_type.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Aggregates all finance dashboard data in a single reactive cubit.
///
/// Subscribes to TransactionRepository.watchChanges() — reloads when
/// transactions change. Performs single-pass aggregation over all
/// transactions for balance (D-07), net worth (D-08), and chart data (D-09).
///
/// No N+1 Isar queries — all data is fetched in parallel logical steps
/// then aggregated in Dart (T-03-03-01).
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
  Future<void> start() async {
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

  // --- Private ---

  /// Single-pass aggregation per D-07, D-08, D-09 formulas.
  ///
  /// Step order:
  /// 1. Load all non-deleted transactions (single Isar query, 500-item cap)
  /// 2. Compute lifetime balance in one Dart loop (no second query)
  /// 3. Load active goals and compute tagged-tx amounts for each per allTx
  /// 4. Load debts; compute net worth D-08 (toPay && !isPaid only)
  /// 5. Filter allTx to selectedMonth expenses; groupBy categoryId in Dart
  /// 6. Load category labels for chart rendering
  /// 7. Emit HomeDashboardLoaded
  Future<void> _reload() async {
    if (isClosed) return;

    // Step 1 — All non-deleted transactions (DAO applies deletedAtIsNull)
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

    // Step 2 — Balance: single-pass income/expense sum (D-07)
    var income = 0;
    var expenses = 0;
    for (final tx in allTx) {
      if (tx.type == TransactionType.income) {
        income += tx.amountCents;
      } else {
        expenses += tx.amountCents;
      }
    }
    final balance = income - expenses;

    // Step 3 — Load active goals; compute tagged-tx amounts from allTx
    // (avoids second Isar query per goal — no N+1)
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

    // Build a map of goalId -> taggedTransactionsCents from allTx in one pass
    final taggedByGoal = <int, int>{};
    for (final tx in allTx) {
      final goalId = tx.linkedGoalId;
      if (goalId != null) {
        taggedByGoal[goalId] = (taggedByGoal[goalId] ?? 0) + tx.amountCents;
      }
    }

    // Sum of all active goal savings (manual contributions + tagged txs)
    final goalsSavedTotal = goals.fold(
      0,
      (sum, g) => sum + g.amountSavedCents(taggedByGoal[g.id] ?? 0),
    );

    // Step 4 — Load debts; compute D-08 formula
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

    // D-08: only toPay && !isPaid debts are subtracted from net worth.
    // Debts-to-receive (toReceive) are explicitly excluded (T-03-03-01).
    final debtTotal = debts
        .where(
          (d) => d.direction == DebtDirection.toPay && !d.isPaid,
        )
        .fold(0, (sum, d) => sum + d.amountCents);

    final netWorth = balance + goalsSavedTotal - debtTotal;

    // Step 5 — Filter allTx to selectedMonth expenses; groupBy categoryId
    // Single-pass Dart loop — no additional Isar query (no N+1)
    final selectedYear = _selectedMonth.year;
    final selectedMonthNum = _selectedMonth.month;
    final categorySpend = <int, int>{};
    for (final tx in allTx) {
      if (tx.type == TransactionType.expense &&
          tx.date.year == selectedYear &&
          tx.date.month == selectedMonthNum &&
          tx.deletedAt == null) {
        categorySpend[tx.categoryId] =
            (categorySpend[tx.categoryId] ?? 0) + tx.amountCents;
      }
    }

    // Step 6 — Load category labels for chart display
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

    // Step 7 — Emit loaded state
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
