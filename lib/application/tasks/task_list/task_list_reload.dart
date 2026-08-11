import 'package:agenda/application/tasks/task_list/task_list_filter.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_repository.dart';

/// Runs the search-or-filter query and maps the result to a [TaskListState].
///
/// Extracted from `TaskListCubit._reload()` so the query-selection and
/// result-mapping logic can be tested and read independently of the cubit's
/// stream-subscription/emit orchestration.
Future<TaskListState> reloadTaskListState({
  required ItemRepository repository,
  required String searchQuery,
  required TaskListFilter filter,
}) async {
  final result = searchQuery.isNotEmpty
      ? await repository.searchByTitle(searchQuery)
      : await repository.filterItems(
          type: filter.itemType,
          quadrant: filter.quadrant,
          gtdContext: filter.gtdContext,
          dueDateFrom: filter.dueDateFrom,
          dueDateTo: filter.dueDateTo,
          parentId: filter.projectId,
          showCompleted: filter.showCompleted,
        );

  return switch (result) {
    Success<List<Item>>(:final value) => TaskListLoaded(
        items: value,
        filter: filter,
        searchQuery: searchQuery,
      ),
    Err<List<Item>>(:final failure) => TaskListError(failure),
  };
}

/// Extracts the current item list from a [TaskListState], or `[]` for
/// states with no item list (e.g. [TaskListInitial], [TaskListError]).
List<Item> currentItemsFromState(TaskListState state) {
  return switch (state) {
    TaskListLoaded(:final items) => items,
    TaskListWithPendingUndo(:final items) => items,
    _ => [],
  };
}
