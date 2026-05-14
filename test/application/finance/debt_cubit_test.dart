import 'package:agenda/application/finance/debt/debt_cubit.dart';
import 'package:agenda/application/finance/debt/debt_state.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/debt.dart';
import 'package:agenda/domain/finance/debt_direction.dart';
import 'package:agenda/domain/finance/debt_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

Debt _makeDebt({
  int id = 1,
  bool isPaid = false,
  DebtDirection direction = DebtDirection.toPay,
}) {
  final now = DateTime(2026, 1, 15);
  return Debt(
    id: id,
    title: 'Rent',
    amountCents: 50000,
    direction: direction,
    counterparty: 'Landlord',
    dueDate: now,
    isPaid: isPaid,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockDebtRepository mockRepo;

  setUp(() {
    mockRepo = MockDebtRepository();
    when(() => mockRepo.watchChanges()).thenAnswer((_) => const Stream.empty());
  });

  group('DebtCubit', () {
    blocTest<DebtCubit, DebtState>(
      'start() emits DebtLoaded with repo debt list',
      build: () {
        when(() => mockRepo.getDebts()).thenAnswer(
          (_) async => Success([_makeDebt()]),
        );
        return DebtCubit(mockRepo);
      },
      act: (cubit) => cubit.start(),
      expect: () => [
        isA<DebtLoaded>().having(
          (s) => s.debts.length,
          'debts.length',
          1,
        ),
      ],
    );

    blocTest<DebtCubit, DebtState>(
      'start() emits DebtError when repo returns Err',
      build: () {
        when(() => mockRepo.getDebts()).thenAnswer(
          (_) async => const Err(DatabaseFailure('db error')),
        );
        return DebtCubit(mockRepo);
      },
      act: (cubit) => cubit.start(),
      expect: () => [isA<DebtError>()],
    );

    blocTest<DebtCubit, DebtState>(
      'togglePaid() calls repo.togglePaid',
      build: () {
        final paidDebt = _makeDebt(isPaid: true);
        when(() => mockRepo.togglePaid(1)).thenAnswer(
          (_) async => Success(paidDebt),
        );
        when(() => mockRepo.getDebts())
            .thenAnswer((_) async => Success([paidDebt]));
        return DebtCubit(mockRepo);
      },
      act: (cubit) => cubit.togglePaid(1),
      verify: (_) {
        verify(() => mockRepo.togglePaid(1)).called(1);
      },
    );

    blocTest<DebtCubit, DebtState>(
      'togglePaid() emits DebtLoaded with updated debt',
      build: () {
        final unpaidDebt = _makeDebt(id: 1, isPaid: false);
        final paidDebt = _makeDebt(id: 1, isPaid: true);
        // Simulate watchChanges firing after togglePaid triggers a repo change
        when(() => mockRepo.watchChanges()).thenAnswer((_) => const Stream.empty());
        when(() => mockRepo.togglePaid(1)).thenAnswer(
          (_) async => Success(paidDebt),
        );
        when(() => mockRepo.getDebts()).thenAnswer(
          (_) async => Success([paidDebt]),
        );
        return DebtCubit(mockRepo);
      },
      act: (cubit) => cubit.togglePaid(1),
      expect: () => [
        isA<DebtLoaded>().having(
          (s) => s.debts.first.isPaid,
          'isPaid',
          true,
        ),
      ],
    );
  });
}
