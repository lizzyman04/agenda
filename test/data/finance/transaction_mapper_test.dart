import 'package:agenda/data/finance/transaction/transaction_mapper.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart'
    as domain;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = TransactionMapper();
  final now = DateTime(2026, 5, 14, 12);

  group('TransactionMapper.toDomain', () {
    test('preserves amountCents exactly (no floating-point corruption)', () {
      final model =
          TransactionModel()
            ..id = 1
            ..type = TransactionType.expense
            ..amountCents = 123456
            ..categoryId = 2
            ..date = now
            ..createdAt = now
            ..updatedAt = now;

      final domain = mapper.toDomain(model);

      expect(domain.amountCents, equals(123456));
    });

    test('maps TransactionType.income correctly', () {
      final model =
          TransactionModel()
            ..id = 1
            ..type = TransactionType.income
            ..amountCents = 1000
            ..categoryId = 1
            ..date = now
            ..createdAt = now
            ..updatedAt = now;

      final result = mapper.toDomain(model);

      expect(result.type, equals(domain.TransactionType.income));
    });

    test('maps TransactionType.expense correctly', () {
      final model =
          TransactionModel()
            ..id = 1
            ..type = TransactionType.expense
            ..amountCents = 5000
            ..categoryId = 3
            ..date = now
            ..createdAt = now
            ..updatedAt = now;

      final result = mapper.toDomain(model);

      expect(result.type, equals(domain.TransactionType.expense));
    });
  });

  group('TransactionMapper.toModel', () {
    test('does NOT set model.id when transaction.id == 0 (autoIncrement)', () {
      final tx = Transaction(
        id: 0,
        type: domain.TransactionType.expense,
        amountCents: 500,
        categoryId: 1,
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      final model = mapper.toModel(tx);

      // When id == 0, the model id should remain Isar.autoIncrement
      // (9223372036854775807)
      // and not be set to 0 (which would overwrite the record with id=0)
      expect(model.id, isNot(equals(0)));
    });

    test('sets model.id = 5 when transaction.id == 5', () {
      final tx = Transaction(
        id: 5,
        type: domain.TransactionType.income,
        amountCents: 9999,
        categoryId: 2,
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      final model = mapper.toModel(tx);

      expect(model.id, equals(5));
    });

    test('TransactionType enum round-trips: income → income', () {
      final tx = Transaction(
        id: 0,
        type: domain.TransactionType.income,
        amountCents: 100,
        categoryId: 1,
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      final model = mapper.toModel(tx);
      final roundTripped = mapper.toDomain(model);

      expect(roundTripped.type, equals(domain.TransactionType.income));
    });

    test('TransactionType enum round-trips: expense → expense', () {
      final tx = Transaction(
        id: 0,
        type: domain.TransactionType.expense,
        amountCents: 200,
        categoryId: 2,
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      final model = mapper.toModel(tx);
      final roundTripped = mapper.toDomain(model);

      expect(roundTripped.type, equals(domain.TransactionType.expense));
    });
  });
}
