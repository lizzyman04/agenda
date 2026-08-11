import 'dart:async';

import 'package:agenda/application/tasks/task_list/recurring_completion.dart';
import 'package:agenda/application/tasks/task_list/task_list_filter.dart';
import 'package:agenda/application/tasks/task_list/task_list_reload.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_repository.dart';
import 'package:agenda/domain/tasks/recurrence_engine.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Owns the filtered and searched task list (TASK-11, TASK-12); subscribes
/// to watchChanges() (T-02-05). Factory (not singleton) per screen open.
@injectable
class TaskListCubit extends Cubit<TaskListState> {
  TaskListCubit(this._repository, this._recurrenceEngine)
      : super(const TaskListInitial());

  final ItemRepository _repository;
  final RecurrenceEngine _recurrenceEngine;
  StreamSubscription<void>? _watchSubscription;
  Timer? _undoTimer;
  TaskListFilter _filter = TaskListFilter.empty;
  String _searchQuery = '';

  /// Subscribes to collection changes and loads the initial list. Call
  /// once from the task list screen's initState or BlocProvider.
  Future<void> start() async {
    _watchSubscription = _repository.watchChanges().listen((_) async {
      await _reload();
    });
    await _reload();
  }

  /// Updates the active filter and reloads.
  Future<void> applyFilter(TaskListFilter filter) async {
    _filter = filter;
    await _reload();
  }

  /// Updates the keyword search query and reloads (TASK-11).
  Future<void> search(String query) async {
    _searchQuery = query;
    await _reload();
  }

  /// Soft-deletes an item and emits [TaskListWithPendingUndo] (TASK-05);
  /// undo window is 5s (AppConstants.undoSnackbarDuration); item stays
  /// soft-deleted in Isar whether or not the undo window is used.
  Future<void> softDelete(int id) async {
    final result = await _repository.softDelete(id);
    if (result is Err<Item>) {
      emit(TaskListError(result.failure));
      return;
    }
    final currentItems = currentItemsFromState(state);
    final updatedItems = currentItems.where((i) => i.id != id).toList();
    _undoTimer?.cancel();
    emit(TaskListWithPendingUndo(
      deletedItemId: id,
      items: updatedItems,
      filter: _filter,
      searchQuery: _searchQuery,
    ));
    _undoTimer = Timer(AppConstants.undoSnackbarDuration, () async {
      await _reload();
    });
  }

  /// Restores a soft-deleted item within the undo window (TASK-05).
  /// Cancels the undo timer and emits a fresh TaskListLoaded.
  Future<void> restoreItem(int id) async {
    _undoTimer?.cancel();
    _undoTimer = null;
    final result = await _repository.restoreItem(id);
    if (result is Err<Item>) {
      emit(TaskListError(result.failure));
      return;
    }
    await _reload();
  }

  /// Creates a new item (TASK-01, TASK-03). Returns `true`/`false` for
  /// success — callers must branch on this, not post-await state: success
  /// emits nothing (watchChanges() drives reload), so a stale
  /// [TaskListError] from a prior op could be mistaken for this outcome.
  Future<bool> createItem(Item item) async {
    final result = await _repository.createItem(item);
    if (result is Err<Item>) {
      emit(TaskListError(result.failure));
      return false;
    }
    return true;
  }

  /// Updates an existing item (edit flow — TASK-03). See [createItem] for
  /// why the boolean result, not post-await state, is the source of truth.
  Future<bool> updateItem(Item item) async {
    final result = await _repository.updateItem(item);
    if (result is Err<Item>) {
      emit(TaskListError(result.failure));
      return false;
    }
    return true;
  }

  /// Marks an item as completed (TASK-06); recurring tasks (TASK-10) get
  /// their next occurrence via [RecurrenceEngine], reload via watchChanges().
  Future<void> completeItem(Item item) async {
    final now = DateTime.now();
    final updated = item.copyWith(
      isCompleted: true,
      completedAt: now,
      updatedAt: now,
    );
    final result = await _repository.updateItem(updated);
    if (result is Err<Item>) {
      emit(TaskListError(result.failure));
      return;
    }
    if (item.recurrenceRule != null && item.dueDate != null) {
      final rule = _recurrenceEngine.parse(item.recurrenceRule);
      if (rule != null) {
        final nextDate =
            _recurrenceEngine.nextOccurrence(item.dueDate!, rule);
        final nextItem = buildNextOccurrence(item, nextDate);
        await _repository.createItem(nextItem);
      }
    }
  }

  Future<void> _reload() async {
    if (isClosed) return;
    final newState = await reloadTaskListState(
      repository: _repository,
      searchQuery: _searchQuery,
      filter: _filter,
    );
    if (!isClosed) emit(newState);
  }
  @override
  Future<void> close() async {
    _undoTimer?.cancel();
    await _watchSubscription?.cancel();
    return super.close();
  }
}
