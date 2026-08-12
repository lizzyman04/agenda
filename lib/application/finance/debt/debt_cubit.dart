import 'dart:async';

import 'package:agenda/application/finance/debt/debt_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/debt/debt.dart';
import 'package:agenda/domain/finance/debt/debt_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Owns the list of debts (to pay and to receive).
///
/// Subscribes to DebtRepository.watchChanges() — reloads automatically
/// whenever the DebtModel collection changes.
///
/// Factory (not singleton) — a fresh instance per debt screen.
@injectable
class DebtCubit extends Cubit<DebtState> {
  DebtCubit(this._repository) : super(const DebtInitial());

  final DebtRepository _repository;
  StreamSubscription<void>? _watchSubscription;

  /// Subscribes to collection changes and loads the initial list.
  Future<void> start() async {
    _watchSubscription = _repository.watchChanges().listen((_) async {
      await _reload();
    });
    await _reload();
  }

  /// Creates a new debt.
  Future<void> createDebt(Debt debt) async {
    final result = await _repository.createDebt(debt);
    if (result is Err<Debt>) {
      emit(DebtError(result.failure));
    }
    // watchChanges() fires reload automatically
  }

  /// Updates an existing debt.
  Future<void> updateDebt(Debt debt) async {
    final result = await _repository.updateDebt(debt);
    if (result is Err<Debt>) {
      emit(DebtError(result.failure));
    }
    // watchChanges() fires reload automatically
  }

  /// Toggles the paid status for the debt with [id].
  ///
  /// After toggling, triggers a reload to reflect the updated state.
  Future<void> togglePaid(int id) async {
    final result = await _repository.togglePaid(id);
    if (result is Err<Debt>) {
      emit(DebtError(result.failure));
      return;
    }
    // Explicitly reload to get fresh list state
    await _reload();
  }

  /// Soft-deletes a debt by id.
  Future<void> softDelete(int id) async {
    final result = await _repository.softDelete(id);
    if (result is Err<Debt>) {
      emit(DebtError(result.failure));
    }
    // watchChanges() fires reload automatically
  }

  // --- Private ---

  Future<void> _reload() async {
    if (isClosed) return;

    final result = await _repository.getDebts();

    if (isClosed) return;

    switch (result) {
      case Success<List<Debt>>(:final value):
        emit(DebtLoaded(debts: value));
      case Err<List<Debt>>(:final failure):
        emit(DebtError(failure));
    }
  }

  @override
  Future<void> close() async {
    await _watchSubscription?.cancel();
    return super.close();
  }
}
