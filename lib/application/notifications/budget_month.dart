import 'package:agenda/application/finance/budget/budget_aggregator.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/budget/budget.dart';
import 'package:agenda/domain/finance/budget/budget_repository.dart';
import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/category/transaction_category_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';
import 'package:agenda/domain/notifications/planning/budget_threshold.dart';

/// One calendar month of budget data: spend and limit per category id, and
/// the display name of each expense category.
typedef BudgetMonth =
    ({
      Map<int, ({int limitCents, int spentCents})> spend,
      Map<int, String> names,
    });

/// Reads [month]/[year] from the three repositories.
///
/// Returns null when any read fails, so the caller can leave its state
/// alone instead of acting on partial data. [english] picks `nameEn` where
/// a category has one.
Future<BudgetMonth?> loadBudgetMonth({
  required TransactionRepository transactions,
  required BudgetRepository budgets,
  required TransactionCategoryRepository categories,
  required int month,
  required int year,
  required bool english,
}) async {
  final spent = await transactions.getByMonth(month, year);
  final limits = await budgets.getForMonth(month, year);
  final named = await categories.getByType(TransactionType.expense);
  if (spent is! Success<List<Transaction>> ||
      limits is! Success<List<Budget>> ||
      named is! Success<List<TransactionCategory>>) {
    return null;
  }
  return (
    spend: mergeBudgetData(
      transactions: spent.value,
      budgets: limits.value,
    ),
    names: {
      for (final c in named.value)
        c.id: english ? (c.nameEn ?? c.namePtBr) : c.namePtBr,
    },
  );
}

/// The highest threshold (80 or 100) each category has reached this month.
/// Categories below 80% or without a positive limit are left out.
Map<int, int> crossedThresholds(BudgetMonth month) => {
  for (final MapEntry(key: id, value: line) in month.spend.entries)
    if (crossedBudgetThreshold(
          spentCents: line.spentCents,
          limitCents: line.limitCents,
        )
        case final threshold?)
      id: threshold,
};

/// Every alert key for a threshold [month] has already crossed in
/// [year]/[monthNumber]: the 80 key, and the 100 key too when 100 is crossed.
///
/// Used to seed the marker store silently, so existing overspend never
/// raises an alert.
Set<String> crossedBudgetKeys(BudgetMonth month, int year, int monthNumber) => {
  for (final MapEntry(key: id, value: threshold)
      in crossedThresholds(month).entries)
    ...newBudgetKeys(
      existing: const {},
      year: year,
      month: monthNumber,
      categoryId: id,
      threshold: threshold,
    ),
};
