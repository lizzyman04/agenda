import 'dart:async';

import 'package:agenda/application/finance/transaction/transaction_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/domain/finance/transaction_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Owns the list of financial transactions.
///
/// Subscribes to TransactionRepository.watchChanges() — reloads automatically
/// whenever the Isar collection changes (T-03-03-05).
///
/// Factory (not singleton) — a fresh instance per screen.
@injectable
class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit(this._repository) : super(const TransactionInitial());

  final TransactionRepository _repository;
  StreamSubscription<void>? _watchSubscription;

  /// Subscribes to collection changes and loads the initial list.
  ///
  /// Call once from the transaction list screen's initState.
  Future<void> start() async {
    _watchSubscription = _repository.watchChanges().listen((_) async {
      await _reload();
    });
    await _reload();
  }

  /// Creates a new transaction.
  ///
  /// The watchChanges() stream fires automatically after the write,
  /// triggering _reload() via the listener.
  Future<void> createTransaction(Transaction transaction) async {
    final result = await _repository.createTransaction(transaction);
    if (result is Err<Transaction>) {
      emit(TransactionError(result.failure));
    }
    // watchChanges() fires reload automatically
  }

  /// Updates an existing transaction.
  Future<void> updateTransaction(Transaction transaction) async {
    final result = await _repository.updateTransaction(transaction);
    if (result is Err<Transaction>) {
      emit(TransactionError(result.failure));
    }
    // watchChanges() fires reload automatically
  }

  /// Soft-deletes a transaction by id.
  ///
  /// The watchChanges() stream fires automatically after the write.
  Future<void> softDelete(int id) async {
    final result = await _repository.softDelete(id);
    if (result is Err<Transaction>) {
      emit(TransactionError(result.failure));
    }
    // watchChanges() fires reload automatically
  }

  // --- Private ---

  Future<void> _reload() async {
    if (isClosed) return;

    final result = await _repository.getTransactions();

    if (isClosed) return;

    switch (result) {
      case Success<List<Transaction>>(:final value):
        emit(TransactionLoaded(transactions: value));
      case Err<List<Transaction>>(:final failure):
        emit(TransactionError(failure));
    }
  }

  @override
  Future<void> close() async {
    await _watchSubscription?.cancel();
    return super.close();
  }
}
