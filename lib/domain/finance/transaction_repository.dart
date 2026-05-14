import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/transaction.dart';

/// Abstract repository interface for financial transactions.
///
/// All methods return [AsyncResult] or [Stream] — never throw.
/// Implementations live in lib/infrastructure/finance/.
abstract class TransactionRepository {
  /// Creates a new transaction and returns it with the assigned Isar id.
  AsyncResult<Transaction> createTransaction(Transaction transaction);

  /// Returns the transaction with [id], or Err(DatabaseFailure) if not found.
  AsyncResult<Transaction> getTransaction(int id);

  /// Returns all active (non-deleted) transactions. Limit 500.
  AsyncResult<List<Transaction>> getTransactions();

  /// Returns expense transactions for the given [month] and [year].
  /// Used for budget progress and chart rendering (D-09).
  AsyncResult<List<Transaction>> getByMonth(int month, int year);

  /// Returns all active transactions tagged with [goalId].
  /// Used to compute goal progress from tagged transactions (D-11).
  AsyncResult<List<Transaction>> getByLinkedGoal(int goalId);

  /// Overwrites the stored transaction with [transaction].
  /// The implementation updates updatedAt = DateTime.now() before writing.
  AsyncResult<Transaction> updateTransaction(Transaction transaction);

  /// Soft-deletes by setting deletedAt = DateTime.now().
  /// Returns the updated transaction (with deletedAt set).
  AsyncResult<Transaction> softDelete(int id);

  /// Stream that fires whenever the TransactionModel collection changes.
  /// Cubits subscribe via start() and call _reload() on each emission.
  Stream<void> watchChanges();
}
