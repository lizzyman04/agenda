import 'package:agenda/data/backup/json/json_fields.dart';
import 'package:agenda/data/finance/debt/debt_model.dart';

/// Encodes a [DebtModel] with explicit keys.
Map<String, Object?> debtToJson(DebtModel m) => {
  'id': m.id,
  'title': m.title,
  'amountCents': m.amountCents,
  'direction': m.direction.name,
  'counterparty': m.counterparty,
  'dueDate': encodeJsonDate(m.dueDate),
  'isPaid': m.isPaid,
  'paidAt': encodeJsonDateOrNull(m.paidAt),
  'deletedAt': encodeJsonDateOrNull(m.deletedAt),
  'createdAt': encodeJsonDate(m.createdAt),
  'updatedAt': encodeJsonDate(m.updatedAt),
};

/// Strictly decodes a [DebtModel], keeping the explicit `id`.
DebtModel debtFromJson(JsonObjectReader r) =>
    DebtModel()
      ..id = r.requireInt('id')
      ..title = r.requireString('title')
      ..amountCents = r.requireInt('amountCents')
      ..direction = r.requireEnum('direction', DebtDirection.values)
      ..counterparty = r.requireString('counterparty')
      ..dueDate = r.requireDate('dueDate')
      ..isPaid = r.requireBool('isPaid')
      ..paidAt = r.optDate('paidAt')
      ..deletedAt = r.optDate('deletedAt')
      ..createdAt = r.requireDate('createdAt')
      ..updatedAt = r.requireDate('updatedAt');
