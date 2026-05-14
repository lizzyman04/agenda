import 'package:agenda/domain/finance/debt.dart';
import 'package:agenda/domain/finance/debt_direction.dart';
import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:agenda/domain/finance/savings_goal_contribution.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/domain/finance/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Computes the current balance from a list of transactions.
/// balance = sum(income) - sum(expenses)
int computeBalance(List<Transaction> transactions) {
  return transactions.fold(0, (acc, tx) {
    if (tx.type == TransactionType.income) return acc + tx.amountCents;
    return acc - tx.amountCents;
  });
}

/// Computes net worth per D-08 formula.
/// netWorth = balance + Σ(goal.amountSavedCents(0)) - Σ(toPay unpaid debt.amountCents)
int computeNetWorth(
  int balance,
  List<SavingsGoal> goals,
  List<Debt> debts,
) {
  final goalsTotal = goals.fold(
    0,
    (sum, g) => sum + g.amountSavedCents(0),
  );
  final toPayDebts = debts
      .where((d) => d.direction == DebtDirection.toPay && !d.isPaid)
      .fold(0, (sum, d) => sum + d.amountCents);
  return balance + goalsTotal - toPayDebts;
}

void main() {
  final now = DateTime(2026, 5, 14);

  group('Transaction entity', () {
    test(
      'amountCents is stored as int — no double conversion',
      () {
        final tx = Transaction(
          id: 1,
          type: TransactionType.expense,
          amountCents: 12345,
          categoryId: 1,
          date: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(tx.amountCents, equals(12345));
        expect(tx.amountCents, isA<int>());
      },
    );

    test(
      'Transaction with amountCents=0 is constructable at domain level',
      () {
        final tx = Transaction(
          id: 2,
          type: TransactionType.income,
          amountCents: 0,
          categoryId: 1,
          date: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(tx.amountCents, equals(0));
      },
    );
  });

  group('computeBalance', () {
    test(
      'computeBalance([income:5000, income:3000, expense:2000]) == 6000',
      () {
        final transactions = [
          Transaction(
            id: 1,
            type: TransactionType.income,
            amountCents: 5000,
            categoryId: 1,
            date: now,
            createdAt: now,
            updatedAt: now,
          ),
          Transaction(
            id: 2,
            type: TransactionType.income,
            amountCents: 3000,
            categoryId: 1,
            date: now,
            createdAt: now,
            updatedAt: now,
          ),
          Transaction(
            id: 3,
            type: TransactionType.expense,
            amountCents: 2000,
            categoryId: 2,
            date: now,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        expect(computeBalance(transactions), equals(6000));
      },
    );
  });

  group('computeNetWorth', () {
    test(
      'computeNetWorth(balance:6000, goalAmountSaved:2000, toPayDebts:[4000]) == 4000',
      () {
        final goals = [
          SavingsGoal(
            id: 1,
            title: 'Emergency Fund',
            targetAmountCents: 10000,
            contributions: [
              SavingsGoalContribution(
                amountCents: 2000,
                date: now,
              ),
            ],
            isCompleted: false,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final debts = [
          Debt(
            id: 1,
            title: 'Credit card',
            amountCents: 4000,
            direction: DebtDirection.toPay,
            counterparty: 'Bank',
            dueDate: now,
            isPaid: false,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        expect(computeNetWorth(6000, goals, debts), equals(4000));
      },
    );
  });
}
