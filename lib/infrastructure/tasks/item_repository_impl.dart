import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/tasks/item_dao.dart';
import 'package:agenda/data/tasks/item_mapper.dart';
import 'package:agenda/data/tasks/item_model.dart' as model_enums;
import 'package:agenda/domain/tasks/eisenhower_quadrant.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_repository.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/domain/tasks/recurrence_engine.dart';
import 'package:injectable/injectable.dart';

/// Concrete implementation of [ItemRepository].
///
/// Wraps [ItemDao] in try/catch blocks and maps results to [Result<T>].
/// Never throws — all errors are returned as Err(DatabaseFailure(...)).
@LazySingleton(as: ItemRepository)
class ItemRepositoryImpl implements ItemRepository {
  const ItemRepositoryImpl(this._dao, this._mapper, this._recurrenceEngine);

  final ItemDao _dao;
  final ItemMapper _mapper;

  // Stored for recurring-task completion (Phase 2+).
  // ignore: unused_field
  final RecurrenceEngine _recurrenceEngine;

  @override
  AsyncResult<Item> createItem(Item item) async {
    try {
      // T-02-04: validate parentId points to a project
      if (item.parentId != null) {
        final parentResult = await getItem(item.parentId!);
        final Item parent;
        switch (parentResult) {
          case Err<Item>():
            return parentResult;
          case Success<Item>(:final value):
            parent = value;
        }
        if (parent.type != ItemType.project) {
          return const Err<Item>(
            ValidationFailure(
              'parentId must reference an item of type project',
            ),
          );
        }
      }
      final now = DateTime.now();
      final toSave = item.copyWith(createdAt: now, updatedAt: now);
      final model = _mapper.toModel(toSave);
      final id = await _dao.save(model);
      final saved = await _dao.findById(id);
      return Success<Item>(_mapper.toDomain(saved!));
    } on Object catch (e) {
      return Err<Item>(DatabaseFailure('createItem failed: $e'));
    }
  }

  @override
  AsyncResult<Item> getItem(int id) async {
    try {
      final model = await _dao.findById(id);
      if (model == null) {
        return Err<Item>(DatabaseFailure('Item $id not found'));
      }
      return Success<Item>(_mapper.toDomain(model));
    } on Object catch (e) {
      return Err<Item>(DatabaseFailure('getItem failed: $e'));
    }
  }

  @override
  AsyncResult<List<Item>> getItemsByType(ItemType type) async {
    try {
      final models = await _dao.findByType(_toModelType(type));
      return Success<List<Item>>(models.map(_mapper.toDomain).toList());
    } on Object catch (e) {
      return Err<List<Item>>(DatabaseFailure('getItemsByType failed: $e'));
    }
  }

  @override
  AsyncResult<List<Item>> getSubtasks(int projectId) async {
    try {
      final models = await _dao.findSubtasks(projectId);
      return Success<List<Item>>(models.map(_mapper.toDomain).toList());
    } on Object catch (e) {
      return Err<List<Item>>(DatabaseFailure('getSubtasks failed: $e'));
    }
  }

  @override
  AsyncResult<Item> updateItem(Item item) async {
    try {
      final updated = item.copyWith(updatedAt: DateTime.now());
      final model = _mapper.toModel(updated);
      await _dao.save(model);
      return Success<Item>(updated);
    } on Object catch (e) {
      return Err<Item>(DatabaseFailure('updateItem failed: $e'));
    }
  }

  @override
  AsyncResult<Item> softDelete(int id) async {
    try {
      await _dao.softDelete(id);
      // Read model directly by raw id (bypasses deletedAtIsNull filter) so
      // the result is consistent even if a future refactor adds that filter
      // to findById. Do NOT call getItem() — it may exclude soft-deleted rows.
      final model = await _dao.findById(id);
      if (model == null) {
        return Err<Item>(DatabaseFailure('Item $id not found after softDelete'));
      }
      return Success<Item>(_mapper.toDomain(model));
    } on Object catch (e) {
      return Err<Item>(DatabaseFailure('softDelete failed: $e'));
    }
  }

  @override
  AsyncResult<Item> restoreItem(int id) async {
    try {
      await _dao.restoreItem(id);
      // Read model directly by raw id — same reason as softDelete above.
      final model = await _dao.findById(id);
      if (model == null) {
        return Err<Item>(
          DatabaseFailure('Item $id not found after restoreItem'),
        );
      }
      return Success<Item>(_mapper.toDomain(model));
    } on Object catch (e) {
      return Err<Item>(DatabaseFailure('restoreItem failed: $e'));
    }
  }

  @override
  AsyncResult<List<Item>> searchByTitle(String query) async {
    try {
      // T-02-01: typed .titleContains() — no string interpolation
      final models = await _dao.searchByTitle(query);
      return Success<List<Item>>(models.map(_mapper.toDomain).toList());
    } on Object catch (e) {
      return Err<List<Item>>(DatabaseFailure('searchByTitle failed: $e'));
    }
  }

  @override
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

  @override
  AsyncResult<(int, int)> getSubtaskCounts(int projectId) async {
    try {
      final total = await _dao.countSubtasks(projectId);
      final completed = await _dao.countCompletedSubtasks(projectId);
      return Success<(int, int)>((completed, total));
    } on Object catch (e) {
      return Err<(int, int)>(DatabaseFailure('getSubtaskCounts failed: $e'));
    }
  }

  @override
  Stream<void> watchChanges() => _dao.watchLazy();

  @override
  AsyncResult<List<String>> getDistinctGtdContexts() async {
    try {
      final allResult = await filterItems();
      if (allResult is Err<List<Item>>) {
        return Err<List<String>>(allResult.failure);
      }
      final items = (allResult as Success<List<Item>>).value;
      final contexts = items
          .map((i) => i.gtdContext)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
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
