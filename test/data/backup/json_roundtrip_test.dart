// Round-trip fidelity for the transaction, category, budget and goal codecs,
// and the single-transaction `BackupDao.readAll`, against a REAL Isar
// instance. Only IsarService (a thin wrapper whose `db` getter the DAO
// calls) is mocked.

import 'dart:convert';

import 'package:agenda/data/backup/dao/backup_dao.dart';
import 'package:agenda/data/backup/json/budget_json_codec.dart';
import 'package:agenda/data/backup/json/category_json_codec.dart';
import 'package:agenda/data/backup/json/goal_json_codec.dart';
import 'package:agenda/data/backup/json/json_fields.dart';
import 'package:agenda/data/backup/json/transaction_json_codec.dart';
import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/budget/budget_model.dart';
import 'package:agenda/data/finance/category/transaction_category_model.dart';
import 'package:agenda/data/finance/debt/debt_model.dart';
import 'package:agenda/data/finance/goal/savings_goal_model.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_model.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/isar_test_harness.dart';

class MockIsarService extends Mock implements IsarService {}

final _t0 = DateTime(2026, 3, 4, 5, 6, 7, 8, 9);
final _t1 = DateTime(2026, 5, 6, 7, 8, 9);

JsonObjectReader _wire(Map<String, Object?> json) =>
    JsonObjectReader.fromObject(jsonDecode(jsonEncode(json)));

bool _same(DateTime? a, DateTime? b) =>
    a == null ? b == null : (b != null && a.isAtSameMomentAs(b));

TransactionModel _tx(int id, {required bool full}) =>
    TransactionModel()
      ..id = id
      ..type = full ? TransactionType.income : TransactionType.expense
      ..amountCents = 123456
      ..categoryId = 9
      ..date = _t0
      ..note = full ? 'salary' : null
      ..linkedGoalId = full ? 4 : null
      ..deletedAt = full ? _t1 : null
      ..createdAt = _t0
      ..updatedAt = _t1;

TransactionCategoryModel _cat(int id, {required bool full}) =>
    TransactionCategoryModel()
      ..id = id
      ..namePtBr = 'Comida'
      ..nameEn = full ? 'Food' : null
      ..type = full ? TransactionType.expense : TransactionType.income
      ..isDefault = full
      ..createdAt = _t0;

BudgetModel _budget(int id, int month, int year) =>
    BudgetModel()
      ..id = id
      ..categoryId = 3
      ..month = month
      ..year = year
      ..limitCents = 50000
      ..createdAt = _t0
      ..updatedAt = _t1;

SavingsGoalModel _goal(int id, {required bool full}) =>
    SavingsGoalModel()
      ..id = id
      ..title = 'Trip'
      ..targetAmountCents = 900000
      ..deadline = full ? _t1 : null
      ..contributions =
          full
              ? [
                GoalContribution()
                  ..amountCents = 100
                  ..date = _t0
                  ..note = 'first',
                GoalContribution()
                  ..amountCents = 250
                  ..date = _t1,
              ]
              : List<GoalContribution>.empty(growable: true)
      ..isCompleted = full
      ..deletedAt = full ? _t0 : null
      ..createdAt = _t0
      ..updatedAt = _t1;

void main() {
  late IsarTestHarness harness;
  late Isar isar;
  late BackupDao dao;

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
    dao = BackupDao(service);
  });

  tearDown(() async {
    await harness.close();
  });

  test('transaction and category codecs reproduce every field', () async {
    await isar.writeTxn(() async {
      await isar.collection<TransactionModel>().putAll([
        _tx(1, full: true),
        _tx(2, full: false),
      ]);
      await isar.collection<TransactionCategoryModel>().putAll([
        _cat(1, full: true),
        _cat(2, full: false),
      ]);
    });
    final rows = await dao.readAll();

    for (final a in rows.transactions) {
      final b = transactionFromJson(_wire(transactionToJson(a)));
      expect(b.id, a.id);
      expect(b.type, a.type);
      expect(b.amountCents, a.amountCents);
      expect(b.categoryId, a.categoryId);
      expect(_same(b.date, a.date), isTrue);
      expect(b.note, a.note);
      expect(b.linkedGoalId, a.linkedGoalId);
      expect(_same(b.deletedAt, a.deletedAt), isTrue);
      expect(_same(b.createdAt, a.createdAt), isTrue);
      expect(_same(b.updatedAt, a.updatedAt), isTrue);
    }
    for (final a in rows.categories) {
      final b = categoryFromJson(_wire(categoryToJson(a)));
      expect(b.id, a.id);
      expect(b.namePtBr, a.namePtBr);
      expect(b.nameEn, a.nameEn);
      expect(b.type, a.type);
      expect(b.isDefault, a.isDefault);
      expect(_same(b.createdAt, a.createdAt), isTrue);
    }
    expect(rows.transactions.map((t) => t.note), contains('salary'));
    expect(rows.categories.map((c) => c.nameEn), contains(null));
  });

  test('budget codec reproduces every field', () async {
    await isar.writeTxn(
      () => isar.collection<BudgetModel>().put(_budget(7, 2, 2026)),
    );
    final a = (await dao.readAll()).budgets.single;
    final b = budgetFromJson(_wire(budgetToJson(a)));
    expect(b.id, 7);
    expect(b.categoryId, a.categoryId);
    expect(b.month, 2);
    expect(b.year, 2026);
    expect(b.limitCents, a.limitCents);
    expect(_same(b.createdAt, a.createdAt), isTrue);
    expect(_same(b.updatedAt, a.updatedAt), isTrue);
  });

  test('goal codec keeps contributions in order and growable', () async {
    await isar.writeTxn(
      () => isar.collection<SavingsGoalModel>().putAll([
        _goal(1, full: true),
        _goal(2, full: false),
      ]),
    );
    final goals = (await dao.readAll()).goals..sort((a, b) => a.id - b.id);
    for (final a in goals) {
      final b = goalFromJson(_wire(goalToJson(a)));
      expect(b.id, a.id);
      expect(b.title, a.title);
      expect(b.targetAmountCents, a.targetAmountCents);
      expect(_same(b.deadline, a.deadline), isTrue);
      expect(b.isCompleted, a.isCompleted);
      expect(_same(b.deletedAt, a.deletedAt), isTrue);
      expect(_same(b.createdAt, a.createdAt), isTrue);
      expect(_same(b.updatedAt, a.updatedAt), isTrue);
      expect(b.contributions.length, a.contributions.length);
      for (var i = 0; i < a.contributions.length; i++) {
        expect(b.contributions[i].amountCents, a.contributions[i].amountCents);
        expect(_same(b.contributions[i].date, a.contributions[i].date), isTrue);
        expect(b.contributions[i].note, a.contributions[i].note);
      }
      // A fixed-length list would throw here (Phase 03 UAT bug).
      expect(
        () => b.contributions.add(GoalContribution()..date = _t0),
        returnsNormally,
      );
    }
    expect(goals.first.contributions.map((c) => c.amountCents), [100, 250]);
  });

  test('decoders reject bad input with the field path', () {
    expect(
      () => transactionFromJson(
        _wire({...transactionToJson(_tx(1, full: true)), 'type': 'nope'}),
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          startsWith('type'),
        ),
      ),
    );
    expect(
      () => budgetFromJson(
        _wire({...budgetToJson(_budget(1, 1, 2026)), 'limitCents': '5'}),
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          startsWith('limitCents'),
        ),
      ),
    );
    expect(
      () => categoryFromJson(_wire({'id': 1})),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          startsWith('namePtBr'),
        ),
      ),
    );
  });

  test('readAll returns all 600 rows of every collection', () async {
    await isar.writeTxn(() async {
      await isar.collection<ItemModel>().putAll([
        for (var i = 1; i <= 600; i++)
          ItemModel()
            ..id = i
            ..type = ItemType.task
            ..title = 'T$i'
            ..deletedAt = i.isEven ? _t0 : null
            ..createdAt = _t0
            ..updatedAt = _t0,
      ]);
      await isar.collection<TransactionModel>().putAll(
        [for (var i = 1; i <= 600; i++) _tx(i, full: i.isEven)],
      );
      await isar.collection<TransactionCategoryModel>().putAll(
        [for (var i = 1; i <= 600; i++) _cat(i, full: i.isEven)],
      );
      await isar.collection<BudgetModel>().putAll([
        for (var i = 1; i <= 600; i++) _budget(i, i % 12 + 1, 1900 + i ~/ 12),
      ]);
      await isar.collection<SavingsGoalModel>().putAll(
        [for (var i = 1; i <= 600; i++) _goal(i, full: i.isEven)],
      );
      await isar.collection<DebtModel>().putAll([
        for (var i = 1; i <= 600; i++)
          DebtModel()
            ..id = i
            ..title = 'D$i'
            ..amountCents = 1
            ..direction = DebtDirection.toPay
            ..counterparty = 'X'
            ..dueDate = _t0
            ..createdAt = _t0
            ..updatedAt = _t0,
      ]);
      await isar.collection<RecurringPaymentModel>().putAll([
        for (var i = 1; i <= 600; i++)
          RecurringPaymentModel()
            ..id = i
            ..title = 'R$i'
            ..amountCents = 1
            ..categoryId = 1
            ..cycle = RecurringCycle.monthly
            ..nextDueDate = _t0
            ..createdAt = _t0
            ..updatedAt = _t0,
      ]);
    });

    final rows = await dao.readAll();

    expect(rows.items.length, 600);
    expect(rows.transactions.length, 600);
    expect(rows.categories.length, 600);
    expect(rows.budgets.length, 600);
    expect(rows.goals.length, 600);
    expect(rows.debts.length, 600);
    expect(rows.recurringPayments.length, 600);
    expect(rows.items.where((m) => m.deletedAt != null).length, 300);
  });
}
