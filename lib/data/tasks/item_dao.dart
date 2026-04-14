import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:isar_community/isar.dart';

/// Raw Isar query access for [ItemModel].
///
/// All list queries apply .deletedAtIsNull() and .limit(500) — T-02-02.
/// Never use findSync, putSync, deleteSync — async only.
class ItemDao {
  const ItemDao(this._isarService);

  final IsarService _isarService;

  IsarCollection<ItemModel> get _collection =>
      _isarService.db.collection<ItemModel>();

  // --- Reads ---

  Future<ItemModel?> findById(int id) async => _collection.get(id);

  Future<List<ItemModel>> findByType(ItemType type) async => _collection
      .filter()
      .typeEqualTo(type)
      .and()
      .deletedAtIsNull()
      .limit(500)
      .findAll();

  Future<List<ItemModel>> findSubtasks(int projectId) async => _collection
      .filter()
      .parentIdEqualTo(projectId)
      .and()
      .deletedAtIsNull()
      .limit(500)
      .findAll();

  Future<List<ItemModel>> searchByTitle(String query) async => _collection
      .filter()
      .deletedAtIsNull()
      .and()
      .titleContains(query, caseSensitive: false)
      .limit(500)
      .findAll();

  Future<List<ItemModel>> filterItems({
    ItemType? type,
    bool? isUrgent,
    bool? isImportant,
    String? gtdContext,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
    int? parentId,
    bool showCompleted = false,
  }) async {
    // Always start with active (non-deleted) items.
    // Use .optional() to conditionally chain each filter — preserves the
    // Isar QueryBuilder phantom-type invariant without dynamic reassignment.
    return _collection
        .filter()
        .deletedAtIsNull()
        .optional(type != null, (q) => q.and().typeEqualTo(type!))
        .optional(isUrgent != null, (q) => q.and().isUrgentEqualTo(isUrgent!))
        .optional(
          isImportant != null,
          (q) => q.and().isImportantEqualTo(isImportant!),
        )
        .optional(
          gtdContext != null,
          (q) => q.and().gtdContextEqualTo(gtdContext!),
        )
        .optional(
          dueDateFrom != null && dueDateTo != null,
          (q) => q.and().dueDateBetween(dueDateFrom!, dueDateTo!),
        )
        .optional(
          dueDateFrom != null && dueDateTo == null,
          (q) => q.and().dueDateGreaterThan(dueDateFrom!, include: true),
        )
        .optional(
          dueDateTo != null && dueDateFrom == null,
          (q) => q.and().dueDateLessThan(dueDateTo!, include: true),
        )
        .optional(parentId != null, (q) => q.and().parentIdEqualTo(parentId!))
        .optional(
          !showCompleted,
          (q) => q.and().isCompletedEqualTo(false),
        )
        .limit(500)
        .findAll();
  }

  /// Count subtasks for rollup — O(1) with index.
  Future<int> countSubtasks(int projectId) async => _collection
      .filter()
      .parentIdEqualTo(projectId)
      .and()
      .deletedAtIsNull()
      .count();

  Future<int> countCompletedSubtasks(int projectId) async => _collection
      .filter()
      .parentIdEqualTo(projectId)
      .and()
      .deletedAtIsNull()
      .and()
      .isCompletedEqualTo(true)
      .count();

  // --- Writes ---

  Future<int> save(ItemModel model) async =>
      _isarService.db.writeTxn(() => _collection.put(model));

  /// Saves multiple models in a single transaction (used for recurring task
  /// completion).
  Future<void> saveAll(List<ItemModel> models) async =>
      _isarService.db.writeTxn(() => _collection.putAll(models));

  Future<void> softDelete(int id) async {
    await _isarService.db.writeTxn(() async {
      final model = await _collection.get(id);
      if (model == null) return;
      model.deletedAt = DateTime.now();
      await _collection.put(model);
    });
  }

  Future<void> restoreItem(int id) async {
    await _isarService.db.writeTxn(() async {
      final model = await _collection.get(id);
      if (model == null) return;
      model.deletedAt = null;
      await _collection.put(model);
    });
  }

  // --- Watch ---

  Stream<void> watchLazy() =>
      _isarService.db.collection<ItemModel>().watchLazy();
}
