import 'package:agenda/application/finance/budget/budget_aggregator.dart';
import 'package:agenda/domain/finance/budget.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/domain/finance/transaction_type.dart';
import 'package:test/test.dart';

DateTime _jan2026(int day) => DateTime(2026, 1, day);

Transaction _makeExpense({
  int id = 1,
  int amountCents = 3000,
  int categoryId = 1,
}) {
  return Transaction(
    id: id,
    type: TransactionType.expense,
    amountCents: amountCents,
    categoryId: categoryId,
    date: _jan2026(10),
    createdAt: _jan2026(10),
    updatedAt: _jan2026(10),
  );
}

Budget _makeBudget({int categoryId = 1, int limitCents = 10000}) {
  return Budget(
    id: 1,
    categoryId: categoryId,
    month: 1,
    year: 2026,
    limitCents: limitCents,
    createdAt: _jan2026(1),
    updatedAt: _jan2026(1),
  );
}

void main() {
  group('mergeBudgetData', () {
    test('combines spend and limit for a category present in both', () {
      final combined = mergeBudgetData(
        transactions: [_makeExpense()],
        budgets: [_makeBudget()],
      );
      expect(combined[1]?.spentCents, 3000);
      expect(combined[1]?.limitCents, 10000);
    });

    test('category with a limit but no transactions has spentCents 0', () {
      final combined = mergeBudgetData(
        transactions: const [],
        budgets: [_makeBudget(categoryId: 2, limitCents: 5000)],
      );
      expect(combined[2]?.spentCents, 0);
      expect(combined[2]?.limitCents, 5000);
    });

    test('category with spend but no configured limit has limitCents 0', () {
      final combined = mergeBudgetData(
        transactions: [_makeExpense(categoryId: 3, amountCents: 1200)],
        budgets: const [],
      );
      expect(combined[3]?.spentCents, 1200);
      expect(combined[3]?.limitCents, 0);
    });

    test('empty inputs yield empty map', () {
      final combined = mergeBudgetData(
        transactions: const [],
        budgets: const [],
      );
      expect(combined, isEmpty);
    });
  });
}
