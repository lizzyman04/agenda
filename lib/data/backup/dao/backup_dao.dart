import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/budget/budget_model.dart';
import 'package:agenda/data/finance/category/transaction_category_model.dart';
import 'package:agenda/data/finance/debt/debt_model.dart';
import 'package:agenda/data/finance/goal/savings_goal_model.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_model.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:isar_community/isar.dart';

/// Every row of all seven collections, read as one consistent snapshot.
class BackupRows {
  const BackupRows({
    required this.items,
    required this.transactions,
    required this.categories,
    required this.budgets,
    required this.goals,
    required this.debts,
    required this.recurringPayments,
  });

  final List<ItemModel> items;
  final List<TransactionModel> transactions;
  final List<TransactionCategoryModel> categories;
  final List<BudgetModel> budgets;
  final List<SavingsGoalModel> goals;
  final List<DebtModel> debts;
  final List<RecurringPaymentModel> recurringPayments;
}

/// Raw, whole-collection Isar reads used to build a backup.
///
/// Every read here is DELIBERATELY uncapped and unfiltered: a backup must
/// contain every row, including soft-deleted ones, so foreign keys such as
/// `parentId`, `linkedGoalId` and `categoryId` stay valid after a restore.
/// Adding `.limit(...)` or a `deletedAt` filter would silently truncate a
/// user's backup. That is the CR-04 / BL-01 defect class this project has
/// already been burned by twice. Never add either.
class BackupDao {
  const BackupDao(this.isarService);

  /// Public so the import engine can open its own write transaction against
  /// the same database without changing the DI graph.
  final IsarService isarService;

  /// Reads all seven collections inside ONE read transaction, so the export
  /// is a consistent snapshot even if a write lands mid-export.
  Future<BackupRows> readAll() async {
    final isar = isarService.db;
    return isar.txn(
      () async => BackupRows(
        items: await isar.collection<ItemModel>().where().findAll(),
        transactions:
            await isar.collection<TransactionModel>().where().findAll(),
        categories:
            await isar.collection<TransactionCategoryModel>().where().findAll(),
        budgets: await isar.collection<BudgetModel>().where().findAll(),
        goals: await isar.collection<SavingsGoalModel>().where().findAll(),
        debts: await isar.collection<DebtModel>().where().findAll(),
        recurringPayments:
            await isar.collection<RecurringPaymentModel>().where().findAll(),
      ),
    );
  }

  /// Every category row, uncapped. Used while validating a CSV import to
  /// resolve category names without a write transaction.
  Future<List<TransactionCategoryModel>> readCategories() =>
      isarService.db.collection<TransactionCategoryModel>().where().findAll();
}
