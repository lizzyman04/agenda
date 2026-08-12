import 'package:agenda/application/finance/dashboard/dashboard_aggregator.dart';
import 'package:agenda/domain/finance/debt/debt.dart';
import 'package:agenda/domain/finance/debt/debt_direction.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';
import 'package:test/test.dart';

DateTime _d(int y, int m, int day) => DateTime(y, m, day);

Transaction _makeTx({
  int id = 1,
  TransactionType type = TransactionType.income,
  int amountCents = 5000,
  int categoryId = 1,
  DateTime? date,
  DateTime? deletedAt,
  int? linkedGoalId,
}) {
  final txDate = date ?? _d(2026, 1, 10);
  return Transaction(
    id: id,
    type: type,
    amountCents: amountCents,
    categoryId: categoryId,
    date: txDate,
    createdAt: txDate,
    updatedAt: txDate,
    deletedAt: deletedAt,
    linkedGoalId: linkedGoalId,
  );
}

SavingsGoal _makeGoal({int id = 1, int targetCents = 100000}) {
  return SavingsGoal(
    id: id,
    title: 'Emergency Fund',
    targetAmountCents: targetCents,
    contributions: const [],
    isCompleted: false,
    createdAt: _d(2026, 1, 1),
    updatedAt: _d(2026, 1, 1),
  );
}

Debt _makeDebt({
  int id = 1,
  int amountCents = 1500,
  DebtDirection direction = DebtDirection.toPay,
  bool isPaid = false,
}) {
  return Debt(
    id: id,
    title: 'Loan',
    amountCents: amountCents,
    direction: direction,
    counterparty: 'Bank',
    dueDate: _d(2026, 6, 1),
    isPaid: isPaid,
    createdAt: _d(2026, 1, 1),
    updatedAt: _d(2026, 1, 1),
  );
}

void main() {
  group('computeBalance', () {
    test('income minus expense, single pass', () {
      final balance = computeBalance([
        _makeTx(),
        _makeTx(id: 2, amountCents: 3000),
        _makeTx(id: 3, type: TransactionType.expense, amountCents: 2000),
      ]);
      expect(balance, 6000);
    });

    test('empty list yields zero balance', () {
      expect(computeBalance(const []), 0);
    });
  });

  group('computeTaggedByGoal', () {
    test('sums amounts per linkedGoalId, ignores untagged txs', () {
      final tagged = computeTaggedByGoal([
        _makeTx(linkedGoalId: 1, amountCents: 1000),
        _makeTx(id: 2, linkedGoalId: 1, amountCents: 500),
        _makeTx(id: 3, linkedGoalId: 2, amountCents: 200),
        _makeTx(id: 4),
      ]);
      expect(tagged, {1: 1500, 2: 200});
    });
  });

  group('computeGoalsSavedTotal', () {
    test('folds amountSavedCents across all goals', () {
      final total = computeGoalsSavedTotal(
        [_makeGoal()],
        {1: 0},
      );
      expect(total, 0);
    });
  });

  group('computeDebtTotal', () {
    test('sums only toPay && !isPaid debts', () {
      final total = computeDebtTotal([
        _makeDebt(),
        _makeDebt(id: 2, direction: DebtDirection.toReceive, amountCents: 3000),
        _makeDebt(id: 3, isPaid: true, amountCents: 9000),
      ]);
      expect(total, 1500);
    });
  });

  group('computeNetWorth', () {
    test('balance + goalsSaved - debt', () {
      final netWorth = computeNetWorth(
        balanceCents: 6000,
        goalsSavedTotalCents: 0,
        debtTotalCents: 1500,
      );
      expect(netWorth, 4500);
    });
  });

  group('computeCategorySpend', () {
    test('groups expenses by categoryId for the given year/month only', () {
      final spend = computeCategorySpend(
        [
          _makeTx(
            type: TransactionType.expense,
            amountCents: 1000,
            date: _d(2026, 3, 5),
          ),
          _makeTx(
            id: 2,
            type: TransactionType.expense,
            amountCents: 2000,
            categoryId: 2,
            date: _d(2026, 3, 10),
          ),
          _makeTx(
            id: 3,
            type: TransactionType.expense,
            amountCents: 999,
            date: _d(2026, 4, 5),
          ),
        ],
        year: 2026,
        month: 3,
      );
      expect(spend, {1: 1000, 2: 2000});
    });

    test('excludes soft-deleted transactions', () {
      final spend = computeCategorySpend(
        [
          _makeTx(
            type: TransactionType.expense,
            amountCents: 1000,
            date: _d(2026, 3, 5),
            deletedAt: _d(2026, 3, 6),
          ),
        ],
        year: 2026,
        month: 3,
      );
      expect(spend, isEmpty);
    });
  });
}
