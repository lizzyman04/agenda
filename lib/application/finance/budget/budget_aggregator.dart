import 'package:agenda/domain/finance/budget.dart';
import 'package:agenda/domain/finance/transaction.dart';

/// Merges [transactions] and [budgets] into a per-category spend/limit map.
///
/// Extracted from `BudgetCubit._reload()` — pure aggregation, no cubit
/// state, no repository access.
///
/// Includes every category id that appears in either the spend or limit
/// data, plus a backfill pass for categories that have a configured budget
/// limit but no transactions this month (spentCents defaults to 0).
Map<int, ({int limitCents, int spentCents})> mergeBudgetData({
  required List<Transaction> transactions,
  required List<Budget> budgets,
}) {
  // Group by categoryId to get spentCents per category
  final spentMap = <int, int>{};
  for (final tx in transactions) {
    spentMap[tx.categoryId] = (spentMap[tx.categoryId] ?? 0) + tx.amountCents;
  }

  // Build limit map from configured budgets
  final limitMap = <int, int>{};
  for (final budget in budgets) {
    limitMap[budget.categoryId] = budget.limitCents;
  }

  // Build combined map: all category ids from both spend and limit maps
  final allCategoryIds = {...spentMap.keys, ...limitMap.keys};
  final combined = <int, ({int limitCents, int spentCents})>{};
  for (final id in allCategoryIds) {
    combined[id] = (
      limitCents: limitMap[id] ?? 0,
      spentCents: spentMap[id] ?? 0,
    );
  }

  // Also include categories with limits but no spend
  for (final budget in budgets) {
    combined[budget.categoryId] ??= (
      limitCents: budget.limitCents,
      spentCents: 0,
    );
  }

  return combined;
}
