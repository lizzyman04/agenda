import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:agenda/domain/finance/savings_goal_contribution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 5, 14);

  group('SavingsGoal.amountSavedCents', () {
    test(
      'amountSavedCents = sum of contributions + taggedTransactionsCents',
      () {
        final goal = SavingsGoal(
          id: 1,
          title: 'Vacation',
          targetAmountCents: 50000,
          contributions: [
            SavingsGoalContribution(amountCents: 10000, date: now),
            SavingsGoalContribution(amountCents: 5000, date: now),
          ],
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
        );

        // contributions sum = 15000, taggedTransactionsCents = 3000
        expect(goal.amountSavedCents(3000), equals(18000));
      },
    );
  });

  group('SavingsGoal.progressPercent', () {
    test(
      'progressPercent = amountSavedCents / targetAmountCents',
      () {
        final goal = SavingsGoal(
          id: 2,
          title: 'Car',
          targetAmountCents: 100000,
          contributions: [
            SavingsGoalContribution(amountCents: 30000, date: now),
          ],
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
        );

        // 30000 / 100000 = 0.3
        expect(goal.progressPercent(0), closeTo(0.3, 0.001));
      },
    );

    test(
      'progressPercent returns 0.0 when targetAmountCents == 0',
      () {
        final goal = SavingsGoal(
          id: 3,
          title: 'Empty',
          targetAmountCents: 0,
          contributions: [
            SavingsGoalContribution(amountCents: 1000, date: now),
          ],
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
        );

        expect(goal.progressPercent(0), equals(0.0));
      },
    );

    test(
      'progressPercent can exceed 1.0 (no UI cap in domain)',
      () {
        final goal = SavingsGoal(
          id: 4,
          title: 'Overfunded',
          targetAmountCents: 10000,
          contributions: [
            SavingsGoalContribution(amountCents: 15000, date: now),
          ],
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
        );

        // 15000 / 10000 = 1.5
        expect(goal.progressPercent(0), closeTo(1.5, 0.001));
      },
    );
  });
}
