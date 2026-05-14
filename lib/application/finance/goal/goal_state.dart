import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:equatable/equatable.dart';

/// Base sealed class for all GoalCubit states (single goal view).
sealed class GoalState extends Equatable {
  const GoalState();
}

/// Emitted on construction before any data is loaded.
final class GoalInitial extends GoalState {
  const GoalInitial();
  @override
  List<Object?> get props => [];
}

/// Emitted while the goal is being loaded.
final class GoalLoading extends GoalState {
  const GoalLoading();
  @override
  List<Object?> get props => [];
}

/// Emitted when the goal detail is loaded and ready for display.
///
/// [goal] contains the SavingsGoal entity including manual contributions.
/// [taggedTransactionsCents] is the sum of all tagged transactions
/// (linkedGoalId == goal.id) — used for progress computation.
/// Goal progress = goal.amountSavedCents(taggedTransactionsCents).
final class GoalLoaded extends GoalState {
  const GoalLoaded({
    required this.goal,
    required this.taggedTransactionsCents,
  });

  final SavingsGoal goal;

  /// Sum of amountCents for all active transactions tagged to this goal.
  final int taggedTransactionsCents;

  @override
  List<Object?> get props => [goal, taggedTransactionsCents];
}

/// Emitted when the repository returns an Err.
final class GoalError extends GoalState {
  const GoalError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
