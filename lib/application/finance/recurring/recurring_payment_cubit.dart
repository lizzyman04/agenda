import 'package:agenda/application/finance/recurring/recurring_payment_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Owns the list of recurring payments, paused ones included.
///
/// A paused payment stays in this list on purpose — the list screen holds
/// the only control that can un-pause it, so filtering paused rows out here
/// would make pausing irreversible (CR-02).
///
/// Recurring payments are not reactive — no watchChanges stream on
/// RecurringPaymentRepository. Loaded on demand via [start].
///
/// Factory (not singleton) — a fresh instance per recurring payment screen.
@injectable
class RecurringPaymentCubit extends Cubit<RecurringPaymentState> {
  RecurringPaymentCubit(this._repository)
      : super(const RecurringPaymentInitial());

  final RecurringPaymentRepository _repository;

  /// Loads all non-deleted recurring payments, paused ones included.
  Future<void> start() async {
    await _reload();
  }

  /// Creates a new recurring payment.
  Future<void> createPayment(RecurringPayment payment) async {
    final result = await _repository.createPayment(payment);
    if (result is Err<RecurringPayment>) {
      emit(RecurringPaymentError(result.failure));
      return;
    }
    await _reload();
  }

  /// Updates an existing recurring payment.
  Future<void> updatePayment(RecurringPayment payment) async {
    final result = await _repository.updatePayment(payment);
    if (result is Err<RecurringPayment>) {
      emit(RecurringPaymentError(result.failure));
      return;
    }
    await _reload();
  }

  /// Soft-deletes a recurring payment by id.
  Future<void> softDelete(int id) async {
    final result = await _repository.softDelete(id);
    if (result is Err<RecurringPayment>) {
      emit(RecurringPaymentError(result.failure));
      return;
    }
    await _reload();
  }

  // --- Private ---

  Future<void> _reload() async {
    if (isClosed) return;

    final result = await _repository.getPayments();

    if (isClosed) return;

    switch (result) {
      case Success<List<RecurringPayment>>(:final value):
        emit(RecurringPaymentLoaded(payments: value));
      case Err<List<RecurringPayment>>(:final failure):
        emit(RecurringPaymentError(failure));
    }
  }
}
