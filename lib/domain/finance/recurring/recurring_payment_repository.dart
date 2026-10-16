import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment.dart';

/// Abstract repository interface for recurring payments.
///
/// All methods return [AsyncResult] — never throw.
/// Implementations live in lib/infrastructure/finance/.
///
/// Reactive through [watchChanges]: payment writes are observable so the
/// reminder planner can re-plan when a payment is added, edited or paused.
abstract class RecurringPaymentRepository {
  /// Creates a new recurring payment and returns it with the assigned Isar id.
  AsyncResult<RecurringPayment> createPayment(RecurringPayment payment);

  /// Returns the recurring payment with [id], or Err(DatabaseFailure)
  /// if not found.
  AsyncResult<RecurringPayment> getPayment(int id);

  /// Returns all non-deleted recurring payments, paused ones included.
  ///
  /// Renamed from `getActivePayments` when CR-02 was closed: the query
  /// behind it stopped filtering isActive, and a name promising "active"
  /// while returning paused rows is how a total silently starts counting
  /// the wrong thing. Anything that must see only unpaused payments has to
  /// say so at its own call site.
  AsyncResult<List<RecurringPayment>> getPayments();

  /// Overwrites the stored payment with [payment].
  /// The implementation updates updatedAt = DateTime.now() before writing.
  AsyncResult<RecurringPayment> updatePayment(RecurringPayment payment);

  /// Soft-deletes by setting deletedAt = DateTime.now().
  /// Returns the updated payment (with deletedAt set).
  AsyncResult<RecurringPayment> softDelete(int id);

  /// Stream that fires whenever the RecurringPaymentModel collection changes
  /// (any payment created, edited, paused, resumed or deleted).
  ///
  /// The event carries no payload: re-read with [getPayments].
  Stream<void> watchChanges();
}
