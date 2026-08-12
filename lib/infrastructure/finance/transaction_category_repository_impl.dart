import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/finance/category/transaction_category_dao.dart';
import 'package:agenda/data/finance/category/transaction_category_mapper.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart' as data;
import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/category/transaction_category_repository.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';
import 'package:injectable/injectable.dart';

/// Concrete implementation of [TransactionCategoryRepository].
///
/// Validation (T-03-02-02):
/// - Default categories (isDefault == true) cannot be deleted or renamed.
@LazySingleton(as: TransactionCategoryRepository)
class TransactionCategoryRepositoryImpl
    implements TransactionCategoryRepository {
  const TransactionCategoryRepositoryImpl(this._dao, this._mapper);

  final TransactionCategoryDao _dao;
  final TransactionCategoryMapper _mapper;

  @override
  AsyncResult<List<TransactionCategory>> getAll() async {
    try {
      final models = await _dao.findAll();
      return Success(models.map(_mapper.toDomain).toList());
    } on Object catch (e) {
      return Err(DatabaseFailure('getAll categories failed: $e'));
    }
  }

  @override
  AsyncResult<List<TransactionCategory>> getByType(
    TransactionType type,
  ) async {
    try {
      final dataType = type == TransactionType.income
          ? data.TransactionType.income
          : data.TransactionType.expense;
      final models = await _dao.findByType(dataType);
      return Success(models.map(_mapper.toDomain).toList());
    } on Object catch (e) {
      return Err(DatabaseFailure('getByType categories failed: $e'));
    }
  }

  @override
  AsyncResult<TransactionCategory> create(
    TransactionCategory category,
  ) async {
    try {
      final now = DateTime.now();
      final toSave = category.copyWith(createdAt: now);
      final model = _mapper.toModel(toSave);
      final id = await _dao.save(model);
      final saved = await _dao.findById(id);
      return Success(_mapper.toDomain(saved!));
    } on Object catch (e) {
      return Err(DatabaseFailure('create category failed: $e'));
    }
  }

  @override
  AsyncResult<TransactionCategory> update(
    TransactionCategory category,
  ) async {
    try {
      // Load the existing record to check isDefault
      final existing = await _dao.findById(category.id);
      if (existing == null) {
        return Err(DatabaseFailure('Category ${category.id} not found'));
      }
      if (existing.isDefault) {
        return const Err(
          ValidationFailure('Cannot rename a default category'),
        );
      }
      final model = _mapper.toModel(category);
      final id = await _dao.save(model);
      final saved = await _dao.findById(id);
      return Success(_mapper.toDomain(saved!));
    } on Object catch (e) {
      return Err(DatabaseFailure('update category failed: $e'));
    }
  }

  @override
  AsyncResult<void> delete(int id) async {
    try {
      // T-03-02-02: Guard — cannot delete default categories
      final existing = await _dao.findById(id);
      if (existing == null) {
        return Err(DatabaseFailure('Category $id not found'));
      }
      if (existing.isDefault) {
        return const Err(
          ValidationFailure('Cannot delete a default category'),
        );
      }
      await _dao.hardDelete(id);
      return const Success(null);
    } on Object catch (e) {
      return Err(DatabaseFailure('delete category failed: $e'));
    }
  }
}
