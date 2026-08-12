import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';

/// Abstract repository interface for transaction categories.
///
/// All methods return [AsyncResult] — never throw.
/// Implementations live in lib/infrastructure/finance/.
///
/// Note: This repository is not reactive — categories change infrequently
/// and are loaded on demand. No [watchChanges] stream is provided.
abstract class TransactionCategoryRepository {
  /// Returns all categories (default and user-defined).
  AsyncResult<List<TransactionCategory>> getAll();

  /// Returns all categories of the given [type] (income or expense).
  AsyncResult<List<TransactionCategory>> getByType(TransactionType type);

  /// Creates a new user-defined category (isDefault = false).
  AsyncResult<TransactionCategory> create(TransactionCategory category);

  /// Updates a user-defined category.
  /// Default categories (isDefault = true) must be rejected by the
  /// implementation.
  AsyncResult<TransactionCategory> update(TransactionCategory category);

  /// Hard-deletes a user-defined category by [id].
  /// Caller must verify isDefault == false before calling.
  /// Default categories must not be deletable.
  AsyncResult<void> delete(int id);
}
