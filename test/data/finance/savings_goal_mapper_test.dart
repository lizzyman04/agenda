import 'package:agenda/data/finance/debt_mapper.dart';
import 'package:agenda/data/finance/debt_model.dart' as data;
import 'package:agenda/data/finance/goal_mapper.dart';
import 'package:agenda/data/finance/savings_goal_model.dart';
import 'package:agenda/domain/finance/debt_direction.dart' as domain;
import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:agenda/domain/finance/savings_goal_contribution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 5, 14, 12);

  group('GoalMapper.toDomain', () {
    const mapper = GoalMapper();

    test('produces SavingsGoal with contributions.length == 2', () {
      final c1 = GoalContribution()
        ..amountCents = 1000
        ..date = now;
      final c2 = GoalContribution()
        ..amountCents = 2000
        ..date = now;

      final model = SavingsGoalModel()
        ..id = 1
        ..title = 'Emergency Fund'
        ..targetAmountCents = 100000
        ..contributions = [c1, c2]
        ..isCompleted = false
        ..createdAt = now
        ..updatedAt = now;

      final goal = mapper.toDomain(model);

      expect(goal.contributions.length, equals(2));
    });

    test('maps contribution amountCents and note correctly', () {
      final c1 = GoalContribution()
        ..amountCents = 5000
        ..date = now
        ..note = 'First contribution';

      final model = SavingsGoalModel()
        ..id = 2
        ..title = 'Vacation'
        ..targetAmountCents = 50000
        ..contributions = [c1]
        ..isCompleted = false
        ..createdAt = now
        ..updatedAt = now;

      final goal = mapper.toDomain(model);

      expect(goal.contributions.first.amountCents, equals(5000));
      expect(goal.contributions.first.note, equals('First contribution'));
    });
  });

  group('GoalMapper.toModel', () {
    const mapper = GoalMapper();

    test('contributions list initialized as growable (can add without error)',
        () {
      final goal = SavingsGoal(
        id: 0,
        title: 'New Car',
        targetAmountCents: 500000,
        contributions: const [],
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );

      final model = mapper.toModel(goal);

      // List.empty(growable: true) — must not throw when element added
      expect(
        () => model.contributions.add(
          GoalContribution()
            ..amountCents = 100
            ..date = now,
        ),
        returnsNormally,
      );
    });

    test('maps 2 domain contributions to 2 model contributions', () {
      final goal = SavingsGoal(
        id: 3,
        title: 'House',
        targetAmountCents: 1000000,
        contributions: [
          SavingsGoalContribution(
            amountCents: 10000,
            date: DateTime(2026),
          ),
          SavingsGoalContribution(
            amountCents: 20000,
            date: DateTime(2026, 2),
          ),
        ],
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );

      final model = mapper.toModel(goal);

      expect(model.contributions.length, equals(2));
      expect(model.contributions[0].amountCents, equals(10000));
      expect(model.contributions[1].amountCents, equals(20000));
    });
  });

  group('DebtMapper round-trip', () {
    const mapper = DebtMapper();

    test('DebtDirection.toPay round-trips through DebtMapper', () {
      final debtModel = data.DebtModel()
        ..id = 1
        ..title = 'Rent'
        ..amountCents = 50000
        ..direction = data.DebtDirection.toPay
        ..counterparty = 'Landlord'
        ..dueDate = now
        ..isPaid = false
        ..createdAt = now
        ..updatedAt = now;

      final debt = mapper.toDomain(debtModel);
      expect(debt.direction, equals(domain.DebtDirection.toPay));
    });

    test('DebtDirection.toReceive round-trips through DebtMapper', () {
      final debtModel = data.DebtModel()
        ..id = 2
        ..title = 'Loan'
        ..amountCents = 100000
        ..direction = data.DebtDirection.toReceive
        ..counterparty = 'Friend'
        ..dueDate = now
        ..isPaid = false
        ..createdAt = now
        ..updatedAt = now;

      final debt = mapper.toDomain(debtModel);
      expect(debt.direction, equals(domain.DebtDirection.toReceive));
    });
  });
}
