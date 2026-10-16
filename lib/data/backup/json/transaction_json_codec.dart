import 'package:agenda/data/backup/json/json_fields.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';

/// Encodes a [TransactionModel] with explicit keys.
Map<String, Object?> transactionToJson(TransactionModel m) => {
  'id': m.id,
  'type': m.type.name,
  'amountCents': m.amountCents,
  'categoryId': m.categoryId,
  'date': encodeJsonDate(m.date),
  'note': m.note,
  'linkedGoalId': m.linkedGoalId,
  'deletedAt': encodeJsonDateOrNull(m.deletedAt),
  'createdAt': encodeJsonDate(m.createdAt),
  'updatedAt': encodeJsonDate(m.updatedAt),
};

/// Strictly decodes a [TransactionModel], keeping the explicit `id`.
TransactionModel transactionFromJson(JsonObjectReader r) =>
    TransactionModel()
      ..id = r.requireInt('id')
      ..type = r.requireEnum('type', TransactionType.values)
      ..amountCents = r.requireInt('amountCents')
      ..categoryId = r.requireInt('categoryId')
      ..date = r.requireDate('date')
      ..note = r.optString('note')
      ..linkedGoalId = r.optInt('linkedGoalId')
      ..deletedAt = r.optDate('deletedAt')
      ..createdAt = r.requireDate('createdAt')
      ..updatedAt = r.requireDate('updatedAt');
