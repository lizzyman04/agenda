import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/finance/budget_dao.dart';
import 'package:agenda/data/finance/budget_mapper.dart';
import 'package:agenda/domain/finance/budget/budget.dart';
import 'package:agenda/domain/finance/budget/budget_repository.dart';
import 'package:injectable/injectable.dart';

/// Concrete implementation of [BudgetRepository].
///
/// setLimit is an upsert — loads by (categoryId, month, year), then
/// updates or creates as appropriate. Both paths use dao.save().
@LazySingleton(as: BudgetRepository)
class BudgetRepositoryImpl implements BudgetRepository {
  const BudgetRepositoryImpl(this._dao, this._mapper);

  final BudgetDao _dao;
  final BudgetMapper _mapper;

  @override
  AsyncResult<Budget?> getForCategory(
    int categoryId,
    int month,
    int year,
  ) async {
    try {
      final model =
          await _dao.findByCategoryMonthYear(categoryId, month, year);
      if (model == null) return const Success(null);
      return Success(_mapper.toDomain(model));
    } on Object catch (e) {
      return Err(DatabaseFailure('getForCategory failed: $e'));
    }
  }

  @override
  AsyncResult<List<Budget>> getForMonth(int month, int year) async {
    try {
      final models = await _dao.findByMonth(month, year);
      return Success(models.map(_mapper.toDomain).toList());
    } on Object catch (e) {
      return Err(DatabaseFailure('getForMonth failed: $e'));
    }
  }

  @override
  AsyncResult<Budget> setLimit(
    int categoryId,
    int month,
    int year,
    int limitCents,
  ) async {
    try {
      if (limitCents <= 0) {
        return const Err(
          ValidationFailure('amountCents must be greater than zero'),
        );
      }
      final now = DateTime.now();
      final existing =
          await _dao.findByCategoryMonthYear(categoryId, month, year);

      if (existing != null) {
        // Update: preserve id and createdAt
        existing
          ..limitCents = limitCents
          ..updatedAt = now;
        await _dao.save(existing);
        final updated =
            await _dao.findByCategoryMonthYear(categoryId, month, year);
        return Success(_mapper.toDomain(updated!));
      } else {
        // Create: new budget record
        final newBudget = Budget(
          id: 0,
          categoryId: categoryId,
          month: month,
          year: year,
          limitCents: limitCents,
          createdAt: now,
          updatedAt: now,
        );
        final model = _mapper.toModel(newBudget);
        final id = await _dao.save(model);
        final saved = await _dao.findById(id);
        return Success(_mapper.toDomain(saved!));
      }
    } on Object catch (e) {
      return Err(DatabaseFailure('setLimit failed: $e'));
    }
  }

  @override
  AsyncResult<void> delete(int categoryId, int month, int year) async {
    try {
      await _dao.deleteWhere(categoryId, month, year);
      return const Success(null);
    } on Object catch (e) {
      return Err(DatabaseFailure('delete budget failed: $e'));
    }
  }
}
