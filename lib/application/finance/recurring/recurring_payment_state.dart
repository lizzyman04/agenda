import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment.dart';
import 'package:equatable/equatable.dart';

/// Base sealed class for all RecurringPayment states.
sealed class RecurringPaymentState extends Equatable {
  const RecurringPaymentState();
}

/// Emitted on construction before any data is loaded.
final class RecurringPaymentInitial extends RecurringPaymentState {
  const RecurringPaymentInitial();
  @override
  List<Object?> get props => [];
}

/// Emitted while the repository query is in flight.
final class RecurringPaymentLoading extends RecurringPaymentState {
  const RecurringPaymentLoading();
  @override
  List<Object?> get props => [];
}

/// Emitted when recurring payments are loaded and ready for display.
final class RecurringPaymentLoaded extends RecurringPaymentState {
  const RecurringPaymentLoaded({required this.payments});

  /// Every non-deleted recurring payment, paused ones included.
  ///
  /// Paused rows sort last; read `isActive` per row to tell them apart.
  final List<RecurringPayment> payments;

  @override
  List<Object?> get props => [payments];
}

/// Emitted when the repository returns an Err.
final class RecurringPaymentError extends RecurringPaymentState {
  const RecurringPaymentError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
