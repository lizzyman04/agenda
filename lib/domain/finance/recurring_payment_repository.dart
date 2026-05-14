import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/recurring_payment.dart';

/// Abstract repository interface for recurring payments.
///
/// All methods return [AsyncResult] — never throw.
/// Implementations live in lib/infrastructure/finance/.
///
/// Note: This repository is not reactive — recurring payments are loaded
/// on demand. No [watchChanges] stream is provided.
abstract class RecurringPaymentRepository {
  /// Creates a new recurring payment and returns it with the assigned Isar id.
  AsyncResult<RecurringPayment> createPayment(RecurringPayment payment);

  /// Returns the recurring payment with [id], or Err(DatabaseFailure) if not found.
  AsyncResult<RecurringPayment> getPayment(int id);

  /// Returns all active (non-deleted, isActive=true) recurring payments.
  AsyncResult<List<RecurringPayment>> getActivePayments();

  /// Overwrites the stored payment with [payment].
  /// The implementation updates updatedAt = DateTime.now() before writing.
  AsyncResult<RecurringPayment> updatePayment(RecurringPayment payment);

  /// Soft-deletes by setting deletedAt = DateTime.now().
  /// Returns the updated payment (with deletedAt set).
  AsyncResult<RecurringPayment> softDelete(int id);
}
