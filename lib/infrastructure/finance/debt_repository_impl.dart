import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/finance/debt_dao.dart';
import 'package:agenda/data/finance/debt_mapper.dart';
import 'package:agenda/domain/finance/debt.dart';
import 'package:agenda/domain/finance/debt_repository.dart';
import 'package:injectable/injectable.dart';

/// Concrete implementation of [DebtRepository].
///
/// Validation:
/// - title must not be empty
/// - amountCents must be > 0
@LazySingleton(as: DebtRepository)
class DebtRepositoryImpl implements DebtRepository {
  const DebtRepositoryImpl(this._dao, this._mapper);

  final DebtDao _dao;
  final DebtMapper _mapper;

  @override
  AsyncResult<Debt> createDebt(Debt debt) async {
    try {
      if (debt.title.isEmpty) {
        return const Err(ValidationFailure('title must not be empty'));
      }
      if (debt.amountCents <= 0) {
        return const Err(
          ValidationFailure('amountCents must be greater than zero'),
        );
      }
      final now = DateTime.now();
      final toSave = debt.copyWith(createdAt: now, updatedAt: now);
      final model = _mapper.toModel(toSave);
      final id = await _dao.save(model);
      final saved = await _dao.findById(id);
      return Success(_mapper.toDomain(saved!));
    } on Object catch (e) {
      return Err(DatabaseFailure('createDebt failed: $e'));
    }
  }

  @override
  AsyncResult<Debt> getDebt(int id) async {
    try {
      final model = await _dao.findById(id);
      if (model == null) {
        return Err(DatabaseFailure('Debt $id not found'));
      }
      return Success(_mapper.toDomain(model));
    } on Object catch (e) {
      return Err(DatabaseFailure('getDebt failed: $e'));
    }
  }

  @override
  AsyncResult<List<Debt>> getDebts() async {
    try {
      final models = await _dao.findAll();
      return Success(models.map(_mapper.toDomain).toList());
    } on Object catch (e) {
      return Err(DatabaseFailure('getDebts failed: $e'));
    }
  }

  @override
  AsyncResult<Debt> updateDebt(Debt debt) async {
    try {
      if (debt.title.isEmpty) {
        return const Err(ValidationFailure('title must not be empty'));
      }
      if (debt.amountCents <= 0) {
        return const Err(
          ValidationFailure('amountCents must be greater than zero'),
        );
      }
      final updated = debt.copyWith(updatedAt: DateTime.now());
      final model = _mapper.toModel(updated);
      await _dao.save(model);
      return Success(updated);
    } on Object catch (e) {
      return Err(DatabaseFailure('updateDebt failed: $e'));
    }
  }

  @override
  AsyncResult<Debt> togglePaid(int id) async {
    try {
      final model = await _dao.findById(id);
      if (model == null) {
        return Err(DatabaseFailure('Debt $id not found'));
      }

      // Toggle isPaid: if false → set true + record paidAt;
      // if true → clear both
      final now = DateTime.now();
      if (!model.isPaid) {
        model
          ..isPaid = true
          ..paidAt = now;
      } else {
        model
          ..isPaid = false
          ..paidAt = null;
      }
      model.updatedAt = now;

      await _dao.save(model);
      final saved = await _dao.findById(id);
      return Success(_mapper.toDomain(saved!));
    } on Object catch (e) {
      return Err(DatabaseFailure('togglePaid failed: $e'));
    }
  }

  @override
  AsyncResult<Debt> softDelete(int id) async {
    try {
      await _dao.softDelete(id);
      final model = await _dao.findById(id);
      if (model == null) {
        return Err(DatabaseFailure('Debt $id not found after softDelete'));
      }
      return Success(_mapper.toDomain(model));
    } on Object catch (e) {
      return Err(DatabaseFailure('softDelete debt failed: $e'));
    }
  }

  @override
  Stream<void> watchChanges() => _dao.watchLazy();
}
