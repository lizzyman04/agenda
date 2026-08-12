import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_dao.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_mapper.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment_repository.dart';
import 'package:injectable/injectable.dart';

/// Concrete implementation of [RecurringPaymentRepository].
///
/// Phase 3 stores recurring payments only — no auto-advance of nextDueDate.
/// Phase 4 notification system owns the advance logic.
///
/// Validation:
/// - title must not be empty
/// - amountCents must be > 0
/// - categoryId must be > 0
@LazySingleton(as: RecurringPaymentRepository)
class RecurringPaymentRepositoryImpl implements RecurringPaymentRepository {
  const RecurringPaymentRepositoryImpl(this._dao, this._mapper);

  final RecurringPaymentDao _dao;
  final RecurringPaymentMapper _mapper;

  @override
  AsyncResult<RecurringPayment> createPayment(RecurringPayment payment) async {
    try {
      if (payment.title.isEmpty) {
        return const Err(ValidationFailure('title must not be empty'));
      }
      if (payment.amountCents <= 0) {
        return const Err(
          ValidationFailure('amountCents must be greater than zero'),
        );
      }
      if (payment.categoryId <= 0) {
        return const Err(
          ValidationFailure('categoryId must be a valid reference'),
        );
      }
      final now = DateTime.now();
      final toSave = payment.copyWith(createdAt: now, updatedAt: now);
      final model = _mapper.toModel(toSave);
      final id = await _dao.save(model);
      final saved = await _dao.findById(id);
      return Success(_mapper.toDomain(saved!));
    } on Object catch (e) {
      return Err(DatabaseFailure('createPayment failed: $e'));
    }
  }

  @override
  AsyncResult<RecurringPayment> getPayment(int id) async {
    try {
      final model = await _dao.findById(id);
      if (model == null) {
        return Err(DatabaseFailure('RecurringPayment $id not found'));
      }
      return Success(_mapper.toDomain(model));
    } on Object catch (e) {
      return Err(DatabaseFailure('getPayment failed: $e'));
    }
  }

  @override
  AsyncResult<List<RecurringPayment>> getActivePayments() async {
    try {
      final models = await _dao.findAll();
      return Success(models.map(_mapper.toDomain).toList());
    } on Object catch (e) {
      return Err(DatabaseFailure('getActivePayments failed: $e'));
    }
  }

  @override
  AsyncResult<RecurringPayment> updatePayment(RecurringPayment payment) async {
    try {
      if (payment.title.isEmpty) {
        return const Err(ValidationFailure('title must not be empty'));
      }
      if (payment.amountCents <= 0) {
        return const Err(
          ValidationFailure('amountCents must be greater than zero'),
        );
      }
      final updated = payment.copyWith(updatedAt: DateTime.now());
      final model = _mapper.toModel(updated);
      await _dao.save(model);
      return Success(updated);
    } on Object catch (e) {
      return Err(DatabaseFailure('updatePayment failed: $e'));
    }
  }

  @override
  AsyncResult<RecurringPayment> softDelete(int id) async {
    try {
      await _dao.softDelete(id);
      final model = await _dao.findById(id);
      if (model == null) {
        return Err(
          DatabaseFailure('RecurringPayment $id not found after softDelete'),
        );
      }
      return Success(_mapper.toDomain(model));
    } on Object catch (e) {
      return Err(DatabaseFailure('softDelete payment failed: $e'));
    }
  }
}
