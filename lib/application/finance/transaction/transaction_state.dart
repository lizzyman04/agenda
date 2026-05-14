import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/domain/finance/transaction.dart';
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
final class TransactionLoaded extends TransactionState {
  const TransactionLoaded({required this.transactions});

  /// Domain entities — never TransactionModel.
  final List<Transaction> transactions;

  @override
  List<Object?> get props => [transactions];
}

/// Emitted when the repository returns an Err.
final class TransactionError extends TransactionState {
  const TransactionError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
