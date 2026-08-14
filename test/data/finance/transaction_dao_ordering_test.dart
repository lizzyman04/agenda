// Regression coverage for CR-04 (03-REVIEW.md, Critical).
//
// The defect: `TransactionDao.findAll()` was
// `.filter().deletedAtIsNull().limit(500).findAll()` with NO sort. Isar
// returns rows in id order, so the cap kept the OLDEST 500 transactions and
// discarded everything the user had logged most recently. That truncated
// list fed HomeDashboardCubit's computeBalance / computeNetWorth /
// computeCategorySpend, so the headline balance silently went wrong at
// transaction 501 and drifted further every day the user kept logging.
//
// Route taken (the plan asks which): this project has no infrastructure for
// opening a real Isar instance in a test — `initializeIsarCore` appears
// nowhere, `test/data/tasks/item_dao_test.dart` is an empty stub, and
// `migration_runner_test.dart` drives a Fake Isar. Inventing that
// infrastructure was explicitly out of scope, so the fix is pinned at three
// levels instead:
//   1. Repository read routing, against a mocked DAO.
//   2. Dashboard balance past the 500-row cap, against a mocked repository.
//   3. The DAO query shape itself, asserted from source — the same
//      read-the-real-file pattern already used by `test/l10n/l10n_test.dart`.
// Level 3 is the assertion that fails if the descending date sort is
// removed; levels 1 and 2 fail if the aggregate path is pointed back at the
// capped read.

import 'dart:io';

import 'package:agenda/application/finance/dashboard/home_dashboard_cubit.dart';
import 'package:agenda/application/finance/dashboard/home_dashboard_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/finance/transaction/transaction_dao.dart';
import 'package:agenda/data/finance/transaction/transaction_mapper.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/category/transaction_category_repository.dart';
import 'package:agenda/domain/finance/debt/debt.dart';
import 'package:agenda/domain/finance/debt/debt_repository.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart'
    as domain;
import 'package:agenda/infrastructure/finance/transaction_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockTransactionDao extends Mock implements TransactionDao {}

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockGoalRepository extends Mock implements GoalRepository {}

class _MockDebtRepository extends Mock implements DebtRepository {}

class _MockCategoryRepository extends Mock
    implements TransactionCategoryRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _daoPath = 'lib/data/finance/transaction/transaction_dao.dart';

/// Builds a data-layer model dated [date].
TransactionModel _model(int id, DateTime date, {int amountCents = 100}) =>
    TransactionModel()
      ..id = id
      ..type = TransactionType.income
      ..amountCents = amountCents
      ..categoryId = 1
      ..date = date
      ..createdAt = date
      ..updatedAt = date;

/// Builds a domain transaction dated [date].
Transaction _tx(int id, DateTime date, {int amountCents = 100}) => Transaction(
      id: id,
      type: domain.TransactionType.income,
      amountCents: amountCents,
      categoryId: 1,
      date: date,
      createdAt: date,
      updatedAt: date,
    );

/// Returns the source text of the expression body of [signature] in [source],
/// i.e. everything from the signature up to the statement-terminating `;`.
String _methodBody(String source, String signature) {
  final start = source.indexOf(signature);
  expect(
    start,
    greaterThanOrEqualTo(0),
    reason: '"$signature" not found in $_daoPath',
  );
  final end = source.indexOf(';', start);
  expect(end, greaterThan(start), reason: 'unterminated body for $signature');
  return source.substring(start, end);
}

void main() {
  // 501 rows, oldest first — one more than the 500-row cap.
  final dates = List.generate(
    501,
    (i) => DateTime(2026).add(Duration(days: i)),
  );

  group('CR-04 · repository read routing', () {
    late _MockTransactionDao dao;
    late TransactionRepositoryImpl repository;

    setUp(() {
      dao = _MockTransactionDao();
      repository = TransactionRepositoryImpl(dao, const TransactionMapper());
    });

    test('aggregate path reads the uncapped DAO query, not the capped one',
        () async {
      final all = [for (var i = 0; i < 501; i++) _model(i + 1, dates[i])];
      when(dao.findAllForAggregates).thenAnswer((_) async => all);

      final result = await repository.getAllTransactionsForAggregates();

      verify(dao.findAllForAggregates).called(1);
      verifyNever(dao.findAll);
      expect(result, isA<Success<List<Transaction>>>());
      expect((result as Success<List<Transaction>>).value.length, 501);
    });

    test('list path still reads the capped DAO query', () async {
      when(dao.findAll).thenAnswer((_) async => [_model(1, dates.first)]);

      await repository.getTransactions();

      verify(dao.findAll).called(1);
      verifyNever(dao.findAllForAggregates);
    });

    test('aggregate path maps DAO failures to Err(DatabaseFailure)', () async {
      when(dao.findAllForAggregates).thenThrow(Exception('isar down'));

      final result = await repository.getAllTransactionsForAggregates();

      expect(result, isA<Err<List<Transaction>>>());
    });
  });

  group('CR-04 · dashboard balance past the 500-row cap', () {
    test('balance includes the 501st transaction', () async {
      final txRepo = _MockTransactionRepository();
      final goalRepo = _MockGoalRepository();
      final debtRepo = _MockDebtRepository();
      final catRepo = _MockCategoryRepository();

      // 500 old rows of 100 cents, plus one recent row of 999_999 cents.
      final complete = <Transaction>[
        for (var i = 0; i < 500; i++) _tx(i + 1, dates[i]),
        _tx(501, dates[500], amountCents: 999999),
      ];

      when(txRepo.watchChanges).thenAnswer((_) => const Stream.empty());
      when(txRepo.getAllTransactionsForAggregates)
          .thenAnswer((_) async => Success(complete));
      // What the capped read returned before the fix: the OLDEST 500 rows,
      // with the newest transaction missing.
      when(txRepo.getTransactions).thenAnswer(
        (_) async => Success(complete.sublist(0, 500)),
      );
      when(goalRepo.getActiveGoals)
          .thenAnswer((_) async => const Success(<SavingsGoal>[]));
      when(debtRepo.getDebts).thenAnswer((_) async => const Success(<Debt>[]));
      when(catRepo.getAll)
          .thenAnswer((_) async => const Success(<TransactionCategory>[]));

      final cubit = HomeDashboardCubit(txRepo, goalRepo, debtRepo, catRepo);
      addTearDown(cubit.close);

      await cubit.start();

      final state = cubit.state;
      expect(state, isA<HomeDashboardLoaded>());
      expect(
        (state as HomeDashboardLoaded).balanceCents,
        // 500 * 100 + 999_999. Reading the capped query instead yields
        // 50_000 — the silently wrong balance CR-04 recorded.
        equals(500 * 100 + 999999),
      );
    });
  });

  group('CR-04 · DAO query shape', () {
    late String source;

    setUpAll(() {
      source = File(_daoPath).readAsStringSync();
    });

    test('findAll() sorts by date descending BEFORE applying limit(500)', () {
      final body = _methodBody(
        source,
        'Future<List<TransactionModel>> findAll()',
      );

      final sortAt = body.indexOf('sortByDateDesc()');
      final limitAt = body.indexOf('.limit(500)');

      expect(
        sortAt,
        greaterThanOrEqualTo(0),
        reason: 'findAll() has no descending date sort — an unsorted '
            '.limit(500) keeps the OLDEST 500 rows (CR-04).',
      );
      expect(limitAt, greaterThanOrEqualTo(0));
      expect(
        sortAt,
        lessThan(limitAt),
        reason: 'the sort must be applied before the cap, otherwise the cap '
            'still selects rows in id order (CR-04).',
      );
    });

    test('findAllForAggregates() applies no limit', () {
      final body = _methodBody(
        source,
        'Future<List<TransactionModel>> findAllForAggregates()',
      );

      expect(body.contains('deletedAtIsNull()'), isTrue);
      expect(
        body.contains('.limit('),
        isFalse,
        reason: 'aggregates must see every row — a capped total is silently '
            'wrong rather than obviously incomplete (CR-04).',
      );
    });
  });
}
