import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/finance/transaction/transaction_dao.dart';
import 'package:agenda/data/finance/transaction/transaction_mapper.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_repository.dart';
import 'package:injectable/injectable.dart';

/// Concrete implementation of [TransactionRepository].
///
/// Wraps [TransactionDao] in try/catch blocks and maps results to [Result<T>].
/// Never throws — all errors returned as Err(DatabaseFailure or
/// ValidationFailure).
///
/// Validation (T-03-02-01):
/// - amountCents must be > 0
/// - categoryId must be > 0
@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._dao, this._mapper);

  final TransactionDao _dao;
  final TransactionMapper _mapper;

  @override
  AsyncResult<Transaction> createTransaction(Transaction transaction) async {
    try {
      if (transaction.amountCents <= 0) {
        return const Err(
          ValidationFailure('amountCents must be greater than zero'),
        );
      }
      if (transaction.categoryId <= 0) {
        return const Err(
          ValidationFailure('categoryId must be a valid reference'),
        );
      }
      final now = DateTime.now();
      final toSave = transaction.copyWith(createdAt: now, updatedAt: now);
      final model = _mapper.toModel(toSave);
      final id = await _dao.save(model);
      final saved = await _dao.findById(id);
      return Success(_mapper.toDomain(saved!));
    } on Object catch (e) {
      return Err(DatabaseFailure('createTransaction failed: $e'));
    }
  }

  @override
  AsyncResult<Transaction> getTransaction(int id) async {
    try {
      final model = await _dao.findById(id);
      if (model == null) {
        return Err(DatabaseFailure('Transaction $id not found'));
      }
      return Success(_mapper.toDomain(model));
    } on Object catch (e) {
      return Err(DatabaseFailure('getTransaction failed: $e'));
    }
  }

  @override
  AsyncResult<List<Transaction>> getTransactions() async {
    try {
      final models = await _dao.findAll();
      return Success(models.map(_mapper.toDomain).toList());
    } on Object catch (e) {
      return Err(DatabaseFailure('getTransactions failed: $e'));
    }
  }

  @override
  AsyncResult<List<Transaction>> getByMonth(int month, int year) async {
    try {
      final models = await _dao.findByMonth(month, year);
      return Success(models.map(_mapper.toDomain).toList());
    } on Object catch (e) {
      return Err(DatabaseFailure('getByMonth failed: $e'));
    }
  }

  @override
  AsyncResult<List<Transaction>> getByLinkedGoal(int goalId) async {
    try {
      final models = await _dao.findByLinkedGoal(goalId);
      return Success(models.map(_mapper.toDomain).toList());
    } on Object catch (e) {
      return Err(DatabaseFailure('getByLinkedGoal failed: $e'));
    }
  }

  @override
  AsyncResult<Transaction> updateTransaction(Transaction transaction) async {
    try {
      if (transaction.amountCents <= 0) {
        return const Err(
          ValidationFailure('amountCents must be greater than zero'),
        );
      }
      if (transaction.categoryId <= 0) {
        return const Err(
          ValidationFailure('categoryId must be a valid reference'),
        );
      }
      final updated = transaction.copyWith(updatedAt: DateTime.now());
      final model = _mapper.toModel(updated);
      await _dao.save(model);
      return Success(updated);
    } on Object catch (e) {
      return Err(DatabaseFailure('updateTransaction failed: $e'));
    }
  }

  @override
  AsyncResult<Transaction> softDelete(int id) async {
    try {
      await _dao.softDelete(id);
      // Read model directly by id — bypasses the deletedAtIsNull
      // filter in findAll.
      final model = await _dao.findById(id);
      if (model == null) {
        return Err(
          DatabaseFailure('Transaction $id not found after softDelete'),
        );
      }
      return Success(_mapper.toDomain(model));
    } on Object catch (e) {
      return Err(DatabaseFailure('softDelete failed: $e'));
    }
  }

  @override
  Stream<void> watchChanges() => _dao.watchLazy();
}
