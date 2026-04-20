import 'package:agenda/data/tasks/item_model.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart' as domain;
import 'package:agenda/domain/tasks/priority.dart' as domain;
import 'package:agenda/domain/tasks/size_category.dart' as domain;
import 'package:isar_community/isar.dart';

/// Converts between [ItemModel] (data layer) and [Item] (domain layer).
///
/// The mapper is the only place where data enums are mapped to domain enums.
/// EisenhowerQuadrant is computed by the domain Item getter — not stored.
class ItemMapper {
  const ItemMapper();

  /// Converts an Isar [ItemModel] to a domain [Item].
  Item toDomain(ItemModel model) {
    return Item(
      id: model.id,
      type: _toDomainType(model.type),
      title: model.title,
      description: model.description,
      parentId: model.parentId,
      priority: _toDomainPriority(model.priority),
      isUrgent: model.isUrgent,
      isImportant: model.isImportant,
      sizeCategory: _toDomainSizeCategory(model.sizeCategory),
      isNextAction: model.isNextAction,
      gtdContext: model.gtdContext,
      waitingFor: model.waitingFor,
      dueDate: model.dueDate,
      dueTimeMinutes: model.timeInfo?.dueTimeMinutes,
      recurrenceRule: model.timeInfo?.recurrenceRule,
      isCompleted: model.isCompleted,
      completedAt: model.completedAt,
      deletedAt: model.deletedAt,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      amount: model.moneyInfo?.amount,
      currencyCode: model.moneyInfo?.currencyCode,
      linkedGoalId: model.linkedGoalId,
      linkedDebtId: model.linkedDebtId,
    );
  }

  /// Converts a domain [Item] to an [ItemModel] for Isar storage.
  ///
  /// When [item.id] is 0 the model id is left at [Isar.autoIncrement] so that
  /// Isar assigns a new unique id on the next write transaction. Setting it to
  /// 0 explicitly would make every new item overwrite the same record (id=0).
  ItemModel toModel(Item item) {
    final model = ItemModel();

    // Only set the id for existing records. For new items (id == 0) leave the
    // Isar.autoIncrement sentinel so Isar auto-assigns the next available id.
    if (item.id != 0) {
      model.id = item.id;
    }

    model
      ..type = _toModelType(item.type)
      ..title = item.title
      ..description = item.description
      ..parentId = item.parentId
      ..priority = _toModelPriority(item.priority)
      ..isUrgent = item.isUrgent
      ..isImportant = item.isImportant
      ..sizeCategory = _toModelSizeCategory(item.sizeCategory)
      ..isNextAction = item.isNextAction
      ..gtdContext = item.gtdContext
      ..waitingFor = item.waitingFor
      ..dueDate = item.dueDate
      ..isCompleted = item.isCompleted
      ..completedAt = item.completedAt
      ..deletedAt = item.deletedAt
      ..createdAt = item.createdAt
      ..updatedAt = item.updatedAt
      ..linkedGoalId = item.linkedGoalId
      ..linkedDebtId = item.linkedDebtId;

    // Time info — only create if there is data to store
    if (item.dueTimeMinutes != null || item.recurrenceRule != null) {
      model.timeInfo = TimeInfo(
        dueTimeMinutes: item.dueTimeMinutes,
        recurrenceRule: item.recurrenceRule,
      );
    }

    // Money info — only create if there is data to store
    if (item.amount != null || item.currencyCode != null) {
      model.moneyInfo = MoneyInfo(
        amount: item.amount,
        currencyCode: item.currencyCode,
      );
    }

    return model;
  }

  // --- Private enum converters ---

  domain.ItemType _toDomainType(ItemType t) => switch (t) {
        ItemType.project => domain.ItemType.project,
        ItemType.task => domain.ItemType.task,
        ItemType.subtask => domain.ItemType.subtask,
      };

  ItemType _toModelType(domain.ItemType t) => switch (t) {
        domain.ItemType.project => ItemType.project,
        domain.ItemType.task => ItemType.task,
        domain.ItemType.subtask => ItemType.subtask,
      };

  domain.Priority _toDomainPriority(Priority p) => switch (p) {
        Priority.low => domain.Priority.low,
        Priority.medium => domain.Priority.medium,
        Priority.high => domain.Priority.high,
        Priority.critical => domain.Priority.critical,
        Priority.urgent => domain.Priority.urgent,
      };

  Priority _toModelPriority(domain.Priority p) => switch (p) {
        domain.Priority.low => Priority.low,
        domain.Priority.medium => Priority.medium,
        domain.Priority.high => Priority.high,
        domain.Priority.critical => Priority.critical,
        domain.Priority.urgent => Priority.urgent,
      };

  domain.SizeCategory _toDomainSizeCategory(SizeCategory s) => switch (s) {
        SizeCategory.big => domain.SizeCategory.big,
        SizeCategory.medium => domain.SizeCategory.medium,
        SizeCategory.small => domain.SizeCategory.small,
        SizeCategory.none => domain.SizeCategory.none,
      };

  SizeCategory _toModelSizeCategory(domain.SizeCategory s) => switch (s) {
        domain.SizeCategory.big => SizeCategory.big,
        domain.SizeCategory.medium => SizeCategory.medium,
        domain.SizeCategory.small => SizeCategory.small,
        domain.SizeCategory.none => SizeCategory.none,
      };
}
