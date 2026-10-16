// Completeness guard for the JSON export (plan 04-04), the BL-01 / CR-04
// class: 600 rows in every one of the seven collections, a tenth of the
// soft-deletable ones deleted, must ALL appear in the export. Real Isar;
// only IsarService is mocked. A second group proves the repository is
// registered in DI and resolves without opening Isar.

import 'dart:convert';

import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/backup/dao/backup_dao.dart';
import 'package:agenda/data/backup/json/backup_envelope.dart';
import 'package:agenda/data/backup/json/budget_json_codec.dart';
import 'package:agenda/data/backup/json/category_json_codec.dart';
import 'package:agenda/data/backup/json/debt_json_codec.dart';
import 'package:agenda/data/backup/json/goal_json_codec.dart';
import 'package:agenda/data/backup/json/item_json_codec.dart';
import 'package:agenda/data/backup/json/json_fields.dart';
import 'package:agenda/data/backup/json/payment_json_codec.dart';
import 'package:agenda/data/backup/json/transaction_json_codec.dart';
import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/budget/budget_model.dart';
import 'package:agenda/data/finance/category/transaction_category_model.dart';
import 'package:agenda/data/finance/debt/debt_model.dart';
import 'package:agenda/data/finance/goal/savings_goal_model.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_model.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:agenda/domain/backup/backup_file.dart';
import 'package:agenda/domain/backup/backup_repository.dart';
import 'package:agenda/infrastructure/backup/backup_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/isar_test_harness.dart';

class MockIsarService extends Mock implements IsarService {}

final _now = DateTime(2026, 2, 3, 4, 5);
const _n = 600;

/// Every 10th row (60 of 600) is soft-deleted.
DateTime? _deleted(int i) => i % 10 == 0 ? _now : null;

void main() {
  group('export completeness', () {
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
    });

    tearDown(() async {
      await harness.close();
    });

    test(
      '600 rows per collection, soft-deleted included, all decode',
      () async {
        await isar.writeTxn(() async {
          await isar.collection<ItemModel>().putAll([
            for (var i = 1; i <= _n; i++)
              ItemModel()
                ..id = i
                ..type = ItemType.task
                ..title = 'T$i'
                ..deletedAt = _deleted(i)
                ..createdAt = _now
                ..updatedAt = _now,
          ]);
          await isar.collection<TransactionModel>().putAll([
            for (var i = 1; i <= _n; i++)
              TransactionModel()
                ..id = i
                ..type = TransactionType.expense
                ..amountCents = i
                ..categoryId = 1
                ..date = _now
                ..deletedAt = _deleted(i)
                ..createdAt = _now
                ..updatedAt = _now,
          ]);
          await isar.collection<TransactionCategoryModel>().putAll([
            for (var i = 1; i <= _n; i++)
              TransactionCategoryModel()
                ..id = i
                ..namePtBr = 'Cat $i'
                ..nameEn = i.isEven ? 'Cat $i' : null
                ..type = TransactionType.income
                ..isDefault = i.isEven
                ..createdAt = _now,
          ]);
          await isar.collection<BudgetModel>().putAll([
            for (var i = 1; i <= _n; i++)
              BudgetModel()
                ..id = i
                ..categoryId = 1
                ..month = i % 12 + 1
                ..year = 1900 + i ~/ 12
                ..limitCents = i
                ..createdAt = _now
                ..updatedAt = _now,
          ]);
          await isar.collection<SavingsGoalModel>().putAll([
            for (var i = 1; i <= _n; i++)
              SavingsGoalModel()
                ..id = i
                ..title = 'G$i'
                ..targetAmountCents = i
                ..deletedAt = _deleted(i)
                ..createdAt = _now
                ..updatedAt = _now,
          ]);
          await isar.collection<DebtModel>().putAll([
            for (var i = 1; i <= _n; i++)
              DebtModel()
                ..id = i
                ..title = 'D$i'
                ..amountCents = i
                ..direction = DebtDirection.toReceive
                ..counterparty = 'X'
                ..dueDate = _now
                ..deletedAt = _deleted(i)
                ..createdAt = _now
                ..updatedAt = _now,
          ]);
          await isar.collection<RecurringPaymentModel>().putAll([
            for (var i = 1; i <= _n; i++)
              RecurringPaymentModel()
                ..id = i
                ..title = 'R$i'
                ..amountCents = i
                ..categoryId = 1
                ..cycle = RecurringCycle.yearly
                ..nextDueDate = _now
                ..isActive = i.isOdd
                ..deletedAt = _deleted(i)
                ..createdAt = _now
                ..updatedAt = _now,
          ]);
        });

        final result = await repository.exportJson(now: _now);

        final file = (result as Success<BackupFile>).value;
        final decoded = jsonDecode(utf8.decode(file.bytes));
        final collections = (decoded as Map<String, dynamic>)['collections'];
        expect(
          (collections as Map<String, dynamic>).keys.toSet(),
          {
            BackupJsonKeys.items,
            BackupJsonKeys.transactions,
            BackupJsonKeys.categories,
            BackupJsonKeys.budgets,
            BackupJsonKeys.goals,
            BackupJsonKeys.debts,
            BackupJsonKeys.recurringPayments,
          },
        );

        final parsed = parseBackupEnvelope(decoded);
        void expectAll<T>(String key, T Function(JsonObjectReader) decode) {
          final rows = parsed.rows(key);
          expect(rows.length, _n, reason: '$key must export every row');
          expect(rows.map(decode).toList().length, _n);
        }

        expectAll(BackupJsonKeys.items, itemFromJson);
        expectAll(BackupJsonKeys.transactions, transactionFromJson);
        expectAll(BackupJsonKeys.categories, categoryFromJson);
        expectAll(BackupJsonKeys.budgets, budgetFromJson);
        expectAll(BackupJsonKeys.goals, goalFromJson);
        expectAll(BackupJsonKeys.debts, debtFromJson);
        expectAll(BackupJsonKeys.recurringPayments, paymentFromJson);

        final deletedDebts = parsed
            .rows(BackupJsonKeys.debts)
            .map(debtFromJson)
            .where((d) => d.deletedAt != null);
        expect(deletedDebts.length, 60);
      },
    );
  });

  group('DI registration', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      if (getIt.isRegistered<IsarService>()) {
        await getIt.reset();
      }
      await configureDependencies();
    });

    tearDown(() async {
      await getIt.reset();
    });

    test('BackupRepository resolves without opening Isar', () {
      expect(getIt<BackupRepository>(), isA<BackupRepositoryImpl>());
    });
  });
}
