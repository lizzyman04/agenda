import 'package:agenda/data/finance/budget_model.dart';
import 'package:agenda/data/finance/debt_model.dart' as data;
import 'package:agenda/data/finance/recurring_payment_model.dart' as data;
import 'package:agenda/data/finance/savings_goal_model.dart';
import 'package:agenda/data/finance/transaction_category_model.dart';
import 'package:agenda/data/finance/transaction_model.dart' as data;
import 'package:agenda/domain/finance/budget.dart';
import 'package:agenda/domain/finance/debt.dart';
import 'package:agenda/domain/finance/debt_direction.dart' as domain;
import 'package:agenda/domain/finance/recurring_cycle.dart' as domain;
import 'package:agenda/domain/finance/recurring_payment.dart';
import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:agenda/domain/finance/savings_goal_contribution.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/domain/finance/transaction_category.dart';
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

/// Converts between [SavingsGoalModel] and [SavingsGoal].
///
/// GoalContribution (embedded) maps to SavingsGoalContribution (domain value object).
class GoalMapper {
  const GoalMapper();

  SavingsGoal toDomain(SavingsGoalModel model) {
    return SavingsGoal(
      id: model.id,
      title: model.title,
      targetAmountCents: model.targetAmountCents,
      deadline: model.deadline,
      contributions: model.contributions
          .map(
            (c) => SavingsGoalContribution(
              amountCents: c.amountCents,
              date: c.date,
              note: c.note,
            ),
          )
          .toList(),
      isCompleted: model.isCompleted,
      deletedAt: model.deletedAt,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  SavingsGoalModel toModel(SavingsGoal goal) {
    final model = SavingsGoalModel();

    if (goal.id != 0) {
      model.id = goal.id;
    }

    // CRITICAL: initialize as growable list before populating
    final contributions = List<GoalContribution>.empty(growable: true);
    for (final c in goal.contributions) {
      contributions.add(
        GoalContribution()
          ..amountCents = c.amountCents
          ..date = c.date
          ..note = c.note,
      );
    }

    model
      ..title = goal.title
      ..targetAmountCents = goal.targetAmountCents
      ..deadline = goal.deadline
      ..contributions = contributions
      ..isCompleted = goal.isCompleted
      ..deletedAt = goal.deletedAt
      ..createdAt = goal.createdAt
      ..updatedAt = goal.updatedAt;

    return model;
  }
}

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
