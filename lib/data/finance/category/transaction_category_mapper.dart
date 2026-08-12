import 'package:agenda/data/finance/category/transaction_category_model.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart' as data;
import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart'
    as domain;

/// Converts between [TransactionCategoryModel] and [TransactionCategory].
class TransactionCategoryMapper {
  const TransactionCategoryMapper();

  TransactionCategory toDomain(TransactionCategoryModel model) {
    return TransactionCategory(
      id: model.id,
      namePtBr: model.namePtBr,
      nameEn: model.nameEn,
      type: _toDomainType(model.type),
      isDefault: model.isDefault,
      createdAt: model.createdAt,
    );
  }

  TransactionCategoryModel toModel(TransactionCategory category) {
    final model = TransactionCategoryModel();

    if (category.id != 0) {
      model.id = category.id;
    }

    model
      ..namePtBr = category.namePtBr
      ..nameEn = category.nameEn
      ..type = _toModelType(category.type)
      ..isDefault = category.isDefault
      ..createdAt = category.createdAt;

    return model;
  }

  // --- Private enum converters ---

  domain.TransactionType _toDomainType(data.TransactionType t) => switch (t) {
        data.TransactionType.income => domain.TransactionType.income,
        data.TransactionType.expense => domain.TransactionType.expense,
      };

  data.TransactionType _toModelType(domain.TransactionType t) => switch (t) {
        domain.TransactionType.income => data.TransactionType.income,
        domain.TransactionType.expense => data.TransactionType.expense,
      };
}
