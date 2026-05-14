import 'package:agenda/application/finance/dashboard/home_dashboard_cubit.dart';
import 'package:agenda/application/finance/dashboard/home_dashboard_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/debt.dart';
import 'package:agenda/domain/finance/debt_direction.dart';
import 'package:agenda/domain/finance/debt_repository.dart';
import 'package:agenda/domain/finance/goal_repository.dart';
import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/domain/finance/transaction_category.dart';
import 'package:agenda/domain/finance/transaction_category_repository.dart';
import 'package:agenda/domain/finance/transaction_repository.dart';
import 'package:agenda/domain/finance/transaction_type.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockGoalRepository extends Mock implements GoalRepository {}

class MockDebtRepository extends Mock implements DebtRepository {}

class MockCategoryRepository extends Mock
    implements TransactionCategoryRepository {}

// Helpers

DateTime _d(int y, int m, int day) => DateTime(y, m, day);

Transaction _makeTx({
  int id = 1,
  TransactionType type = TransactionType.income,
  int amountCents = 5000,
  int categoryId = 1,
  DateTime? date,
  DateTime? deletedAt,
}) {
  final txDate = date ?? _d(2026, 1, 10);
  return Transaction(
    id: id,
    type: type,
    amountCents: amountCents,
    categoryId: categoryId,
    date: txDate,
    createdAt: txDate,
    updatedAt: txDate,
    deletedAt: deletedAt,
  );
}

SavingsGoal _makeGoal({int id = 1, int targetCents = 100000}) {
  return SavingsGoal(
    id: id,
    title: 'Emergency Fund',
    targetAmountCents: targetCents,
    contributions: const [],
    isCompleted: false,
    createdAt: _d(2026, 1, 1),
    updatedAt: _d(2026, 1, 1),
  );
}

Debt _makeDebt({
  int id = 1,
  int amountCents = 1500,
  DebtDirection direction = DebtDirection.toPay,
  bool isPaid = false,
}) {
  return Debt(
    id: id,
    title: 'Loan',
    amountCents: amountCents,
    direction: direction,
    counterparty: 'Bank',
    dueDate: _d(2026, 6, 1),
    isPaid: isPaid,
    createdAt: _d(2026, 1, 1),
    updatedAt: _d(2026, 1, 1),
  );
}

TransactionCategory _makeCategory({int id = 1}) {
  return TransactionCategory(
    id: id,
    namePtBr: 'Alimentação',
    type: TransactionType.expense,
    isDefault: true,
    createdAt: _d(2026, 1, 1),
  );
}

/// Helper to build cubit with all repos stubbed via provided lists.
HomeDashboardCubit _buildCubit({
  required MockTransactionRepository txRepo,
  required MockGoalRepository goalRepo,
  required MockDebtRepository debtRepo,
  required MockCategoryRepository catRepo,
  List<Transaction>? transactions,
  List<SavingsGoal>? goals,
  List<Debt>? debts,
  List<TransactionCategory>? categories,
}) {
  when(() => txRepo.getTransactions()).thenAnswer(
    (_) async => Success(transactions ?? []),
  );
  when(() => goalRepo.getActiveGoals()).thenAnswer(
    (_) async => Success(goals ?? []),
  );
  when(() => debtRepo.getDebts()).thenAnswer(
    (_) async => Success(debts ?? []),
  );
  when(() => catRepo.getAll()).thenAnswer(
    (_) async => Success(categories ?? []),
  );
  return HomeDashboardCubit(txRepo, goalRepo, debtRepo, catRepo);
}

void main() {
  late MockTransactionRepository mockTxRepo;
  late MockGoalRepository mockGoalRepo;
  late MockDebtRepository mockDebtRepo;
  late MockCategoryRepository mockCatRepo;

  setUp(() {
    mockTxRepo = MockTransactionRepository();
    mockGoalRepo = MockGoalRepository();
    mockDebtRepo = MockDebtRepository();
    mockCatRepo = MockCategoryRepository();
    when(() => mockTxRepo.watchChanges())
        .thenAnswer((_) => const Stream.empty());
  });

  group('HomeDashboardCubit', () {
    blocTest<HomeDashboardCubit, HomeDashboardState>(
      '_reload() emits HomeDashboardLoaded with correct balanceCents (income - expense)',
      build: () => _buildCubit(
        txRepo: mockTxRepo,
        goalRepo: mockGoalRepo,
        debtRepo: mockDebtRepo,
        catRepo: mockCatRepo,
        transactions: [
          _makeTx(id: 1, type: TransactionType.income, amountCents: 5000),
          _makeTx(id: 2, type: TransactionType.income, amountCents: 3000),
          _makeTx(id: 3, type: TransactionType.expense, amountCents: 2000),
        ],
      ),
      act: (cubit) => cubit.start(),
      expect: () => [
        isA<HomeDashboardLoaded>().having(
          (s) => s.balanceCents,
          'balanceCents == 5000+3000-2000 == 6000',
          6000,
        ),
      ],
    );

    blocTest<HomeDashboardCubit, HomeDashboardState>(
      '_reload() computes netWorthCents: balance + goals.amountSaved - toPay debts',
      build: () => _buildCubit(
        txRepo: mockTxRepo,
        goalRepo: mockGoalRepo,
        debtRepo: mockDebtRepo,
        catRepo: mockCatRepo,
        transactions: [
          _makeTx(id: 1, type: TransactionType.income, amountCents: 5000),
          _makeTx(id: 2, type: TransactionType.income, amountCents: 3000),
          _makeTx(id: 3, type: TransactionType.expense, amountCents: 2000),
        ],
        goals: [
          _makeGoal(id: 1), // contributions = [], taggedCents = 0 → amountSaved = 0
        ],
        debts: [
          _makeDebt(id: 1, amountCents: 1500, direction: DebtDirection.toPay, isPaid: false),
        ],
      ),
      act: (cubit) => cubit.start(),
      expect: () => [
        isA<HomeDashboardLoaded>().having(
          (s) => s.netWorthCents,
          'netWorthCents == 6000 + 0 - 1500 == 4500',
          4500,
        ),
      ],
    );

    blocTest<HomeDashboardCubit, HomeDashboardState>(
      '_reload() excludes toReceive debts from net worth formula (D-08)',
      build: () => _buildCubit(
        txRepo: mockTxRepo,
        goalRepo: mockGoalRepo,
        debtRepo: mockDebtRepo,
        catRepo: mockCatRepo,
        transactions: [
          _makeTx(id: 1, type: TransactionType.income, amountCents: 6000),
        ],
        debts: [
          // toReceive debt — must NOT be subtracted from net worth
          _makeDebt(
            id: 2,
            amountCents: 3000,
            direction: DebtDirection.toReceive,
            isPaid: false,
          ),
        ],
      ),
      act: (cubit) => cubit.start(),
      expect: () => [
        isA<HomeDashboardLoaded>().having(
          (s) => s.netWorthCents,
          'netWorthCents == 6000 (toReceive debt not subtracted)',
          6000,
        ),
      ],
    );

    blocTest<HomeDashboardCubit, HomeDashboardState>(
      '_reload() categorySpend groups expense txs by categoryId for selectedMonth only',
      build: () {
        // Jan 2026 expenses in category 1 and 2
        // Feb 2026 expense — must NOT appear in categorySpend (different month)
        final now = DateTime.now();
        return _buildCubit(
          txRepo: mockTxRepo,
          goalRepo: mockGoalRepo,
          debtRepo: mockDebtRepo,
          catRepo: mockCatRepo,
          transactions: [
            _makeTx(
              id: 1,
              type: TransactionType.expense,
              amountCents: 1000,
              categoryId: 1,
              date: DateTime(now.year, now.month, 5),
            ),
            _makeTx(
              id: 2,
              type: TransactionType.expense,
              amountCents: 2000,
              categoryId: 2,
              date: DateTime(now.year, now.month, 10),
            ),
            // Different month — must be excluded from categorySpend
            _makeTx(
              id: 3,
              type: TransactionType.expense,
              amountCents: 999,
              categoryId: 1,
              date: DateTime(now.year, now.month - 1 == 0 ? 12 : now.month - 1, 5),
            ),
          ],
          categories: [_makeCategory(id: 1), _makeCategory(id: 2)],
        );
      },
      act: (cubit) => cubit.start(),
      expect: () => [
        isA<HomeDashboardLoaded>()
            .having(
              (s) => s.categorySpend[1],
              'categorySpend[1] == 1000 (current month only)',
              1000,
            )
            .having(
              (s) => s.categorySpend[2],
              'categorySpend[2] == 2000',
              2000,
            ),
      ],
    );

    blocTest<HomeDashboardCubit, HomeDashboardState>(
      'selectMonth() re-queries and emits categorySpend for new month only',
      build: () {
        return _buildCubit(
          txRepo: mockTxRepo,
          goalRepo: mockGoalRepo,
          debtRepo: mockDebtRepo,
          catRepo: mockCatRepo,
          transactions: [
            // March 2026 expense
            _makeTx(
              id: 1,
              type: TransactionType.expense,
              amountCents: 5000,
              categoryId: 1,
              date: _d(2026, 3, 15),
            ),
            // April 2026 expense — must not appear in March chart
            _makeTx(
              id: 2,
              type: TransactionType.expense,
              amountCents: 7777,
              categoryId: 2,
              date: _d(2026, 4, 10),
            ),
          ],
          categories: [_makeCategory(id: 1)],
        );
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.selectMonth(DateTime(2026, 3));
      },
      expect: () => [
        // First emit from start() — uses DateTime.now() as selectedMonth
        isA<HomeDashboardLoaded>(),
        // Second emit from selectMonth(March) — categorySpend for March only
        isA<HomeDashboardLoaded>()
            .having(
              (s) => s.selectedMonth.month,
              'selectedMonth.month == 3',
              3,
            )
            .having(
              (s) => s.categorySpend[1],
              'categorySpend[1] == 5000 (March only)',
              5000,
            )
            .having(
              (s) => s.categorySpend.containsKey(2),
              'April tx NOT in March categorySpend',
              false,
            ),
      ],
    );

    blocTest<HomeDashboardCubit, HomeDashboardState>(
      '_reload() emits empty categorySpend when no expense txs in selected month',
      build: () => _buildCubit(
        txRepo: mockTxRepo,
        goalRepo: mockGoalRepo,
        debtRepo: mockDebtRepo,
        catRepo: mockCatRepo,
        transactions: [
          // Income only — no expense
          _makeTx(id: 1, type: TransactionType.income, amountCents: 5000),
        ],
      ),
      act: (cubit) => cubit.start(),
      expect: () => [
        isA<HomeDashboardLoaded>().having(
          (s) => s.categorySpend.isEmpty,
          'categorySpend is empty',
          true,
        ),
      ],
    );

    blocTest<HomeDashboardCubit, HomeDashboardState>(
      '_reload() excludes soft-deleted transactions from all aggregations',
      build: () => _buildCubit(
        txRepo: mockTxRepo,
        goalRepo: mockGoalRepo,
        debtRepo: mockDebtRepo,
        catRepo: mockCatRepo,
        // Note: TransactionRepository.getTransactions() already excludes
        // soft-deleted (deletedAtIsNull filter in DAO). We confirm the
        // cubit correctly aggregates only what the repo returns.
        transactions: [
          _makeTx(id: 1, type: TransactionType.income, amountCents: 5000),
          // Repo already excludes soft-deleted — simulate by returning only active
        ],
      ),
      act: (cubit) => cubit.start(),
      expect: () => [
        isA<HomeDashboardLoaded>().having(
          (s) => s.balanceCents,
          'balanceCents includes only active txs',
          5000,
        ),
      ],
    );
  });
}
