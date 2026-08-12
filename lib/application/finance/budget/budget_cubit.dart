import 'dart:async';

import 'package:agenda/application/finance/budget/budget_aggregator.dart';
import 'package:agenda/application/finance/budget/budget_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/budget/budget.dart';
import 'package:agenda/domain/finance/budget/budget_repository.dart';
import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/category/transaction_category_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Computes budget vs. actual spend for all expense categories.
///
/// Subscribes to TransactionRepository.watchChanges() — when a transaction
/// changes, budgets must re-compute (T-03-03-03).
///
/// Factory (not singleton) — a fresh instance per budget screen.
@injectable
class BudgetCubit extends Cubit<BudgetState> {
  BudgetCubit(
    this._transactionRepository,
    this._budgetRepository,
    this._categoryRepository,
  ) : super(const BudgetInitial());

  final TransactionRepository _transactionRepository;
  final BudgetRepository _budgetRepository;
  final TransactionCategoryRepository _categoryRepository;

  StreamSubscription<void>? _watchSubscription;

  /// Subscribes to transaction changes and loads the initial budget data.
  Future<void> start() async {
    _watchSubscription = _transactionRepository
        .watchChanges()
        .listen((_) async => _reload());
    await _reload();
  }

  /// Sets a budget limit for [categoryId] in [month]/[year] and reloads.
  Future<void> setLimit(
    int categoryId,
    int month,
    int year,
    int limitCents,
  ) async {
    final result = await _budgetRepository.setLimit(
      categoryId,
      month,
      year,
      limitCents,
    );
    if (result is Err<Budget>) {
      emit(BudgetError(result.failure));
      return;
    }
    await _reload();
  }

  /// Reloads budget data for the current month. Exposed for explicit refresh.
  Future<void> reload() async {
    await _reload();
  }

  // --- Private ---

  Future<void> _reload() async {
    if (isClosed) return;

    final now = DateTime.now();
    final month = now.month;
    final year = now.year;

    // (1) Load expense transactions for current month
    final txResult = await _transactionRepository.getByMonth(month, year);
    if (isClosed) return;

    final List<Transaction> transactions;
    switch (txResult) {
      case Err<List<Transaction>>(:final failure):
        emit(BudgetError(failure));
        return;
      case Success<List<Transaction>>(:final value):
        transactions = value;
    }

    // (2) Load budget limits for current month
    final budgetsResult = await _budgetRepository.getForMonth(month, year);
    if (isClosed) return;

    final List<Budget> budgets;
    switch (budgetsResult) {
      case Err<List<Budget>>(:final failure):
        emit(BudgetError(failure));
        return;
      case Success<List<Budget>>(:final value):
        budgets = value;
    }

    // (3) Load all expense categories
    final catResult =
        await _categoryRepository.getByType(TransactionType.expense);
    if (isClosed) return;

    final List<TransactionCategory> categories;
    switch (catResult) {
      case Err<List<TransactionCategory>>(:final failure):
        emit(BudgetError(failure));
        return;
      case Success<List<TransactionCategory>>(:final value):
        categories = value;
    }

    // (4) Merge spend + limit data per category (see budget_aggregator.dart)
    final combined = mergeBudgetData(
      transactions: transactions,
      budgets: budgets,
    );

    emit(BudgetLoaded(budgets: combined, categories: categories));
  }

  @override
  Future<void> close() async {
    await _watchSubscription?.cancel();
    return super.close();
  }
}
