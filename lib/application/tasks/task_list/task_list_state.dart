import 'package:agenda/application/tasks/task_list/task_list_filter.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:equatable/equatable.dart';

/// Base sealed class for all TaskList states.
sealed class TaskListState extends Equatable {
  const TaskListState();
}

/// Emitted on construction before any data is loaded.
final class TaskListInitial extends TaskListState {
  const TaskListInitial();
  @override
  List<Object?> get props => [];
}

/// Emitted while the repository query is in flight.
final class TaskListLoading extends TaskListState {
  const TaskListLoading();
  @override
  List<Object?> get props => [];
}

/// Emitted when items are loaded and ready for display.
final class TaskListLoaded extends TaskListState {
  const TaskListLoaded({
    required this.items,
    this.filter = TaskListFilter.empty,
    this.searchQuery = '',
  });

  /// Domain entities — never ItemModel.
  final List<Item> items;
  final TaskListFilter filter;
  final String searchQuery;

  @override
  List<Object?> get props => [items, filter, searchQuery];
}

/// Emitted immediately after a soft delete — carries the deleted item id
/// and a copy of the current item list (with the item removed) so the
/// presentation layer can show the undo snackbar.
///
/// After AppConstants.undoSnackbarDuration, transitions back to TaskListLoaded.
final class TaskListWithPendingUndo extends TaskListState {
  const TaskListWithPendingUndo({
    required this.deletedItemId,
    required this.items,
    this.filter = TaskListFilter.empty,
    this.searchQuery = '',
  });

  final int deletedItemId;
  final List<Item> items;
  final TaskListFilter filter;
  final String searchQuery;

  @override
  List<Object?> get props => [deletedItemId, items, filter, searchQuery];
}

/// Emitted when the repository returns an Err.
final class TaskListError extends TaskListState {
  const TaskListError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
