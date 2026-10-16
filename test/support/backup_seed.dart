// Shared fixtures for the backup import tests: a small, internally consistent
// data set whose ids start at a caller-chosen base, helpers to write it into
// a real Isar and to turn rows or snapshots into comparable JSON.

import 'package:agenda/data/backup/dao/backup_dao.dart';
import 'package:agenda/data/backup/import/backup_snapshot.dart';
import 'package:agenda/data/backup/json/budget_json_codec.dart';
import 'package:agenda/data/backup/json/category_json_codec.dart';
import 'package:agenda/data/backup/json/debt_json_codec.dart';
import 'package:agenda/data/backup/json/goal_json_codec.dart';
import 'package:agenda/data/backup/json/item_json_codec.dart';
import 'package:agenda/data/backup/json/payment_json_codec.dart';
import 'package:agenda/data/backup/json/transaction_json_codec.dart';
import 'package:agenda/data/finance/budget/budget_model.dart';
import 'package:agenda/data/finance/category/transaction_category_model.dart';
import 'package:agenda/data/finance/debt/debt_model.dart';
import 'package:agenda/data/finance/goal/savings_goal_model.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_model.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:agenda/domain/backup/import_preview.dart';
import 'package:isar_community/isar.dart';

/// All seven schemas, in the order the app opens them.
List<CollectionSchema<dynamic>> backupSchemas() => [
  ItemModelSchema,
  TransactionModelSchema,
  TransactionCategoryModelSchema,
  BudgetModelSchema,
  SavingsGoalModelSchema,
  DebtModelSchema,
  RecurringPaymentModelSchema,
];

final DateTime seedNow = DateTime(2026, 3, 4, 5, 6);

/// A JSON-style snapshot (all seven collections) with ids from [idBase] + 1.
///
/// [tag] is woven into titles so two data sets are distinguishable. Rows
/// reference each other (parent, goal, category) so a restore keeps links.
BackupSnapshot seedSnapshot({int idBase = 100, String tag = 'B'}) {
  final at = seedNow;
  int id(int n) => idBase + n;
  final categories = [
    TransactionCategoryModel()
      ..id = id(1)
      ..namePtBr = 'Mercado $tag'
      ..nameEn = 'Grocery $tag'
      ..type = TransactionType.expense
      ..isDefault = false
      ..createdAt = at,
    TransactionCategoryModel()
      ..id = id(2)
      ..namePtBr = 'Salario $tag'
      ..type = TransactionType.income
      ..createdAt = at,
  ];
  final goals = [
    SavingsGoalModel()
      ..id = id(1)
      ..title = 'Goal $tag'
      ..targetAmountCents = 500000
      ..contributions = [
        GoalContribution()
          ..amountCents = 1000
          ..date = at
          ..note = 'first',
      ]
      ..createdAt = at
      ..updatedAt = at,
  ];
  final debts = [
    DebtModel()
      ..id = id(1)
      ..title = 'Debt $tag'
      ..amountCents = 25000
      ..direction = DebtDirection.toPay
      ..counterparty = 'Someone'
      ..dueDate = at
      ..createdAt = at
      ..updatedAt = at,
  ];
  final items = [
    ItemModel()
      ..id = id(1)
      ..type = ItemType.project
      ..title = 'Project $tag'
      ..createdAt = at
      ..updatedAt = at,
    ItemModel()
      ..id = id(2)
      ..type = ItemType.task
      ..title = 'Task $tag'
      ..parentId = id(1)
      ..linkedGoalId = id(1)
      ..dueDate = at
      ..timeInfo = TimeInfo(dueTimeMinutes: 90)
      ..createdAt = at
      ..updatedAt = at,
  ];
  final transactions = [
    TransactionModel()
      ..id = id(1)
      ..type = TransactionType.expense
      ..amountCents = 1250
      ..categoryId = id(1)
      ..date = at
      ..note = 'note $tag'
      ..linkedGoalId = id(1)
      ..createdAt = at
      ..updatedAt = at,
  ];
  final budgets = [
    BudgetModel()
      ..id = id(1)
      ..categoryId = id(1)
      ..month = 3
      ..year = 2026
      ..limitCents = 90000
      ..createdAt = at
      ..updatedAt = at,
  ];
  final payments = [
    RecurringPaymentModel()
      ..id = id(1)
      ..title = 'Rent $tag'
      ..amountCents = 70000
      ..categoryId = id(1)
      ..cycle = RecurringCycle.monthly
      ..nextDueDate = at
      ..createdAt = at
      ..updatedAt = at,
  ];
  return BackupSnapshot(
    source: ImportSource.json,
    exportedAt: at,
    items: items,
    transactions: transactions,
    categories: categories,
    budgets: budgets,
    goals: goals,
    debts: debts,
    recurringPayments: payments,
  );
}

/// Replaces every collection of [isar] with [s] (test seeding only).
Future<void> seedDatabase(Isar isar, BackupSnapshot s) async {
  await isar.writeTxn(() async {
    await isar.itemModels.clear();
    await isar.transactionModels.clear();
    await isar.transactionCategoryModels.clear();
    await isar.budgetModels.clear();
    await isar.savingsGoalModels.clear();
    await isar.debtModels.clear();
    await isar.recurringPaymentModels.clear();
    await isar.itemModels.putAll(s.items ?? []);
    await isar.transactionModels.putAll(s.transactions ?? []);
    await isar.transactionCategoryModels.putAll(s.categories ?? []);
    await isar.budgetModels.putAll(s.budgets ?? []);
    await isar.savingsGoalModels.putAll(s.goals ?? []);
    await isar.debtModels.putAll(s.debts ?? []);
    await isar.recurringPaymentModels.putAll(s.recurringPayments ?? []);
  });
}

/// Comparable JSON of every collection, keyed by collection name.
Map<String, List<Map<String, Object?>>> rowsJson(BackupRows r) => {
  'items': r.items.map(itemToJson).toList(),
  'transactions': r.transactions.map(transactionToJson).toList(),
  'categories': r.categories.map(categoryToJson).toList(),
  'budgets': r.budgets.map(budgetToJson).toList(),
  'goals': r.goals.map(goalToJson).toList(),
  'debts': r.debts.map(debtToJson).toList(),
  'recurringPayments': r.recurringPayments.map(paymentToJson).toList(),
};

/// Same shape as [rowsJson] for a snapshot; unsupplied collections are empty.
Map<String, List<Map<String, Object?>>> snapshotJson(BackupSnapshot s) =>
    rowsJson(
      BackupRows(
        items: s.items ?? [],
        transactions: s.transactions ?? [],
        categories: s.categories ?? [],
        budgets: s.budgets ?? [],
        goals: s.goals ?? [],
        debts: s.debts ?? [],
        recurringPayments: s.recurringPayments ?? [],
      ),
    );
