import 'package:agenda/data/finance/debt/debt_model.dart' as data;
import 'package:agenda/domain/finance/debt/debt.dart';
import 'package:agenda/domain/finance/debt/debt_direction.dart' as domain;

/// Converts between [data.DebtModel] and [Debt].
class DebtMapper {
  const DebtMapper();

  Debt toDomain(data.DebtModel model) {
    return Debt(
      id: model.id,
      title: model.title,
      amountCents: model.amountCents,
      direction: _toDomainDirection(model.direction),
      counterparty: model.counterparty,
      dueDate: model.dueDate,
      isPaid: model.isPaid,
      paidAt: model.paidAt,
      deletedAt: model.deletedAt,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  data.DebtModel toModel(Debt debt) {
    final model = data.DebtModel();

    if (debt.id != 0) {
      model.id = debt.id;
    }

    model
      ..title = debt.title
      ..amountCents = debt.amountCents
      ..direction = _toModelDirection(debt.direction)
      ..counterparty = debt.counterparty
      ..dueDate = debt.dueDate
      ..isPaid = debt.isPaid
      ..paidAt = debt.paidAt
      ..deletedAt = debt.deletedAt
      ..createdAt = debt.createdAt
      ..updatedAt = debt.updatedAt;

    return model;
  }

  // --- Private enum converters ---

  domain.DebtDirection _toDomainDirection(data.DebtDirection d) => switch (d) {
        data.DebtDirection.toPay => domain.DebtDirection.toPay,
        data.DebtDirection.toReceive => domain.DebtDirection.toReceive,
      };

  data.DebtDirection _toModelDirection(domain.DebtDirection d) => switch (d) {
        domain.DebtDirection.toPay => data.DebtDirection.toPay,
        domain.DebtDirection.toReceive => data.DebtDirection.toReceive,
      };
}
