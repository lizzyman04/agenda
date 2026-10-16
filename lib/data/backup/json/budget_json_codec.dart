import 'package:agenda/data/backup/json/json_fields.dart';
import 'package:agenda/data/finance/budget/budget_model.dart';

/// Encodes a [BudgetModel] with explicit keys.
Map<String, Object?> budgetToJson(BudgetModel m) => {
  'id': m.id,
  'categoryId': m.categoryId,
  'month': m.month,
  'year': m.year,
  'limitCents': m.limitCents,
  'createdAt': encodeJsonDate(m.createdAt),
  'updatedAt': encodeJsonDate(m.updatedAt),
};

/// Strictly decodes a [BudgetModel], keeping the explicit `id`.
BudgetModel budgetFromJson(JsonObjectReader r) =>
    BudgetModel()
      ..id = r.requireInt('id')
      ..categoryId = r.requireInt('categoryId')
      ..month = r.requireInt('month')
      ..year = r.requireInt('year')
      ..limitCents = r.requireInt('limitCents')
      ..createdAt = r.requireDate('createdAt')
      ..updatedAt = r.requireDate('updatedAt');
