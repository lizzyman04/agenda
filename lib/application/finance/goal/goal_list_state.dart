import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:equatable/equatable.dart';

/// Base sealed class for all GoalListCubit states (full goals list view).
sealed class GoalListState extends Equatable {
  const GoalListState();
}

/// Emitted on construction before any data is loaded.
final class GoalListInitial extends GoalListState {
  const GoalListInitial();
  @override
  List<Object?> get props => [];
}

/// Emitted while the repository query is in flight.
final class GoalListLoading extends GoalListState {
  const GoalListLoading();
  @override
  List<Object?> get props => [];
}

/// Emitted when goals are loaded and ready for display.
final class GoalListLoaded extends GoalListState {
  const GoalListLoaded({required this.goals});

  /// Active (non-deleted) savings goals.
  final List<SavingsGoal> goals;

  @override
  List<Object?> get props => [goals];
}

/// Emitted when the repository returns an Err.
final class GoalListError extends GoalListState {
  const GoalListError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
