import 'package:agenda/application/finance/goal/goal_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:agenda/domain/finance/goal/savings_goal_contribution.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Manages the detail view of a single savings goal.
///
/// Unlike list cubits, GoalCubit is a detail cubit — no auto-start via
/// watchChanges(). Loads on demand via [loadGoal].
///
/// Progress = goal.contributions + tagged transaction amounts (D-11).
/// Two contribution paths are exclusive by design (T-03-03-04).
///
/// Factory (not singleton) — one per goal detail screen.
@injectable
class GoalCubit extends Cubit<GoalState> {
  GoalCubit(this._goalRepository, this._transactionRepository)
      : super(const GoalInitial());

  final GoalRepository _goalRepository;
  final TransactionRepository _transactionRepository;

  /// Loads the goal with [id] and computes tagged transaction amounts.
  Future<void> loadGoal(int id) async {
    emit(const GoalLoading());
    final goalResult = await _goalRepository.getGoal(id);
    final SavingsGoal goal;
    switch (goalResult) {
      case Err<SavingsGoal>(:final failure):
        emit(GoalError(failure));
        return;
      case Success<SavingsGoal>(:final value):
        goal = value;
    }
    await _refreshGoal(goal);
  }

  /// Appends [contribution] to goal and refreshes.
  Future<void> addContribution(
    int goalId,
    SavingsGoalContribution contribution,
  ) async {
    final result = await _goalRepository.addContribution(goalId, contribution);
    switch (result) {
      case Err<SavingsGoal>(:final failure):
        emit(GoalError(failure));
        return;
      case Success<SavingsGoal>(:final value):
        await _refreshGoal(value);
    }
  }

  /// Creates a new savings goal.
  Future<void> createGoal(SavingsGoal goal) async {
    final result = await _goalRepository.createGoal(goal);
    if (result is Err<SavingsGoal>) {
      emit(GoalError(result.failure));
    }
  }

  /// Updates an existing savings goal.
  Future<void> updateGoal(SavingsGoal goal) async {
    final result = await _goalRepository.updateGoal(goal);
    switch (result) {
      case Err<SavingsGoal>(:final failure):
        emit(GoalError(failure));
        return;
      case Success<SavingsGoal>(:final value):
        await _refreshGoal(value);
    }
  }

  /// Soft-deletes the goal.
  Future<void> softDeleteGoal(int id) async {
    final result = await _goalRepository.softDelete(id);
    if (result is Err<SavingsGoal>) {
      emit(GoalError(result.failure));
    }
  }

  // --- Private ---

  /// Loads tagged transactions for [goal] and emits [GoalLoaded].
  ///
  /// Tagged transactions are transactions with linkedGoalId == goal.id.
  /// Their amountCents are summed separately from manual contributions
  /// — two paths are exclusive, never double-counted (D-11, T-03-03-04).
  Future<void> _refreshGoal(SavingsGoal goal) async {
    final txResult = await _transactionRepository.getByLinkedGoal(goal.id);
    final List<Transaction> tagged;
    switch (txResult) {
      case Err<List<Transaction>>(:final failure):
        emit(GoalError(failure));
        return;
      case Success<List<Transaction>>(:final value):
        tagged = value;
    }
    final taggedCents = tagged.fold(0, (sum, tx) => sum + tx.amountCents);
    emit(GoalLoaded(goal: goal, taggedTransactionsCents: taggedCents));
  }
}
