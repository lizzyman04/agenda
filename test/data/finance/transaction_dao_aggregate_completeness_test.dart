// Behavioral regression coverage for BL-01 (03-REVIEW.md,
// 03-VERIFICATION.md's gaps).
//
// The defect: `TransactionDao.findByMonth` and `TransactionDao
// .findByLinkedGoal` both carry `.limit(500)` with NO `sortBy`. Isar returns
// unsorted rows in id (insertion) order, so the cap silently keeps the
// OLDEST 500 rows and drops the user's most recent activity. Both feed money
// TOTALS, not display lists: `findByMonth` folds into
// `BudgetCubit._reload`'s per-category spend and over-limit warning;
// `findByLinkedGoal` folds into `GoalCubit._refreshGoal`'s `taggedCents`,
// half of `SavingsGoal.progressPercent`. Plan 03-09 fixed this exact class
// of bug (CR-04) for `findAll`/`findAllForAggregates` but left these two
// methods capped.
//
// `test/data/finance/transaction_dao_ordering_test.dart` cannot catch this:
// its "DAO query shape" group reads DAO *source text*, never references
// `findByMonth` or `findByLinkedGoal`, and would pass unchanged whether the
// cap is present or not. Per WR-D6 in `03-REVIEW.md`, a source-text
// assertion for these two methods would prove nothing — this file
// supersedes that approach for `findByMonth`/`findByLinkedGoal` specifically
// by testing real query behavior against a genuine Isar collection, via the
// `IsarTestHarness` built in plan 03-13. Only `IsarService` (a thin wrapper
// whose `db` getter the DAO calls) is mocked; the Isar collection itself,
// and every filter/limit applied to it, is real.

import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/transaction/transaction_dao.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
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

/// Builds a data-layer model for the `findByMonth` group.
TransactionModel _monthModel(
  int id,
  DateTime date, {
  TransactionType type = TransactionType.expense,
  DateTime? deletedAt,
}) =>
    TransactionModel()
      ..id = id
      ..type = type
      ..amountCents = 1
      ..categoryId = 1
      ..date = date
      ..deletedAt = deletedAt
      ..createdAt = date
      ..updatedAt = date;

/// Builds a data-layer model for the `findByLinkedGoal` group.
TransactionModel _goalModel(
  int id, {
  required int linkedGoalId,
  DateTime? deletedAt,
}) {
  final date = DateTime(2026, 1, 1);
  return TransactionModel()
    ..id = id
    ..type = TransactionType.expense
    ..amountCents = 1
    ..categoryId = 1
    ..date = date
    ..linkedGoalId = linkedGoalId
    ..deletedAt = deletedAt
    ..createdAt = date
    ..updatedAt = date;
}

void main() {
  late IsarTestHarness harness;
  late Isar isar;
  late MockIsarService mockIsarService;
  late TransactionDao dao;

  setUp(() async {
    harness = IsarTestHarness();
    isar = await harness.open([TransactionModelSchema]);
    mockIsarService = MockIsarService();
    when(() => mockIsarService.db).thenReturn(isar);
    dao = TransactionDao(mockIsarService);
  });

  tearDown(() async {
    await harness.close();
  });

  group('BL-01 · findByMonth returns every row past the 500-row cap', () {
    test(
      'returns all 600 in-month expense rows, not merely the first 500',
      () async {
        final collection = isar.collection<TransactionModel>();

        // 600 in-month, non-deleted expense rows — the rows that must all
        // survive an uncapped read.
        final inMonthExpenses = [
          for (var i = 0; i < 600; i++)
            _monthModel(
              i + 1,
              DateTime(2026, 1, 1).add(Duration(hours: i)),
            ),
        ];

        // Excluded by type: same-month income row.
        final incomeRow = _monthModel(
          601,
          DateTime(2026, 1, 15),
          type: TransactionType.income,
        );

        // Excluded by range: one day into the next month.
        final outOfMonthRow = _monthModel(602, DateTime(2026, 2, 1));

        // Excluded by soft delete: in-month expense, but deletedAt is set.
        final deletedRow = _monthModel(
          603,
          DateTime(2026, 1, 20),
          deletedAt: DateTime(2026, 1, 21),
        );

        await isar.writeTxn(
          () => collection.putAll([
            ...inMonthExpenses,
            incomeRow,
            outOfMonthRow,
            deletedRow,
          ]),
        );

        final result = await dao.findByMonth(1, 2026);

        expect(
          result.length,
          600,
          reason: 'findByMonth must return every matching row, not just the '
              'first 500 (BL-01) — an unsorted .limit(500) silently keeps '
              'the OLDEST 500 and drops the rest.',
        );
        expect(
          result.every((m) => m.type == TransactionType.expense),
          isTrue,
          reason: 'the income-type row must still be excluded',
        );
        expect(
          result.every(
            (m) =>
                !m.date.isBefore(DateTime(2026, 1)) &&
                m.date.isBefore(DateTime(2026, 2)),
          ),
          isTrue,
          reason: 'the out-of-month row must still be excluded',
        );
        expect(
          result.every((m) => m.deletedAt == null),
          isTrue,
          reason: 'the soft-deleted row must still be excluded',
        );
        expect(result.map((m) => m.id), isNot(contains(601)));
        expect(result.map((m) => m.id), isNot(contains(602)));
        expect(result.map((m) => m.id), isNot(contains(603)));
      },
    );
  });

  group(
    'BL-01 · findByLinkedGoal returns every row past the 500-row cap',
    () {
      test(
        'returns all 600 tagged rows, not merely the first 500',
        () async {
          final collection = isar.collection<TransactionModel>();

          // 600 rows tagged to goal 42, non-deleted — must all survive.
          final taggedRows = [
            for (var i = 0; i < 600; i++) _goalModel(i + 1, linkedGoalId: 42),
          ];

          // Excluded by soft delete: tagged to 42, but deletedAt is set.
          final deletedTaggedRow = _goalModel(
            601,
            linkedGoalId: 42,
            deletedAt: DateTime(2026, 1, 2),
          );

          // Excluded by goal: tagged to a different goal.
          final otherGoalRow = _goalModel(602, linkedGoalId: 7);

          await isar.writeTxn(
            () => collection.putAll([
              ...taggedRows,
              deletedTaggedRow,
              otherGoalRow,
            ]),
          );

          final result = await dao.findByLinkedGoal(42);

          expect(
            result.length,
            600,
            reason: 'findByLinkedGoal must return every matching row, not '
                'just the first 500 (BL-01) — an unsorted .limit(500) '
                'silently keeps the OLDEST 500 and drops the rest.',
          );
          expect(
            result.every((m) => m.linkedGoalId == 42),
            isTrue,
            reason: 'the row tagged to a different goal must still be '
                'excluded',
          );
          expect(
            result.every((m) => m.deletedAt == null),
            isTrue,
            reason: 'the soft-deleted tagged row must still be excluded',
          );
          expect(result.map((m) => m.id), isNot(contains(601)));
          expect(result.map((m) => m.id), isNot(contains(602)));
        },
      );
    },
  );
}
