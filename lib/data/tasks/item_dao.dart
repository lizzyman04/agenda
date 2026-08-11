import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:agenda/data/tasks/item_query_builder.dart';
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
    return buildItemFilterQuery(
      _collection,
      type: type,
      isUrgent: isUrgent,
      isImportant: isImportant,
      gtdContext: gtdContext,
      dueDateFrom: dueDateFrom,
      dueDateTo: dueDateTo,
      parentId: parentId,
      showCompleted: showCompleted,
    ).limit(500).findAll();
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

  /// Returns a sorted list of distinct, non-null GTD context strings
  /// from all active (non-deleted) items.
  ///
  /// Queries only the gtdContext field — avoids loading full ItemModel
  /// objects for what is logically a projection query.
  Future<List<String>> findDistinctGtdContexts() async {
    final models = await _collection
        .filter()
        .deletedAtIsNull()
        .gtdContextIsNotNull()
        .findAll();
    return models
        .map((m) => m.gtdContext!)
        .toSet()
        .toList()
      ..sort();
  }

  // --- Watch ---

  Stream<void> watchLazy() =>
      _isarService.db.collection<ItemModel>().watchLazy();
}
