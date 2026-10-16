// validateSnapshot and buildImportPreview (plan 04-11).

import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/data/backup/import/backup_snapshot.dart';
import 'package:agenda/data/backup/import/import_preview_builder.dart';
import 'package:agenda/data/backup/import/snapshot_validator.dart';
import 'package:agenda/data/backup/json/backup_envelope.dart';
import 'package:agenda/data/finance/budget/budget_model.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:agenda/domain/backup/backup_entity.dart';
import 'package:agenda/domain/backup/import_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../support/backup_seed.dart';

ItemModel item(int id, {DateTime? deletedAt, DateTime? createdAt}) =>
    ItemModel()
      ..id = id
      ..type = ItemType.task
      ..title = 'T$id'
      ..deletedAt = deletedAt
      ..createdAt = createdAt ?? seedNow
      ..updatedAt = seedNow;

BudgetModel budget(int id, int month, int category) =>
    BudgetModel()
      ..id = id
      ..categoryId = category
      ..month = month
      ..year = 2026
      ..limitCents = 100
      ..createdAt = seedNow
      ..updatedAt = seedNow;

void main() {
  group('validateSnapshot', () {
    test('a consistent snapshot has no errors, links or deletions', () {
      final report = validateSnapshot(seedSnapshot());
      expect(report.errors, isEmpty);
      expect(report.danglingLinks, 0);
      expect(report.softDeleted, 0);
    });

    test('duplicate explicit ids are errors, auto-increment ids are not', () {
      final dup = BackupSnapshot(
        source: ImportSource.json,
        items: [item(1), item(1)],
      );
      expect(validateSnapshot(dup).errors, isNotEmpty);

      final fresh = BackupSnapshot(
        source: ImportSource.csv,
        items: [item(Isar.autoIncrement), item(Isar.autoIncrement)],
      );
      expect(validateSnapshot(fresh).errors, isEmpty);
    });

    test('a repeated budget key and a bad month are errors', () {
      final repeated = BackupSnapshot(
        source: ImportSource.json,
        budgets: [budget(1, 3, 5), budget(2, 3, 5)],
      );
      expect(validateSnapshot(repeated).errors, isNotEmpty);

      final distinct = BackupSnapshot(
        source: ImportSource.json,
        budgets: [budget(1, 3, 5), budget(2, 4, 5), budget(3, 3, 6)],
      );
      expect(validateSnapshot(distinct).errors, isEmpty);

      final month13 = BackupSnapshot(
        source: ImportSource.json,
        budgets: [budget(1, 13, 5)],
      );
      expect(validateSnapshot(month13).errors, isNotEmpty);
    });

    test('unresolved CSV budgets are keyed by category name', () {
      BackupSnapshot csv(List<String?> names) => BackupSnapshot(
        source: ImportSource.csv,
        budgets: [budget(1, 3, 0), budget(2, 3, 0)],
        budgetCategoryNames: names,
      );
      expect(validateSnapshot(csv(['Food', 'Rent'])).errors, isEmpty);
      expect(validateSnapshot(csv(['Food', ' food '])).errors, isNotEmpty);
    });

    test('dueTimeMinutes outside 0..1439 is an error', () {
      for (final minutes in [-1, 1440]) {
        final s = BackupSnapshot(
          source: ImportSource.json,
          items: [item(1)..timeInfo = TimeInfo(dueTimeMinutes: minutes)],
        );
        expect(validateSnapshot(s).errors, isNotEmpty, reason: '$minutes');
      }
      final ok = BackupSnapshot(
        source: ImportSource.json,
        items: [item(1)..timeInfo = TimeInfo(dueTimeMinutes: 1439)],
      );
      expect(validateSnapshot(ok).errors, isEmpty);
    });

    test('negative cents are errors in every money field', () {
      const fresh = seedSnapshot;
      final cases = <String, BackupSnapshot Function()>{
        'transaction': () => fresh()..transactions!.single.amountCents = -1,
        'budget': () => fresh()..budgets!.single.limitCents = -1,
        'goal': () => fresh()..goals!.single.targetAmountCents = -1,
        'contribution':
            () => fresh()..goals!.single.contributions.first.amountCents = -1,
        'debt': () => fresh()..debts!.single.amountCents = -1,
        'payment': () => fresh()..recurringPayments!.single.amountCents = -1,
      };
      for (final entry in cases.entries) {
        expect(
          validateSnapshot(entry.value()).errors,
          isNotEmpty,
          reason: entry.key,
        );
      }
    });

    test('the per-collection row cap is a parameter', () {
      final s = BackupSnapshot(
        source: ImportSource.json,
        items: [item(1), item(2)],
      );
      expect(validateSnapshot(s, maxRowsPerCollection: 1).errors, isNotEmpty);
      expect(validateSnapshot(s).errors, isEmpty);
    });

    test('dangling foreign keys are counted, never errors', () {
      final s = seedSnapshot();
      s.transactions!.single.categoryId = 999;
      s.items!.last.parentId = 998;
      final report = validateSnapshot(s);
      expect(report.errors, isEmpty);
      expect(report.danglingLinks, 2);
    });

    test('links into collections the file does not carry are not counted', () {
      final s = BackupSnapshot(
        source: ImportSource.csv,
        transactions: [
          TransactionModel()
            ..id = 1
            ..type = TransactionType.expense
            ..amountCents = 1
            ..categoryId = 999
            ..date = seedNow
            ..createdAt = seedNow
            ..updatedAt = seedNow,
        ],
      );
      expect(validateSnapshot(s).danglingLinks, 0);
    });
  });

  group('buildImportPreview', () {
    test('counts active rows and sums soft-deleted ones', () {
      final s = seedSnapshot();
      s.items!.add(item(9, deletedAt: seedNow));
      final preview = buildImportPreview(s, validateSnapshot(s));

      expect(preview.counts[BackupEntity.tasks], 2);
      expect(preview.counts[BackupEntity.categories], 2);
      expect(preview.counts[BackupEntity.budgets], 1);
      expect(preview.softDeletedCount, 1);
      expect(preview.totalRecords, 2 + 1 + 2 + 1 + 1 + 1 + 1);
      expect(preview.isPartial, isFalse);
      expect(preview.replaced, BackupEntity.values.toSet());
      expect(preview.exportedAt, seedNow);
    });

    test('date range spans the earliest and latest createdAt', () {
      final early = DateTime(2020);
      final late = DateTime(2030, 6, 7);
      final s = BackupSnapshot(
        source: ImportSource.json,
        items: [
          item(1, createdAt: late),
          item(2, createdAt: early, deletedAt: seedNow),
          item(3),
        ],
      );
      final preview = buildImportPreview(s, validateSnapshot(s));
      expect(preview.earliest, early);
      expect(preview.latest, late);
    });

    test('a CSV preview is partial and lists only what was supplied', () {
      final goals = seedSnapshot().goals;
      final s = BackupSnapshot(source: ImportSource.csv, goals: goals);
      final preview = buildImportPreview(s, validateSnapshot(s));
      expect(preview.isPartial, isTrue);
      expect(preview.replaced, {BackupEntity.goals});
      expect(preview.counts.keys, [BackupEntity.goals]);
      expect(preview.exportedAt, isNull);
    });

    test('an empty snapshot has no date range', () {
      const s = BackupSnapshot(source: ImportSource.json, items: []);
      final preview = buildImportPreview(s, validateSnapshot(s));
      expect(preview.earliest, isNull);
      expect(preview.latest, isNull);
    });
  });

  group('domain contracts', () {
    test('BackupEntity keys match the JSON envelope keys', () {
      expect(BackupEntity.tasks.jsonKey, BackupJsonKeys.items);
      expect(BackupEntity.transactions.jsonKey, BackupJsonKeys.transactions);
      expect(BackupEntity.categories.jsonKey, BackupJsonKeys.categories);
      expect(BackupEntity.budgets.jsonKey, BackupJsonKeys.budgets);
      expect(BackupEntity.goals.jsonKey, BackupJsonKeys.goals);
      expect(BackupEntity.debts.jsonKey, BackupJsonKeys.debts);
      expect(
        BackupEntity.recurringPayments.jsonKey,
        BackupJsonKeys.recurringPayments,
      );
      expect(BackupEntity.categories.csvStem, isNull);
    });

    test('importErrorCodeOf reads the prefix of a backup failure', () {
      expect(
        importErrorCodeOf(const BackupFailure('tooLarge: file 0 exceeds')),
        ImportErrorCode.tooLarge,
      );
      expect(importErrorCodeOf(const BackupFailure('oops: x')), isNull);
      expect(importErrorCodeOf(const BackupFailure('no colon')), isNull);
      expect(importErrorCodeOf(const DatabaseFailure('invalid: x')), isNull);
    });
  });
}
