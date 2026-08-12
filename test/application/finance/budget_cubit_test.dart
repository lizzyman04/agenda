import 'package:agenda/application/finance/budget/budget_cubit.dart';
import 'package:agenda/application/finance/budget/budget_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/budget/budget.dart';
import 'package:agenda/domain/finance/budget/budget_repository.dart';
import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/category/transaction_category_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockCategoryRepository extends Mock
    implements TransactionCategoryRepository {}

DateTime _jan2026(int day) => DateTime(2026, 1, day);

Transaction _makeExpense({
  int id = 1,
  int amountCents = 3000,
  int categoryId = 1,
}) {
  return Transaction(
    id: id,
    type: TransactionType.expense,
    amountCents: amountCents,
    categoryId: categoryId,
    date: _jan2026(10),
    createdAt: _jan2026(10),
    updatedAt: _jan2026(10),
  );
}

TransactionCategory _makeCategory({int id = 1, String name = 'Food'}) {
  return TransactionCategory(
    id: id,
    namePtBr: name,
    type: TransactionType.expense,
    isDefault: true,
    createdAt: _jan2026(1),
  );
}

Budget _makeBudget({int categoryId = 1, int limitCents = 10000}) {
  return Budget(
    id: 1,
    categoryId: categoryId,
    month: 1,
    year: 2026,
    limitCents: limitCents,
    createdAt: _jan2026(1),
    updatedAt: _jan2026(1),
  );
}

void main() {
  late MockTransactionRepository mockTxRepo;
  late MockBudgetRepository mockBudgetRepo;
  late MockCategoryRepository mockCategoryRepo;

  setUp(() {
    mockTxRepo = MockTransactionRepository();
    mockBudgetRepo = MockBudgetRepository();
    mockCategoryRepo = MockCategoryRepository();
    when(() => mockTxRepo.watchChanges())
        .thenAnswer((_) => const Stream.empty());
  });

  group('BudgetCubit', () {
    blocTest<BudgetCubit, BudgetState>(
      'reload() emits BudgetLoaded with correct spentCents per categoryId',
      build: () {
        final now = DateTime.now();
        when(() => mockTxRepo.getByMonth(now.month, now.year)).thenAnswer(
          (_) async => Success([_makeExpense()]),
        );
        when(() => mockBudgetRepo.getForMonth(now.month, now.year)).thenAnswer(
          (_) async => Success([_makeBudget()]),
        );
        when(() => mockCategoryRepo.getByType(TransactionType.expense))
            .thenAnswer(
          (_) async => Success([_makeCategory(name: 'Alimentação')]),
        );
        return BudgetCubit(mockTxRepo, mockBudgetRepo, mockCategoryRepo);
      },
      act: (cubit) => cubit.start(),
      expect: () => [
        isA<BudgetLoaded>().having(
          (s) => s.budgets[1]?.spentCents,
          'spentCents for categoryId=1',
          3000,
        ),
      ],
    );

    blocTest<BudgetCubit, BudgetState>(
      'budget for category with no transactions emits spentCents = 0',
      build: () {
        final now = DateTime.now();
        when(() => mockTxRepo.getByMonth(now.month, now.year)).thenAnswer(
          (_) async => const Success(<Transaction>[]),
        );
        when(() => mockBudgetRepo.getForMonth(now.month, now.year)).thenAnswer(
          (_) async => Success([_makeBudget(categoryId: 2, limitCents: 5000)]),
        );
        when(() => mockCategoryRepo.getByType(TransactionType.expense))
            .thenAnswer(
          (_) async => Success([_makeCategory(id: 2, name: 'Transporte')]),
        );
        return BudgetCubit(mockTxRepo, mockBudgetRepo, mockCategoryRepo);
      },
      act: (cubit) => cubit.start(),
      expect: () => [
        isA<BudgetLoaded>().having(
          (s) => s.budgets[2]?.spentCents,
          'spentCents for categoryId=2',
          0,
        ),
      ],
    );

    blocTest<BudgetCubit, BudgetState>(
      'setLimit() calls budgetRepo.setLimit then triggers reload',
      build: () {
        final now = DateTime.now();
        when(() => mockTxRepo.getByMonth(now.month, now.year)).thenAnswer(
          (_) async => const Success(<Transaction>[]),
        );
        when(
          () => mockBudgetRepo.setLimit(any(), any(), any(), any()),
        ).thenAnswer(
          (_) async => Success(_makeBudget(limitCents: 8000)),
        );
        when(() => mockBudgetRepo.getForMonth(any(), any())).thenAnswer(
          (_) async => Success([_makeBudget(limitCents: 8000)]),
        );
        when(() => mockCategoryRepo.getByType(TransactionType.expense))
            .thenAnswer(
          (_) async => Success([_makeCategory()]),
        );
        return BudgetCubit(mockTxRepo, mockBudgetRepo, mockCategoryRepo);
      },
      act: (cubit) {
        final now = DateTime.now();
        return cubit.setLimit(1, now.month, now.year, 8000);
      },
      verify: (_) {
        verify(
          () => mockBudgetRepo.setLimit(any(), any(), any(), any()),
        ).called(1);
      },
    );
  });
}
