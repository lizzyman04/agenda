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

part 'item_repository_impl_queries.dart';

/// Concrete implementation of [ItemRepository].
///
/// Wraps [ItemDao] in try/catch blocks and maps results to [Result<T>].
/// Never throws — all errors are returned as Err(DatabaseFailure(...)).
///
/// Split across two files via `part`/`part of`: this file holds the CRUD
/// methods, `item_repository_impl_queries.dart` holds the query methods as a
/// mixin (`_ItemRepositoryImplQueries`) applied to this class. Dart has no
/// literal "continue this class body in another file" construct, so the
/// mixin is the mechanism that lets the part file contribute real instance
/// methods satisfying [ItemRepository] while sharing this class's private
/// `_dao`/`_mapper` fields via same-library (`part of`) scope. This remains
/// a single class with a single DI registration — see Pattern 4 in
/// 06-RESEARCH.md.
@LazySingleton(as: ItemRepository)
class ItemRepositoryImpl extends Object
    with _ItemRepositoryImplQueries
    implements ItemRepository {
  const ItemRepositoryImpl(this._dao, this._mapper, this._recurrenceEngine);

  @override
  final ItemDao _dao;
  @override
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
  AsyncResult<Item> updateItem(Item item) async {
    try {
      if (item.type != ItemType.subtask && item.parentId != null) {
        return const Err<Item>(
          ValidationFailure('parentId must be null for type task or project'),
        );
      }
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
        return Err<Item>(
          DatabaseFailure('Item $id not found after softDelete'),
        );
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
}
