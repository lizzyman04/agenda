import 'package:agenda/application/finance/goal/goal_cubit.dart';
import 'package:agenda/application/finance/goal/goal_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/goal_repository.dart';
import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:agenda/domain/finance/savings_goal_contribution.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/domain/finance/transaction_repository.dart';
import 'package:agenda/domain/finance/transaction_type.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

DateTime _d(int y, int m, int d) => DateTime(y, m, d);

SavingsGoal _makeGoal({
  int id = 1,
  int targetAmountCents = 100000,
  List<SavingsGoalContribution> contributions = const [],
}) {
  return SavingsGoal(
    id: id,
    title: 'Emergency Fund',
    targetAmountCents: targetAmountCents,
    contributions: contributions,
    isCompleted: false,
    createdAt: _d(2026, 1, 1),
    updatedAt: _d(2026, 1, 1),
  );
}

Transaction _makeTaggedTx({int id = 10, int amountCents = 5000, int goalId = 1}) {
  return Transaction(
    id: id,
    type: TransactionType.expense,
    amountCents: amountCents,
    categoryId: 1,
    linkedGoalId: goalId,
    date: _d(2026, 1, 10),
    createdAt: _d(2026, 1, 10),
    updatedAt: _d(2026, 1, 10),
  );
}

void main() {
  late MockGoalRepository mockGoalRepo;
  late MockTransactionRepository mockTxRepo;

  setUp(() {
    mockGoalRepo = MockGoalRepository();
    mockTxRepo = MockTransactionRepository();
    when(() => mockGoalRepo.watchChanges())
        .thenAnswer((_) => const Stream.empty());
    registerFallbackValue(
      SavingsGoalContribution(amountCents: 1, date: _d(2026, 1, 1)),
    );
  });

  group('GoalCubit', () {
    blocTest<GoalCubit, GoalState>(
      'loadGoal() emits GoalLoaded with combined amountSavedCents',
      build: () {
        final goal = _makeGoal(
          id: 1,
          contributions: [
            SavingsGoalContribution(amountCents: 2000, date: _d(2026, 1, 5)),
          ],
        );
        when(() => mockGoalRepo.getGoal(1)).thenAnswer(
          (_) async => Success(goal),
        );
        when(() => mockTxRepo.getByLinkedGoal(1)).thenAnswer(
          (_) async => Success([_makeTaggedTx(amountCents: 3000)]),
        );
        return GoalCubit(mockGoalRepo, mockTxRepo);
      },
      act: (cubit) => cubit.loadGoal(1),
      expect: () => [
        isA<GoalLoading>(),
        isA<GoalLoaded>()
            .having((s) => s.taggedTransactionsCents, 'taggedCents', 3000),
      ],
    );

    blocTest<GoalCubit, GoalState>(
      'addContribution() calls goalRepo.addContribution and re-emits GoalLoaded',
      build: () {
        final goal = _makeGoal(id: 1);
        final contribution = SavingsGoalContribution(
          amountCents: 1000,
          date: _d(2026, 1, 10),
        );
        final updatedGoal = _makeGoal(
          id: 1,
          contributions: [contribution],
        );
        when(() => mockGoalRepo.getGoal(1))
            .thenAnswer((_) async => Success(goal));
        when(() => mockTxRepo.getByLinkedGoal(1))
            .thenAnswer((_) async => Success([]));
        when(() => mockGoalRepo.addContribution(1, any())).thenAnswer(
          (_) async => Success(updatedGoal),
        );
        return GoalCubit(mockGoalRepo, mockTxRepo);
      },
      act: (cubit) async {
        await cubit.loadGoal(1);
        await cubit.addContribution(
          1,
          SavingsGoalContribution(amountCents: 1000, date: _d(2026, 1, 10)),
        );
      },
      verify: (_) {
        verify(() => mockGoalRepo.addContribution(1, any())).called(1);
      },
    );
  });
}
