import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:equatable/equatable.dart';

/// Base sealed class for all Transaction states.
sealed class TransactionState extends Equatable {
  const TransactionState();
}

/// Emitted on construction before any data is loaded.
final class TransactionInitial extends TransactionState {
  const TransactionInitial();
  @override
  List<Object?> get props => [];
}

/// Emitted while the repository query is in flight.
final class TransactionLoading extends TransactionState {
  const TransactionLoading();
  @override
  List<Object?> get props => [];
}

/// Emitted when transactions are loaded and ready for display.
///
/// [categories] travels with the transactions so the presentation layer can
/// resolve a [Transaction.categoryId] to a display name without issuing a
/// second query per row.
final class TransactionLoaded extends TransactionState {
  const TransactionLoaded({
    required this.transactions,
    required this.categories,
  });

  /// Domain entities — never TransactionModel.
  final List<Transaction> transactions;

  /// All categories (income and expense), for label lookup.
  final List<TransactionCategory> categories;

  @override
  List<Object?> get props => [transactions, categories];
}

/// Emitted when the repository returns an Err.
final class TransactionError extends TransactionState {
  const TransactionError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
