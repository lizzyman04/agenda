import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/tasks/eisenhower_quadrant.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';

/// Abstract repository interface for all Item types
/// (project, task, subtask).
///
/// One interface for the unified collection — ItemType discriminates.
/// All methods return AsyncResult and never throw (D-05 pattern).
abstract class ItemRepository {
  /// Creates a new item and returns it with the assigned Isar id.
  AsyncResult<Item> createItem(Item item);

  /// Returns the item with [id], or Err(DatabaseFailure) if not found.
  AsyncResult<Item> getItem(int id);

  /// Returns all active (non-deleted) items of [type].
  /// Apply limit(500) inside the implementation — T-02-02.
  AsyncResult<List<Item>> getItemsByType(ItemType type);

  /// Returns all active subtasks whose parentId == [projectId].
  AsyncResult<List<Item>> getSubtasks(int projectId);

  /// Overwrites the stored item with the provided [item].
  /// Updates updatedAt to DateTime.now() before writing.
  AsyncResult<Item> updateItem(Item item);

  /// Soft-deletes by setting deletedAt = DateTime.now() (TASK-05).
  /// Returns the updated item.
  AsyncResult<Item> softDelete(int id);

  /// Restores a soft-deleted item by nulling deletedAt (TASK-05 undo).
  AsyncResult<Item> restoreItem(int id);

  /// Keyword search across title — case-insensitive substring match
  /// (TASK-11).
  /// Uses Isar titleContains() — never raw string interpolation (T-02-01).
  AsyncResult<List<Item>> searchByTitle(String query);

  /// Multi-criteria filter — all parameters are optional (TASK-12).
  /// null parameter = not filtered on that axis.
  /// All queries apply deletedAtIsNull() first and limit(500) — T-02-02.
  AsyncResult<List<Item>> filterItems({
    ItemType? type,
    EisenhowerQuadrant? quadrant,
    String? gtdContext,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
    int? parentId,
    bool showCompleted,
  });

  /// Subtask rollup: returns (completedCount, totalCount) for [projectId].
  AsyncResult<(int, int)> getSubtaskCounts(int projectId);

  /// Stream that fires when the ItemModel collection changes.
  /// Cubits subscribe via start() and call _reload() on each event.
  Stream<void> watchChanges();

  /// Returns a sorted list of distinct, non-null GTD context strings
  /// from all active (non-deleted) items (TASK-09).
  ///
  /// Used by GtdFilterScreen to populate the chip list.
  AsyncResult<List<String>> getDistinctGtdContexts();
}
