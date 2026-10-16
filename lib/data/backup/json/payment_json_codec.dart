import 'package:agenda/data/backup/json/json_fields.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_model.dart';

/// Encodes a [RecurringPaymentModel] with explicit keys.
Map<String, Object?> paymentToJson(RecurringPaymentModel m) => {
  'id': m.id,
  'title': m.title,
  'amountCents': m.amountCents,
  'categoryId': m.categoryId,
  'cycle': m.cycle.name,
  'nextDueDate': encodeJsonDate(m.nextDueDate),
  'isActive': m.isActive,
  'deletedAt': encodeJsonDateOrNull(m.deletedAt),
  'createdAt': encodeJsonDate(m.createdAt),
  'updatedAt': encodeJsonDate(m.updatedAt),
};

/// Strictly decodes a [RecurringPaymentModel], keeping the explicit `id`.
RecurringPaymentModel paymentFromJson(JsonObjectReader r) =>
    RecurringPaymentModel()
      ..id = r.requireInt('id')
      ..title = r.requireString('title')
      ..amountCents = r.requireInt('amountCents')
      ..categoryId = r.requireInt('categoryId')
      ..cycle = r.requireEnum('cycle', RecurringCycle.values)
      ..nextDueDate = r.requireDate('nextDueDate')
      ..isActive = r.requireBool('isActive')
      ..deletedAt = r.optDate('deletedAt')
      ..createdAt = r.requireDate('createdAt')
      ..updatedAt = r.requireDate('updatedAt');
