// Behavioral regression coverage for the last two live instances of the
// BL-01 defect class (03-REVIEW.md, deferred-items.md logged during 03-14).
//
// The defect: `SavingsGoalDao.findAll` and `DebtDao.findAll` both carry
// `.limit(500)` with NO `sortBy`. Isar returns unsorted rows in id
// (insertion) order, so the cap silently keeps the OLDEST 500 rows and
// drops the user's newest goals/debts. Both feed money TOTALS, not just
// display lists: `SavingsGoalDao.findAll` folds into
// `HomeDashboardCubit._reload`'s `computeGoalsSavedTotal`; `DebtDao.findAll`
// folds into `HomeDashboardCubit._reload`'s `computeDebtTotal`. Both sums
// land in `computeNetWorth`
// (`lib/application/finance/dashboard/dashboard_aggregator.dart`).
//
// This file is modelled directly on
// `test/data/finance/transaction_dao_aggregate_completeness_test.dart`
// (written by 03-14): only `IsarService` (a thin wrapper whose `db` getter
// the DAO calls) is mocked; the Isar collection itself, and every
// filter/limit applied to it, is real, via `IsarTestHarness` (03-13).

import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/debt/debt_dao.dart';
import 'package:agenda/data/finance/debt/debt_model.dart';
import 'package:agenda/data/finance/goal/savings_goal_dao.dart';
import 'package:agenda/data/finance/goal/savings_goal_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/isar_test_harness.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockIsarService extends Mock implements IsarService {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a data-layer model for the `SavingsGoalDao.findAll` group.
SavingsGoalModel _goalModel(int id, {DateTime? deletedAt}) {
  final now = DateTime(2026);
  return SavingsGoalModel()
    ..id = id
    ..title = 'Goal $id'
    ..targetAmountCents = 1000
    ..deletedAt = deletedAt
    ..createdAt = now
    ..updatedAt = now;
}

/// Builds a data-layer model for the `DebtDao.findAll` group.
DebtModel _debtModel(int id, {DateTime? deletedAt}) {
  final now = DateTime(2026);
  return DebtModel()
    ..id = id
    ..title = 'Debt $id'
    ..amountCents = 1000
    ..direction = DebtDirection.toPay
    ..counterparty = 'Counterparty $id'
    ..dueDate = now
    ..deletedAt = deletedAt
    ..createdAt = now
    ..updatedAt = now;
}

void main() {
  group('BL-01 · SavingsGoalDao.findAll returns every row past the '
      '500-row cap', () {
    late IsarTestHarness harness;
    late Isar isar;
    late MockIsarService mockIsarService;
    late SavingsGoalDao dao;

    setUp(() async {
      harness = IsarTestHarness();
      isar = await harness.open([SavingsGoalModelSchema]);
      mockIsarService = MockIsarService();
      when(() => mockIsarService.db).thenReturn(isar);
      dao = SavingsGoalDao(mockIsarService);
    });

    tearDown(() async {
      await harness.close();
    });

    test(
      'returns all 600 active goals, not merely the first 500',
      () async {
        final collection = isar.collection<SavingsGoalModel>();

        // 600 active (non-deleted) goals — must all survive an uncapped
        // read.
        final activeGoals = [
          for (var i = 0; i < 600; i++) _goalModel(i + 1),
        ];

        // Excluded by soft delete.
        final deletedGoal = _goalModel(601, deletedAt: DateTime(2026, 1, 2));

        await isar.writeTxn(
          () => collection.putAll([...activeGoals, deletedGoal]),
        );

        final result = await dao.findAll();

        expect(
          result.length,
          600,
          reason: 'SavingsGoalDao.findAll must return every matching row, '
              'not just the first 500 — an unsorted .limit(500) silently '
              'keeps the OLDEST 500 and drops the rest (BL-01 defect '
              'class).',
        );
        expect(
          result.every((m) => m.deletedAt == null),
          isTrue,
          reason: 'the soft-deleted goal must still be excluded',
        );
        expect(result.map((m) => m.id), isNot(contains(601)));
      },
    );
  });

  group(
    'BL-01 · DebtDao.findAll returns every row past the 500-row cap',
    () {
      late IsarTestHarness harness;
      late Isar isar;
      late MockIsarService mockIsarService;
      late DebtDao dao;

      setUp(() async {
        harness = IsarTestHarness();
        isar = await harness.open([DebtModelSchema]);
        mockIsarService = MockIsarService();
        when(() => mockIsarService.db).thenReturn(isar);
        dao = DebtDao(mockIsarService);
      });

      tearDown(() async {
        await harness.close();
      });

      test(
        'returns all 600 active debts, not merely the first 500',
        () async {
          final collection = isar.collection<DebtModel>();

          // 600 active (non-deleted) debts — must all survive an uncapped
          // read.
          final activeDebts = [
            for (var i = 0; i < 600; i++) _debtModel(i + 1),
          ];

          // Excluded by soft delete.
          final deletedDebt = _debtModel(
            601,
            deletedAt: DateTime(2026, 1, 2),
          );

          await isar.writeTxn(
            () => collection.putAll([...activeDebts, deletedDebt]),
          );

          final result = await dao.findAll();

          expect(
            result.length,
            600,
            reason: 'DebtDao.findAll must return every matching row, not '
                'just the first 500 — an unsorted .limit(500) silently '
                'keeps the OLDEST 500 and drops the rest (BL-01 defect '
                'class).',
          );
          expect(
            result.every((m) => m.deletedAt == null),
            isTrue,
            reason: 'the soft-deleted debt must still be excluded',
          );
          expect(result.map((m) => m.id), isNot(contains(601)));
        },
      );
    },
  );
}
