import 'package:agenda/data/finance/budget/budget_model.dart';
import 'package:agenda/data/finance/category/transaction_category_model.dart';
import 'package:agenda/data/finance/debt/debt_model.dart';
import 'package:agenda/data/finance/goal/savings_goal_model.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_model.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:agenda/domain/backup/import_preview.dart';

/// Fully decoded contents of an import, held in memory until it is committed.
///
/// A null list means that collection was NOT supplied and must not be touched
/// by the import. A JSON snapshot supplies all seven; a CSV snapshot supplies
/// only the entities for which a file was given.
final class BackupSnapshot {
  const BackupSnapshot({
    required this.source,
    this.items,
    this.transactions,
    this.categories,
    this.budgets,
    this.goals,
    this.debts,
    this.recurringPayments,
    this.exportedAt,
    this.transactionCategoryNames,
    this.budgetCategoryNames,
    this.paymentCategoryNames,
  });

  final ImportSource source;
  final DateTime? exportedAt;
  final List<ItemModel>? items;
  final List<TransactionModel>? transactions;
  final List<TransactionCategoryModel>? categories;
  final List<BudgetModel>? budgets;
  final List<SavingsGoalModel>? goals;
  final List<DebtModel>? debts;
  final List<RecurringPaymentModel>? recurringPayments;

  /// CSV only: category display names aligned by index with the model list.
  final List<String?>? transactionCategoryNames;
  final List<String?>? budgetCategoryNames;
  final List<String?>? paymentCategoryNames;
}

/// A rejected import. [code] is one of the `ImportErrorCode` constants and
/// [detail] names the row or path (never the content of a cell).
final class BackupImportException implements Exception {
  const BackupImportException(this.code, this.detail);

  final String code;
  final String detail;

  @override
  String toString() => '$code: $detail';
}
