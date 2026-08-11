import 'package:agenda/data/finance/budget_model.dart';
import 'package:agenda/domain/finance/budget.dart';

/// Converts between [BudgetModel] and [Budget].
class BudgetMapper {
  const BudgetMapper();

  Budget toDomain(BudgetModel model) {
    return Budget(
      id: model.id,
      categoryId: model.categoryId,
      month: model.month,
      year: model.year,
      limitCents: model.limitCents,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  BudgetModel toModel(Budget budget) {
    final model = BudgetModel();

    if (budget.id != 0) {
      model.id = budget.id;
    }

    model
      ..categoryId = budget.categoryId
      ..month = budget.month
      ..year = budget.year
      ..limitCents = budget.limitCents
      ..createdAt = budget.createdAt
      ..updatedAt = budget.updatedAt;

    return model;
  }
}
