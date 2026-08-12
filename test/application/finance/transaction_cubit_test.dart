import 'package:agenda/application/finance/transaction/transaction_cubit.dart';
import 'package:agenda/application/finance/transaction/transaction_state.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

Transaction _makeTransaction({
  int id = 1,
  TransactionType type = TransactionType.income,
  int amountCents = 5000,
}) {
  final now = DateTime(2026, 1, 15);
  return Transaction(
    id: id,
    type: type,
    amountCents: amountCents,
    categoryId: 1,
    date: now,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockTransactionRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(_makeTransaction(id: 0));
  });

  setUp(() {
    mockRepo = MockTransactionRepository();
    // Default stub for watchChanges — returns empty stream
    when(() => mockRepo.watchChanges()).thenAnswer((_) => const Stream.empty());
  });

  group('TransactionCubit', () {
    blocTest<TransactionCubit, TransactionState>(
      'start() emits TransactionLoaded with repo transaction list',
      build: () {
        when(() => mockRepo.getTransactions()).thenAnswer(
          (_) async => Success([_makeTransaction()]),
        );
        return TransactionCubit(mockRepo);
      },
      act: (cubit) => cubit.start(),
      expect: () => [
        isA<TransactionLoaded>().having(
          (s) => s.transactions.length,
          'transactions.length',
          1,
        ),
      ],
    );

    blocTest<TransactionCubit, TransactionState>(
      'start() emits TransactionError when repo returns Err',
      build: () {
        when(() => mockRepo.getTransactions()).thenAnswer(
          (_) async => const Err(DatabaseFailure('db error')),
        );
        return TransactionCubit(mockRepo);
      },
      act: (cubit) => cubit.start(),
      expect: () => [isA<TransactionError>()],
    );

    blocTest<TransactionCubit, TransactionState>(
      'createTransaction() calls repo.createTransaction',
      build: () {
        final tx = _makeTransaction();
        when(() => mockRepo.createTransaction(any()))
            .thenAnswer((_) async => Success(tx));
        when(() => mockRepo.getTransactions())
            .thenAnswer((_) async => Success([tx]));
        return TransactionCubit(mockRepo);
      },
      act: (cubit) => cubit.createTransaction(_makeTransaction(id: 0)),
      verify: (_) {
        verify(() => mockRepo.createTransaction(any())).called(1);
      },
    );

    blocTest<TransactionCubit, TransactionState>(
      'softDelete() calls repo.softDelete',
      build: () {
        final tx = _makeTransaction();
        when(() => mockRepo.softDelete(any()))
            .thenAnswer((_) async => Success(tx));
        when(() => mockRepo.getTransactions())
            .thenAnswer((_) async => const Success([]));
        return TransactionCubit(mockRepo);
      },
      act: (cubit) => cubit.softDelete(1),
      verify: (_) {
        verify(() => mockRepo.softDelete(1)).called(1);
      },
    );
  });
}
