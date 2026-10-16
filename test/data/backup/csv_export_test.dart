// Completeness guard for the CSV export (plan 04-08): 600 active rows per
// entity must ALL appear (the 500-row cap defect class, BL-01 / CR-04), the
// 40 soft-deleted rows per soft-deletable entity must NOT. Real Isar; only
// IsarService is mocked.

import 'dart:convert';

import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/backup/csv/csv_table_codec.dart';
import 'package:agenda/data/backup/csv/mappers/budget_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/debt_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/goal_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/payment_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/task_csv_mapper.dart';
import 'package:agenda/data/backup/csv/mappers/transaction_csv_mapper.dart';
import 'package:agenda/data/backup/dao/backup_dao.dart';
import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/budget/budget_model.dart';
import 'package:agenda/data/finance/category/transaction_category_model.dart';
import 'package:agenda/data/finance/debt/debt_model.dart';
import 'package:agenda/data/finance/goal/savings_goal_model.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_model.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:agenda/domain/backup/backup_file.dart';
import 'package:agenda/infrastructure/backup/backup_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/isar_test_harness.dart';

class MockIsarService extends Mock implements IsarService {}

final _now = DateTime(2026, 2, 3, 4, 5);
const _active = 600;
const _deleted = 40;

DateTime? _deletedAt(int i) => i > _active ? _now : null;

CsvTable _decode(BackupFile f) => decodeCsvTable(utf8.decode(f.bytes));

void main() {
  group('exportCsv completeness', () {
    late IsarTestHarness harness;
    late Isar isar;
    late BackupRepositoryImpl repository;

    setUp(() async {
      harness = IsarTestHarness();
      isar = await harness.open([
        ItemModelSchema,
        TransactionModelSchema,
        TransactionCategoryModelSchema,
        BudgetModelSchema,
        SavingsGoalModelSchema,
        DebtModelSchema,
        RecurringPaymentModelSchema,
      ]);
      final service = MockIsarService();
      when(() => service.db).thenReturn(isar);
      repository = BackupRepositoryImpl(BackupDao(service));

      const total = _active + _deleted;
      await isar.writeTxn(() async {
        await isar.collection<TransactionCategoryModel>().put(
          TransactionCategoryModel()
            ..id = 1
            ..namePtBr = 'Alimentação'
            ..nameEn = 'Food'
            ..type = TransactionType.expense
            ..createdAt = _now,
        );
        await isar.collection<ItemModel>().putAll([
          for (var i = 1; i <= total; i++)
            ItemModel()
              ..id = i
              ..type = ItemType.task
              ..title = 'T$i'
              ..deletedAt = _deletedAt(i)
              ..createdAt = _now
              ..updatedAt = _now,
        ]);
        await isar.collection<TransactionModel>().putAll([
          for (var i = 1; i <= total; i++)
            TransactionModel()
              ..id = i
              ..type = TransactionType.expense
              ..amountCents = i * 13
              ..categoryId = 1
              ..date = _now
              ..deletedAt = _deletedAt(i)
              ..createdAt = _now
              ..updatedAt = _now,
        ]);
        await isar.collection<BudgetModel>().putAll([
          for (var i = 1; i <= _active; i++)
            BudgetModel()
              ..id = i
              ..categoryId = 1
              ..month = i % 12 + 1
              ..year = 1900 + i ~/ 12
              ..limitCents = i * 13
              ..createdAt = _now
              ..updatedAt = _now,
        ]);
        await isar.collection<SavingsGoalModel>().putAll([
          for (var i = 1; i <= total; i++)
            SavingsGoalModel()
              ..id = i
              ..title = 'G$i'
              ..targetAmountCents = i * 13
              ..deletedAt = _deletedAt(i)
              ..createdAt = _now
              ..updatedAt = _now,
        ]);
        await isar.collection<DebtModel>().putAll([
          for (var i = 1; i <= total; i++)
            DebtModel()
              ..id = i
              ..title = 'D$i'
              ..amountCents = i * 13
              ..direction = DebtDirection.toReceive
              ..counterparty = 'X'
              ..dueDate = _now
              ..deletedAt = _deletedAt(i)
              ..createdAt = _now
              ..updatedAt = _now,
        ]);
        await isar.collection<RecurringPaymentModel>().putAll([
          for (var i = 1; i <= total; i++)
            RecurringPaymentModel()
              ..id = i
              ..title = 'R$i'
              ..amountCents = i * 13
              ..categoryId = 1
              ..cycle = RecurringCycle.yearly
              ..nextDueDate = _now
              ..deletedAt = _deletedAt(i)
              ..createdAt = _now
              ..updatedAt = _now,
        ]);
      });
    });

    tearDown(() async {
      await harness.close();
    });

    Future<List<BackupFile>> export(String language) async {
      final result = await repository.exportCsv(
        languageCode: language,
        now: _now,
      );
      return (result as Success<List<BackupFile>>).value;
    }

    const headers = [
      TaskCsvMapper.header,
      TransactionCsvMapper.header,
      BudgetCsvMapper.header,
      GoalCsvMapper.header,
      DebtCsvMapper.header,
      PaymentCsvMapper.header,
    ];
    const stems = [
      TaskCsvMapper.fileStem,
      TransactionCsvMapper.fileStem,
      BudgetCsvMapper.fileStem,
      GoalCsvMapper.fileStem,
      DebtCsvMapper.fileStem,
      PaymentCsvMapper.fileStem,
    ];

    for (final language in ['pt', 'en']) {
      test('six uncapped, active-only files ($language)', () async {
        final files = await export(language);

        expect(files, hasLength(6));
        expect(files.map((f) => f.name), [
          for (final s in stems) 'agenda-$s-2026-02-03.csv',
        ]);
        for (var i = 0; i < files.length; i++) {
          expect(files[i].bytes.take(3), [0xEF, 0xBB, 0xBF]);
          final table = _decode(files[i]);
          expect(table.header, headers[i], reason: stems[i]);
          expect(table.rows, hasLength(_active), reason: stems[i]);
          final ids = {for (final r in table.rows) int.parse(r.first)};
          expect(ids, hasLength(_active), reason: stems[i]);
          expect(ids.every((id) => id <= _active), isTrue, reason: stems[i]);
          expect(ids.first, 1, reason: '${stems[i]} ordered by id');
        }

        final tx = _decode(files[1]);
        final row = tx.rows[6]; // id 7
        final cents = tx.header.indexOf('amount_cents');
        final amount = tx.header.indexOf('amount');
        final name = tx.header.indexOf('category_name');
        expect(row[cents], '91');
        expect(row[amount], language == 'en' ? '0.91' : '0,91');
        expect(row[name], language == 'en' ? 'Food' : 'Alimentação');

        final text = utf8.decode(files[1].bytes);
        if (language == 'en') {
          expect(text.split('\r\n').first, contains(','));
          expect(text.split('\r\n').first, isNot(contains(';')));
        } else {
          expect(text.split('\r\n').first, contains(';'));
        }
      });
    }

    test('an empty database still yields six header-only files', () async {
      await isar.writeTxn(() async {
        await isar.clear();
      });
      final files = await export('en');
      expect(files, hasLength(6));
      for (var i = 0; i < files.length; i++) {
        final table = _decode(files[i]);
        expect(table.header, headers[i]);
        expect(table.rows, isEmpty);
      }
    });
  });
}
