import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/budget/budget_model.dart';
import 'package:isar_community/isar.dart';

/// Raw Isar query access for [BudgetModel].
///
/// One record per (categoryId, month, year) — enforced by composite unique
/// index on BudgetModel. Use [findByCategoryMonthYear] for upsert lookups.
class BudgetDao {
  const BudgetDao(this._isarService);

  final IsarService _isarService;

  IsarCollection<BudgetModel> get _collection =>
      _isarService.db.collection<BudgetModel>();

  // --- Reads ---

  Future<BudgetModel?> findById(int id) async => _collection.get(id);

  /// Returns the budget for a specific category in a given month/year.
  ///
  /// Returns null when no budget limit has been set for this combination.
  Future<BudgetModel?> findByCategoryMonthYear(
    int categoryId,
    int month,
    int year,
  ) async {
    final results = await _collection
        .filter()
        .categoryIdEqualTo(categoryId)
        .and()
        .monthEqualTo(month)
        .and()
        .yearEqualTo(year)
        .limit(1)
        .findAll();
    return results.isEmpty ? null : results.first;
  }

  /// Returns all budgets set for the given month and year.
  Future<List<BudgetModel>> findByMonth(int month, int year) async =>
      _collection
          .filter()
          .monthEqualTo(month)
          .and()
          .yearEqualTo(year)
          .limit(500)
          .findAll();

  // --- Writes ---

  Future<int> save(BudgetModel model) async =>
      _isarService.db.writeTxn(() => _collection.put(model));

  /// Deletes the budget for a specific (categoryId, month, year) combination.
  Future<void> deleteWhere(int categoryId, int month, int year) async {
    final existing = await findByCategoryMonthYear(categoryId, month, year);
    if (existing == null) return;
    await _isarService.db.writeTxn(() => _collection.delete(existing.id));
  }
}
