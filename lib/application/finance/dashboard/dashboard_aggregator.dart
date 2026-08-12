import 'package:agenda/domain/finance/debt/debt.dart';
import 'package:agenda/domain/finance/debt/debt_direction.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';

/// Pure aggregation math for `HomeDashboardCubit`'s dashboard figures.
///
/// Extracted from `HomeDashboardCubit._reload()` — no cubit state, no
/// repository access. Each function is independently unit-testable.

/// Balance: single-pass income/expense sum (D-07).
int computeBalance(List<Transaction> transactions) {
  var income = 0;
  var expenses = 0;
  for (final tx in transactions) {
    if (tx.type == TransactionType.income) {
      income += tx.amountCents;
    } else {
      expenses += tx.amountCents;
    }
  }
  return income - expenses;
}

/// Builds a map of goalId -> taggedTransactionsCents from [transactions] in
/// one pass (avoids a second Isar query per goal — no N+1).
Map<int, int> computeTaggedByGoal(List<Transaction> transactions) {
  final taggedByGoal = <int, int>{};
  for (final tx in transactions) {
    final goalId = tx.linkedGoalId;
    if (goalId != null) {
      taggedByGoal[goalId] = (taggedByGoal[goalId] ?? 0) + tx.amountCents;
    }
  }
  return taggedByGoal;
}

/// Sum of all active goal savings (manual contributions + tagged txs).
int computeGoalsSavedTotal(
  List<SavingsGoal> goals,
  Map<int, int> taggedByGoal,
) {
  return goals.fold(
    0,
    (sum, g) => sum + g.amountSavedCents(taggedByGoal[g.id] ?? 0),
  );
}

/// D-08: only toPay && !isPaid debts are subtracted from net worth.
/// Debts-to-receive (toReceive) are explicitly excluded (T-03-03-01).
int computeDebtTotal(List<Debt> debts) {
  return debts
      .where((d) => d.direction == DebtDirection.toPay && !d.isPaid)
      .fold(0, (sum, d) => sum + d.amountCents);
}

/// D-08 combination formula: net worth = balance + goalsSaved - debt.
int computeNetWorth({
  required int balanceCents,
  required int goalsSavedTotalCents,
  required int debtTotalCents,
}) {
  return balanceCents + goalsSavedTotalCents - debtTotalCents;
}

/// Filters [transactions] to [year]/[month] expenses; groups by categoryId
/// (D-09). Single-pass Dart loop — no additional Isar query (no N+1).
Map<int, int> computeCategorySpend(
  List<Transaction> transactions, {
  required int year,
  required int month,
}) {
  final categorySpend = <int, int>{};
  for (final tx in transactions) {
    if (tx.type == TransactionType.expense &&
        tx.date.year == year &&
        tx.date.month == month &&
        tx.deletedAt == null) {
      categorySpend[tx.categoryId] =
          (categorySpend[tx.categoryId] ?? 0) + tx.amountCents;
    }
  }
  return categorySpend;
}
