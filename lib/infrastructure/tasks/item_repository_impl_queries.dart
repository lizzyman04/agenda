part of 'item_repository_impl.dart';

/// Query-side methods of [ItemRepositoryImpl], applied to that class as a
/// mixin (`with _ItemRepositoryImplQueries`).
///
/// This is a `part of` file within `item_repository_impl.dart`'s library, so
/// the abstract `_dao`/`_mapper` getters below resolve directly to
/// [ItemRepositoryImpl]'s private fields of the same name — no import, no
/// interface change, no separate DI registration. [ItemRepositoryImpl]
/// remains one class implementing [ItemRepository] with all 12 methods,
/// exactly as before the split. See Pattern 4 in 06-RESEARCH.md.
mixin _ItemRepositoryImplQueries {
  ItemDao get _dao;
  ItemMapper get _mapper;

  AsyncResult<List<Item>> getItemsByType(ItemType type) async {
    try {
      final models = await _dao.findByType(_toModelType(type));
      return Success<List<Item>>(models.map(_mapper.toDomain).toList());
    } on Object catch (e) {
      return Err<List<Item>>(DatabaseFailure('getItemsByType failed: $e'));
    }
  }

  AsyncResult<List<Item>> getSubtasks(int projectId) async {
    try {
      final models = await _dao.findSubtasks(projectId);
      return Success<List<Item>>(models.map(_mapper.toDomain).toList());
    } on Object catch (e) {
      return Err<List<Item>>(DatabaseFailure('getSubtasks failed: $e'));
    }
  }

  AsyncResult<List<Item>> searchByTitle(String query) async {
    try {
      // T-02-01: typed .titleContains() — no string interpolation
      final models = await _dao.searchByTitle(query);
      return Success<List<Item>>(models.map(_mapper.toDomain).toList());
    } on Object catch (e) {
      return Err<List<Item>>(DatabaseFailure('searchByTitle failed: $e'));
    }
  }

  AsyncResult<List<Item>> filterItems({
    ItemType? type,
    EisenhowerQuadrant? quadrant,
    String? gtdContext,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
    int? parentId,
    bool showCompleted = false,
  }) async {
    try {
      // Translate quadrant to isUrgent/isImportant booleans
      bool? isUrgent;
      bool? isImportant;
      if (quadrant != null) {
        isUrgent = quadrant == EisenhowerQuadrant.doNow ||
            quadrant == EisenhowerQuadrant.delegate;
        isImportant = quadrant == EisenhowerQuadrant.doNow ||
            quadrant == EisenhowerQuadrant.schedule;
      }

      final models = await _dao.filterItems(
        type: type != null ? _toModelType(type) : null,
        isUrgent: isUrgent,
        isImportant: isImportant,
        gtdContext: gtdContext,
        dueDateFrom: dueDateFrom,
        dueDateTo: dueDateTo,
        parentId: parentId,
        showCompleted: showCompleted,
      );
      return Success<List<Item>>(models.map(_mapper.toDomain).toList());
    } on Object catch (e) {
      return Err<List<Item>>(DatabaseFailure('filterItems failed: $e'));
    }
  }

  AsyncResult<(int, int)> getSubtaskCounts(int projectId) async {
    try {
      final total = await _dao.countSubtasks(projectId);
      final completed = await _dao.countCompletedSubtasks(projectId);
      return Success<(int, int)>((completed, total));
    } on Object catch (e) {
      return Err<(int, int)>(DatabaseFailure('getSubtaskCounts failed: $e'));
    }
  }

  Stream<void> watchChanges() => _dao.watchLazy();

  AsyncResult<List<String>> getDistinctGtdContexts() async {
    try {
      // Use a dedicated DAO method that queries only the gtdContext field
      // instead of loading up to 500 full ItemModel objects into memory.
      final contexts = await _dao.findDistinctGtdContexts();
      return Success<List<String>>(contexts);
    } on Object catch (e) {
      return Err<List<String>>(
        DatabaseFailure('getDistinctGtdContexts failed: $e'),
      );
    }
  }

  // --- Private helpers ---

  model_enums.ItemType _toModelType(ItemType t) => switch (t) {
        ItemType.project => model_enums.ItemType.project,
        ItemType.task => model_enums.ItemType.task,
        ItemType.subtask => model_enums.ItemType.subtask,
      };
}
