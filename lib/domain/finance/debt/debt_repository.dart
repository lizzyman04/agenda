import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/debt/debt.dart';

/// Abstract repository interface for debts (to pay and to receive).
///
/// All methods return [AsyncResult] or [Stream] — never throw.
/// Implementations live in lib/infrastructure/finance/.
abstract class DebtRepository {
  /// Creates a new debt and returns it with the assigned Isar id.
  AsyncResult<Debt> createDebt(Debt debt);

  /// Returns the debt with [id], or Err(DatabaseFailure) if not found.
  AsyncResult<Debt> getDebt(int id);

  /// Returns all active (non-deleted) debts.
  AsyncResult<List<Debt>> getDebts();

  /// Overwrites the stored debt with [debt].
  /// The implementation updates updatedAt = DateTime.now() before writing.
  AsyncResult<Debt> updateDebt(Debt debt);

  /// Toggles [isPaid] for the debt with [id].
  /// If isPaid was false → sets to true and records paidAt = DateTime.now().
  /// If isPaid was true → sets to false and clears paidAt.
  /// Returns the updated debt.
  AsyncResult<Debt> togglePaid(int id);

  /// Soft-deletes by setting deletedAt = DateTime.now().
  /// Returns the updated debt (with deletedAt set).
  AsyncResult<Debt> softDelete(int id);

  /// Stream that fires whenever the DebtModel collection changes.
  /// Cubits subscribe via start() and call _reload() on each emission.
  Stream<void> watchChanges();
}
