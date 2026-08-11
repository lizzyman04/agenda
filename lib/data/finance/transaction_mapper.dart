import 'package:agenda/data/finance/transaction_model.dart' as data;
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/domain/finance/transaction_type.dart' as domain;

/// Converts between [data.TransactionModel] (Isar) and [Transaction] (domain).
class TransactionMapper {
  const TransactionMapper();

  Transaction toDomain(data.TransactionModel model) {
    return Transaction(
      id: model.id,
      type: _toDomainType(model.type),
      amountCents: model.amountCents,
      categoryId: model.categoryId,
      date: model.date,
      note: model.note,
      linkedGoalId: model.linkedGoalId,
      deletedAt: model.deletedAt,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  data.TransactionModel toModel(Transaction tx) {
    final model = data.TransactionModel();

    // autoIncrement guard: only set id for existing records (id != 0).
    // Setting model.id = 0 would overwrite the record with Isar id 0.
    if (tx.id != 0) {
      model.id = tx.id;
    }

    model
      ..type = _toModelType(tx.type)
      ..amountCents = tx.amountCents
      ..categoryId = tx.categoryId
      ..date = tx.date
      ..note = tx.note
      ..linkedGoalId = tx.linkedGoalId
      ..deletedAt = tx.deletedAt
      ..createdAt = tx.createdAt
      ..updatedAt = tx.updatedAt;

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
