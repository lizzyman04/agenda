import 'package:agenda/data/finance/savings_goal_model.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:agenda/domain/finance/goal/savings_goal_contribution.dart';

/// Converts between [SavingsGoalModel] and [SavingsGoal].
///
/// GoalContribution (embedded) maps to SavingsGoalContribution (domain
/// value object).
class GoalMapper {
  const GoalMapper();

  SavingsGoal toDomain(SavingsGoalModel model) {
    return SavingsGoal(
      id: model.id,
      title: model.title,
      targetAmountCents: model.targetAmountCents,
      deadline: model.deadline,
      contributions:
          model.contributions
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
