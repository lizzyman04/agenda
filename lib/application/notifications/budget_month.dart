import 'package:agenda/application/finance/budget/budget_aggregator.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/budget/budget.dart';
import 'package:agenda/domain/finance/budget/budget_repository.dart';
import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/category/transaction_category_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';

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
