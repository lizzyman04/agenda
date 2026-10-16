import 'package:agenda/data/backup/json/json_fields.dart';
import 'package:agenda/data/tasks/item_model.dart';

/// Encodes an [ItemModel] with explicit keys, independent of Isar internals.
Map<String, Object?> itemToJson(ItemModel m) => {
      'id': m.id,
      'type': m.type.name,
      'parentId': m.parentId,
      'title': m.title,
      'description': m.description,
      'priority': m.priority.name,
      'isUrgent': m.isUrgent,
      'isImportant': m.isImportant,
      'sizeCategory': m.sizeCategory.name,
      'isNextAction': m.isNextAction,
      'gtdContext': m.gtdContext,
      'waitingFor': m.waitingFor,
      'isCompleted': m.isCompleted,
      'completedAt': encodeJsonDateOrNull(m.completedAt),
      'deletedAt': encodeJsonDateOrNull(m.deletedAt),
      'dueDate': encodeJsonDateOrNull(m.dueDate),
      'timeInfo': _timeInfoToJson(m.timeInfo),
      'moneyInfo': _moneyInfoToJson(m.moneyInfo),
      'linkedGoalId': m.linkedGoalId,
      'linkedDebtId': m.linkedDebtId,
      'createdAt': encodeJsonDate(m.createdAt),
      'updatedAt': encodeJsonDate(m.updatedAt),
    };

/// Strictly decodes an [ItemModel], keeping the explicit `id`.
ItemModel itemFromJson(JsonObjectReader r) {
  final time = r.optObject('timeInfo');
  final money = r.optObject('moneyInfo');
  return ItemModel()
    ..id = r.requireInt('id')
    ..type = r.requireEnum('type', ItemType.values)
    ..parentId = r.optInt('parentId')
    ..title = r.requireString('title')
    ..description = r.optString('description')
    ..priority = r.requireEnum('priority', Priority.values)
    ..isUrgent = r.requireBool('isUrgent')
    ..isImportant = r.requireBool('isImportant')
    ..sizeCategory = r.requireEnum('sizeCategory', SizeCategory.values)
    ..isNextAction = r.requireBool('isNextAction')
    ..gtdContext = r.optString('gtdContext')
    ..waitingFor = r.optString('waitingFor')
    ..isCompleted = r.requireBool('isCompleted')
    ..completedAt = r.optDate('completedAt')
    ..deletedAt = r.optDate('deletedAt')
    ..dueDate = r.optDate('dueDate')
    ..timeInfo = time == null
        ? null
        : TimeInfo(
            dueTimeMinutes: time.optInt('dueTimeMinutes'),
            recurrenceRule: time.optString('recurrenceRule'),
          )
    ..moneyInfo = money == null
        ? null
        : MoneyInfo(
            amount: money.optDouble('amount'),
            currencyCode: money.optString('currencyCode'),
          )
    ..linkedGoalId = r.optInt('linkedGoalId')
    ..linkedDebtId = r.optInt('linkedDebtId')
    ..createdAt = r.requireDate('createdAt')
    ..updatedAt = r.requireDate('updatedAt');
}

Map<String, Object?>? _timeInfoToJson(TimeInfo? t) => t == null
    ? null
    : {
        'dueTimeMinutes': t.dueTimeMinutes,
        'recurrenceRule': t.recurrenceRule,
      };

Map<String, Object?>? _moneyInfoToJson(MoneyInfo? m) => m == null
    ? null
    : {'amount': m.amount, 'currencyCode': m.currencyCode};
