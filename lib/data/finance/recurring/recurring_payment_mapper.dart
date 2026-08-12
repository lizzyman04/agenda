import 'package:agenda/data/finance/recurring/recurring_payment_model.dart' as data;
import 'package:agenda/domain/finance/recurring/recurring_cycle.dart' as domain;
import 'package:agenda/domain/finance/recurring/recurring_payment.dart';

/// Converts between [data.RecurringPaymentModel] and [RecurringPayment].
class RecurringPaymentMapper {
  const RecurringPaymentMapper();

  RecurringPayment toDomain(data.RecurringPaymentModel model) {
    return RecurringPayment(
      id: model.id,
      title: model.title,
      amountCents: model.amountCents,
      categoryId: model.categoryId,
      cycle: _toDomainCycle(model.cycle),
      nextDueDate: model.nextDueDate,
      isActive: model.isActive,
      deletedAt: model.deletedAt,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  data.RecurringPaymentModel toModel(RecurringPayment payment) {
    final model = data.RecurringPaymentModel();

    if (payment.id != 0) {
      model.id = payment.id;
    }

    model
      ..title = payment.title
      ..amountCents = payment.amountCents
      ..categoryId = payment.categoryId
      ..cycle = _toModelCycle(payment.cycle)
      ..nextDueDate = payment.nextDueDate
      ..isActive = payment.isActive
      ..deletedAt = payment.deletedAt
      ..createdAt = payment.createdAt
      ..updatedAt = payment.updatedAt;

    return model;
  }

  // --- Private enum converters ---

  domain.RecurringCycle _toDomainCycle(data.RecurringCycle c) => switch (c) {
        data.RecurringCycle.daily => domain.RecurringCycle.daily,
        data.RecurringCycle.weekly => domain.RecurringCycle.weekly,
        data.RecurringCycle.biweekly => domain.RecurringCycle.biweekly,
        data.RecurringCycle.monthly => domain.RecurringCycle.monthly,
        data.RecurringCycle.quarterly => domain.RecurringCycle.quarterly,
        data.RecurringCycle.yearly => domain.RecurringCycle.yearly,
      };

  data.RecurringCycle _toModelCycle(domain.RecurringCycle c) => switch (c) {
        domain.RecurringCycle.daily => data.RecurringCycle.daily,
        domain.RecurringCycle.weekly => data.RecurringCycle.weekly,
        domain.RecurringCycle.biweekly => data.RecurringCycle.biweekly,
        domain.RecurringCycle.monthly => data.RecurringCycle.monthly,
        domain.RecurringCycle.quarterly => data.RecurringCycle.quarterly,
        domain.RecurringCycle.yearly => data.RecurringCycle.yearly,
      };
}
