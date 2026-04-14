import 'dart:async';

import 'package:agenda/application/tasks/task_list/task_list_filter.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_repository.dart';
import 'package:agenda/domain/tasks/recurrence_engine.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Owns the filtered and searched task list (TASK-11, TASK-12).
///
/// Subscribes to ItemRepository.watchChanges() — reloads automatically
/// whenever the Isar collection changes (T-02-05).
///
/// Factory (not singleton) — a fresh instance is created each time the
/// task list screen is opened.
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

  /// Subscribes to collection changes and loads the initial list.
  ///
  /// Call once from the task list screen's initState or BlocProvider.
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

  /// Soft-deletes an item and emits [TaskListWithPendingUndo] (TASK-05).
  ///
  /// The undo snackbar duration is AppConstants.undoSnackbarDuration (5s).
  /// If not restored within 5 s, the state transitions to TaskListLoaded
  /// (the item remains soft-deleted in Isar).
  Future<void> softDelete(int id) async {
    final result = await _repository.softDelete(id);
    if (result is Err<Item>) {
      emit(TaskListError(result.failure));
      return;
    }

    final currentItems = _currentItems();
    final updatedItems = currentItems.where((i) => i.id != id).toList();

    _undoTimer?.cancel();
    emit(TaskListWithPendingUndo(
      deletedItemId: id,
      items: updatedItems,
      filter: _filter,
      searchQuery: _searchQuery,
    ));

    _undoTimer = Timer(AppConstants.undoSnackbarDuration, () async {
      // 5-second window closed — item remains soft-deleted; reload fresh state
      await _reload();
    });
  }

  /// Restores a soft-deleted item within the undo window (TASK-05).
  ///
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

  /// Creates a new item (TASK-01, TASK-03).
  ///
  /// The watchChanges() stream fires automatically after the write,
  /// triggering _reload() via the listener.
  Future<void> createItem(Item item) async {
    final result = await _repository.createItem(item);
    if (result is Err<Item>) {
      emit(TaskListError(result.failure));
    }
    // watchChanges() fires reload automatically
  }

  /// Updates an existing item (edit flow — TASK-03).
  Future<void> updateItem(Item item) async {
    final result = await _repository.updateItem(item);
    if (result is Err<Item>) {
      emit(TaskListError(result.failure));
    }
    // watchChanges() fires reload automatically
  }

  /// Marks an item as completed (TASK-06).
  ///
  /// For recurring tasks (TASK-10): creates a new Item with the next
  /// occurrence's dueDate computed by [RecurrenceEngine].
  /// The watch stream fires and triggers _reload() automatically.
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

    // Recurring task: create next occurrence (TASK-10)
    if (item.recurrenceRule != null && item.dueDate != null) {
      final rule = _recurrenceEngine.parse(item.recurrenceRule);
      if (rule != null) {
        final nextDate =
            _recurrenceEngine.nextOccurrence(item.dueDate!, rule);
        final nextItem = Item(
          id: 0, // Isar auto-increment assigns a new id
          type: item.type,
          title: item.title,
          description: item.description,
          parentId: item.parentId,
          priority: item.priority,
          isUrgent: item.isUrgent,
          isImportant: item.isImportant,
          sizeCategory: item.sizeCategory,
          isNextAction: item.isNextAction,
          gtdContext: item.gtdContext,
          waitingFor: item.waitingFor,
          dueDate: nextDate,
          dueTimeMinutes: item.dueTimeMinutes,
          recurrenceRule: item.recurrenceRule,
          amount: item.amount,
          currencyCode: item.currencyCode,
          createdAt: now,
          updatedAt: now,
        );
        await _repository.createItem(nextItem);
        // watchChanges() stream fires; _reload() called by listener
      }
    }
    // watchChanges() fires reload for the completed item update
  }

  // --- Private ---

  Future<void> _reload() async {
    if (isClosed) return;

    final result = _searchQuery.isNotEmpty
        ? await _repository.searchByTitle(_searchQuery)
        : await _repository.filterItems(
            type: _filter.itemType,
            quadrant: _filter.quadrant,
            gtdContext: _filter.gtdContext,
            dueDateFrom: _filter.dueDateFrom,
            dueDateTo: _filter.dueDateTo,
            parentId: _filter.projectId,
            showCompleted: _filter.showCompleted,
          );

    if (isClosed) return;

    if (result is Success<List<Item>>) {
      emit(TaskListLoaded(
        items: result.value,
        filter: _filter,
        searchQuery: _searchQuery,
      ));
    } else if (result is Err<List<Item>>) {
      emit(TaskListError(result.failure));
    }
  }

  List<Item> _currentItems() {
    return switch (state) {
      TaskListLoaded(:final items) => items,
      TaskListWithPendingUndo(:final items) => items,
      _ => [],
    };
  }

  @override
  Future<void> close() async {
    _undoTimer?.cancel();
    await _watchSubscription?.cancel();
    return super.close();
  }
}
