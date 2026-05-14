import 'dart:async';

import 'package:agenda/application/finance/goal/goal_list_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/goal_repository.dart';
import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Manages the list of all active savings goals.
///
/// Subscribes to GoalRepository.watchChanges() — reloads automatically
/// whenever the SavingsGoalModel collection changes.
///
/// Factory (not singleton) — a fresh instance per goal list screen.
@injectable
class GoalListCubit extends Cubit<GoalListState> {
  GoalListCubit(this._goalRepository) : super(const GoalListInitial());

  final GoalRepository _goalRepository;
  StreamSubscription<void>? _watchSubscription;

  /// Subscribes to collection changes and loads the initial list.
  Future<void> start() async {
    _watchSubscription = _goalRepository.watchChanges().listen((_) async {
      await _reload();
    });
    await _reload();
  }

  // --- Private ---

  Future<void> _reload() async {
    if (isClosed) return;

    final result = await _goalRepository.getActiveGoals();

    if (isClosed) return;

    switch (result) {
      case Success<List<SavingsGoal>>(:final value):
        emit(GoalListLoaded(goals: value));
      case Err<List<SavingsGoal>>(:final failure):
        emit(GoalListError(failure));
    }
  }

  @override
  Future<void> close() async {
    await _watchSubscription?.cancel();
    return super.close();
  }
}
