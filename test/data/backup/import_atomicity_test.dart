// Tracer for the import engine (plan 04-11): a snapshot replaces the database
// in one transaction, a failure rolls everything back, and Isar's
// auto-increment survives explicit ids (assumption A4). Real Isar; only
// IsarService is mocked.

import 'dart:math';

import 'package:agenda/data/backup/dao/backup_dao.dart';
import 'package:agenda/data/backup/import/backup_importer.dart';
import 'package:agenda/data/backup/import/backup_snapshot.dart';
import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/budget/budget_model.dart';
import 'package:agenda/data/finance/category/transaction_category_model.dart';
import 'package:agenda/data/finance/debt/debt_model.dart';
import 'package:agenda/data/finance/goal/savings_goal_model.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_model.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:agenda/domain/backup/import_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/backup_seed.dart';
import '../../support/isar_test_harness.dart';

class MockIsarService extends Mock implements IsarService {}

void main() {
  late IsarTestHarness harness;
  late Isar isar;
  late BackupDao dao;
  late BackupImporter importer;

  setUp(() async {
    harness = IsarTestHarness();
    isar = await harness.open(backupSchemas());
    final service = MockIsarService();
    when(() => service.db).thenReturn(isar);
    dao = BackupDao(service);
    importer = BackupImporter(service);
  });

  tearDown(() async {
    await harness.close();
  });

  group('BackupImporter.replace', () {
    test('replaces every collection, preserving explicit ids', () async {
      await seedDatabase(isar, seedSnapshot(idBase: 0, tag: 'A'));
      final incoming = seedSnapshot();

      final counts = await importer.replace(incoming, now: seedNow);

      expect(rowsJson(await dao.readAll()), snapshotJson(incoming));
      expect(counts['items'], 2);
      expect(counts['categories'], 2);
      expect(counts['budgets'], 1);
    });

    test('auto-increment passes every imported id (assumption A4)', () async {
      final incoming = seedSnapshot();
      await importer.replace(incoming, now: seedNow);
      final before = rowsJson(await dao.readAll());
      final incomingMax = {
        for (final e in snapshotJson(incoming).entries)
          e.key: e.value.map((r) => r['id']! as int).reduce(max),
      };

      final ids = <String, int>{};
      await isar.writeTxn(() async {
        ids['items'] = await isar.itemModels.put(
          ItemModel()
            ..type = ItemType.task
            ..title = 'new'
            ..createdAt = seedNow
            ..updatedAt = seedNow,
        );
        ids['transactions'] = await isar.transactionModels.put(
          TransactionModel()
            ..type = TransactionType.income
            ..amountCents = 1
            ..categoryId = 102
            ..date = seedNow
            ..createdAt = seedNow
            ..updatedAt = seedNow,
        );
        ids['categories'] = await isar.transactionCategoryModels.put(
          TransactionCategoryModel()
            ..namePtBr = 'novo'
            ..type = TransactionType.expense
            ..createdAt = seedNow,
        );
        ids['budgets'] = await isar.budgetModels.put(
          BudgetModel()
            ..categoryId = 101
            ..month = 4
            ..year = 2026
            ..limitCents = 1
            ..createdAt = seedNow
            ..updatedAt = seedNow,
        );
        ids['goals'] = await isar.savingsGoalModels.put(
          SavingsGoalModel()
            ..title = 'new'
            ..targetAmountCents = 1
            ..createdAt = seedNow
            ..updatedAt = seedNow,
        );
        ids['debts'] = await isar.debtModels.put(
          DebtModel()
            ..title = 'new'
            ..amountCents = 1
            ..direction = DebtDirection.toReceive
            ..counterparty = 'x'
            ..dueDate = seedNow
            ..createdAt = seedNow
            ..updatedAt = seedNow,
        );
        ids['recurringPayments'] = await isar.recurringPaymentModels.put(
          RecurringPaymentModel()
            ..title = 'new'
            ..amountCents = 1
            ..categoryId = 101
            ..cycle = RecurringCycle.weekly
            ..nextDueDate = seedNow
            ..createdAt = seedNow
            ..updatedAt = seedNow,
        );
      });

      // Highest imported id per collection (seedSnapshot: idBase 100).
      final maxImported = incomingMax;
      for (final entry in ids.entries) {
        expect(
          entry.value,
          greaterThan(maxImported[entry.key]!),
          reason: entry.key,
        );
      }
      final after = rowsJson(await dao.readAll());
      for (final key in before.keys) {
        // Every imported row is still present and unchanged.
        expect(after[key]!.take(before[key]!.length), before[key]);
        expect(after[key]!.length, before[key]!.length + 1, reason: key);
      }
    });

    test('a failure after the clears restores every collection', () async {
      final original = seedSnapshot(idBase: 0, tag: 'A');
      await seedDatabase(isar, original);
      final before = rowsJson(await dao.readAll());

      final bad = seedSnapshot();
      // Same (month, year, categoryId) twice: the unique index throws on the
      // second put, after every collection has already been cleared.
      bad.budgets!.add(
        BudgetModel()
          ..id = 150
          ..categoryId = bad.budgets!.first.categoryId
          ..month = bad.budgets!.first.month
          ..year = bad.budgets!.first.year
          ..limitCents = 5
          ..createdAt = seedNow
          ..updatedAt = seedNow,
      );

      await expectLater(importer.replace(bad, now: seedNow), throwsA(anything));

      expect(rowsJson(await dao.readAll()), before);
    });

    test('a partial snapshot replaces only the supplied collection', () async {
      await seedDatabase(isar, seedSnapshot(idBase: 0, tag: 'A'));
      final before = rowsJson(await dao.readAll());
      final replacement = seedSnapshot(idBase: 500, tag: 'G');
      final partial = BackupSnapshot(
        source: ImportSource.csv,
        goals: replacement.goals,
      );

      await importer.replace(partial, now: seedNow);

      final after = rowsJson(await dao.readAll());
      expect(after['goals'], snapshotJson(replacement)['goals']);
      for (final key in before.keys.where((k) => k != 'goals')) {
        expect(after[key], before[key], reason: key);
      }
    });
  });
}
