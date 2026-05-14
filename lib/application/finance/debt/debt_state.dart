import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/domain/finance/debt.dart';
import 'package:equatable/equatable.dart';

/// Base sealed class for all Debt states.
sealed class DebtState extends Equatable {
  const DebtState();
}

/// Emitted on construction before any data is loaded.
final class DebtInitial extends DebtState {
  const DebtInitial();
  @override
  List<Object?> get props => [];
}

/// Emitted while the repository query is in flight.
final class DebtLoading extends DebtState {
  const DebtLoading();
  @override
  List<Object?> get props => [];
}

/// Emitted when debts are loaded and ready for display.
final class DebtLoaded extends DebtState {
  const DebtLoaded({required this.debts});

  /// Active (non-deleted) debts.
  final List<Debt> debts;

  @override
  List<Object?> get props => [debts];
}

/// Emitted when the repository returns an Err.
final class DebtError extends DebtState {
  const DebtError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
