import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/domain/finance/transaction_category.dart';
import 'package:equatable/equatable.dart';

/// Base sealed class for all Budget states.
sealed class BudgetState extends Equatable {
  const BudgetState();
}

/// Emitted on construction before any data is loaded.
final class BudgetInitial extends BudgetState {
  const BudgetInitial();
  @override
  List<Object?> get props => [];
}

/// Emitted while the repository query is in flight.
final class BudgetLoading extends BudgetState {
  const BudgetLoading();
  @override
  List<Object?> get props => [];
}

/// Emitted when budget data is loaded and ready for display.
///
/// [budgets] is a map from categoryId to a record containing
/// the configured limit and the amount spent in the current month.
/// Categories with spend but no configured limit have limitCents = 0.
final class BudgetLoaded extends BudgetState {
  const BudgetLoaded({
    required this.budgets,
    required this.categories,
  });

  /// Map: categoryId → ({limitCents, spentCents}).
  final Map<int, ({int limitCents, int spentCents})> budgets;

  /// All expense categories, for label lookup.
  final List<TransactionCategory> categories;

  @override
  List<Object?> get props => [budgets, categories];
}

/// Emitted when the repository returns an Err.
final class BudgetError extends BudgetState {
  const BudgetError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
