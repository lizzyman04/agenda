import 'package:agenda/data/backup/import/backup_snapshot.dart';
import 'package:agenda/data/backup/import/csv_category_resolver.dart';
import 'package:agenda/data/backup/json/backup_envelope.dart';
import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/budget/budget_model.dart';
import 'package:agenda/data/finance/category/transaction_category_model.dart';
import 'package:agenda/data/finance/debt/debt_model.dart';
import 'package:agenda/data/finance/goal/savings_goal_model.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_model.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:agenda/domain/backup/backup_entity.dart';
import 'package:agenda/domain/backup/import_preview.dart';
import 'package:isar_community/isar.dart';

/// Replaces database contents with a validated [BackupSnapshot] in ONE write
/// transaction (D-11).
///
/// Works on the collections directly, never through a DAO: every DAO save
/// opens its own write transaction and nesting throws. Exceptions are NOT
/// caught inside the transaction, so Isar aborts it, restores every
/// collection cleared earlier in it, and rethrows.
class BackupImporter {
  const BackupImporter(this._service);

  final IsarService _service;

  /// Clears every collection the snapshot supplies, then writes its rows with
  /// their explicit ids. Returns the rows written per collection key
  /// (see [BackupJsonKeys]).
  Future<Map<String, int>> replace(
    BackupSnapshot snapshot, {
    required DateTime now,
  }) async {
    final isar = _service.db;
    return isar.writeTxn(() async {
      await _resolveCsvCategories(isar, snapshot, now);
      final counts = <String, int>{};
      final categories = snapshot.categories;
      final goals = snapshot.goals;
      final debts = snapshot.debts;
      final items = snapshot.items;
      final transactions = snapshot.transactions;
      final budgets = snapshot.budgets;
      final payments = snapshot.recurringPayments;
      if (categories != null) await isar.transactionCategoryModels.clear();
      if (goals != null) await isar.savingsGoalModels.clear();
      if (debts != null) await isar.debtModels.clear();
      if (items != null) await isar.itemModels.clear();
      if (transactions != null) await isar.transactionModels.clear();
      if (budgets != null) await isar.budgetModels.clear();
      if (payments != null) await isar.recurringPaymentModels.clear();
      if (categories != null) {
        await isar.transactionCategoryModels.putAll(categories);
        counts[BackupJsonKeys.categories] = categories.length;
      }
      if (goals != null) {
        await isar.savingsGoalModels.putAll(goals);
        counts[BackupJsonKeys.goals] = goals.length;
      }
      if (debts != null) {
        await isar.debtModels.putAll(debts);
        counts[BackupJsonKeys.debts] = debts.length;
      }
      if (items != null) {
        await isar.itemModels.putAll(items);
        counts[BackupJsonKeys.items] = items.length;
      }
      if (transactions != null) {
        await isar.transactionModels.putAll(transactions);
        counts[BackupJsonKeys.transactions] = transactions.length;
      }
      if (budgets != null) {
        await isar.budgetModels.putAll(budgets);
        counts[BackupJsonKeys.budgets] = budgets.length;
      }
      if (payments != null) {
        await isar.recurringPaymentModels.putAll(payments);
        counts[BackupJsonKeys.recurringPayments] = payments.length;
      }
      return counts;
    });
  }

  // CSV only: resolves each row's category against the categories as they
  // are NOW (inside the transaction), creates any missing custom categories
  // and rewrites the rows' categoryId. Runs before the replaced collections
  // are written. The snapshot is consumed by the commit, so rewriting its
  // models in place is safe.
  Future<void> _resolveCsvCategories(
    Isar isar,
    BackupSnapshot snapshot,
    DateTime now,
  ) async {
    if (snapshot.source != ImportSource.csv) return;
    final existing = await isar.transactionCategoryModels.where().findAll();
    final resolution = resolveCsvCategories(snapshot, existing, now: now);
    final ids = await isar.transactionCategoryModels.putAll(
      resolution.created,
    );
    int idOf(CategoryRef ref) => ref.id ?? ids[ref.createdIndex!];
    final transactions = snapshot.transactions;
    for (var i = 0; i < resolution.transactions.length; i++) {
      transactions![i].categoryId = idOf(resolution.transactions[i]);
    }
    final budgets = snapshot.budgets;
    for (var i = 0; i < resolution.budgets.length; i++) {
      budgets![i].categoryId = idOf(resolution.budgets[i]);
    }
    final payments = snapshot.recurringPayments;
    for (var i = 0; i < resolution.payments.length; i++) {
      payments![i].categoryId = idOf(resolution.payments[i]);
    }
  }
}

/// [BackupImporter.replace] counts keyed by [BackupEntity].
Map<BackupEntity, int> countsByEntity(Map<String, int> counts) => {
  for (final e in BackupEntity.values)
    if (counts[e.jsonKey] != null) e: counts[e.jsonKey]!,
};
