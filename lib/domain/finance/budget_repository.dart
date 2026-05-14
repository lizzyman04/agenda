import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/budget.dart';

/// Abstract repository interface for monthly category budgets.
///
/// All methods return [AsyncResult] — never throw.
/// Implementations live in lib/infrastructure/finance/.
///
/// Note: This repository is not reactive — budgets are loaded on demand.
/// No [watchChanges] stream is provided.
abstract class BudgetRepository {
  /// Returns the budget for [categoryId] in the given [month] and [year].
  ///
  /// Returns null (Success<Budget?>) when no limit has been set for this
  /// category/month combination — null means "no limit", not a DB error.
  AsyncResult<Budget?> getForCategory(int categoryId, int month, int year);

  /// Returns all budgets set for the given [month] and [year].
  AsyncResult<List<Budget>> getForMonth(int month, int year);

  /// Creates or updates the budget limit for [categoryId] in [month]/[year].
  ///
  /// This is an upsert — if a budget already exists for this
  /// (categoryId, month, year) triplet, it is updated in place.
  AsyncResult<Budget> setLimit(
    int categoryId,
    int month,
    int year,
    int limitCents,
  );

  /// Removes the budget limit for [categoryId] in [month]/[year].
  /// After deletion, [getForCategory] returns null for that slot.
  AsyncResult<void> delete(int categoryId, int month, int year);
}
