import 'package:agenda/data/backup/json/json_fields.dart';
import 'package:agenda/data/finance/category/transaction_category_model.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';

/// Encodes a [TransactionCategoryModel] with explicit keys.
Map<String, Object?> categoryToJson(TransactionCategoryModel m) => {
  'id': m.id,
  'namePtBr': m.namePtBr,
  'nameEn': m.nameEn,
  'type': m.type.name,
  'isDefault': m.isDefault,
  'createdAt': encodeJsonDate(m.createdAt),
};

/// Strictly decodes a [TransactionCategoryModel], keeping the explicit `id`.
TransactionCategoryModel categoryFromJson(JsonObjectReader r) =>
    TransactionCategoryModel()
      ..id = r.requireInt('id')
      ..namePtBr = r.requireString('namePtBr')
      ..nameEn = r.optString('nameEn')
      ..type = r.requireEnum('type', TransactionType.values)
      ..isDefault = r.requireBool('isDefault')
      ..createdAt = r.requireDate('createdAt');
