import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/category/transaction_category_model.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:isar_community/isar.dart';

/// Raw Isar query access for [TransactionCategoryModel].
///
/// Categories are NOT soft-deleted — default categories are undeletable,
/// custom categories are hard-deleted. No deletedAt filter here.
class TransactionCategoryDao {
  const TransactionCategoryDao(this._isarService);

  final IsarService _isarService;

  IsarCollection<TransactionCategoryModel> get _collection =>
      _isarService.db.collection<TransactionCategoryModel>();

  // --- Reads ---

  Future<TransactionCategoryModel?> findById(int id) async =>
      _collection.get(id);

  /// Returns all categories (default and user-defined).
  Future<List<TransactionCategoryModel>> findAll() async =>
      _collection.filter().idGreaterThan(0).limit(500).findAll();

  /// Returns all categories of the given [type] (income or expense).
  Future<List<TransactionCategoryModel>> findByType(
    TransactionType type,
  ) async =>
      _collection
          .filter()
          .typeEqualTo(type)
          .limit(500)
          .findAll();

  /// Total count of all categories — used for idempotency guard in seeding.
  Future<int> count() async => _collection.count();

  // --- Writes ---

  Future<int> save(TransactionCategoryModel model) async =>
      _isarService.db.writeTxn(() => _collection.put(model));

  Future<void> putAll(List<TransactionCategoryModel> models) async =>
      _isarService.db.writeTxn(() => _collection.putAll(models));

  /// Hard-deletes a category by [id].
  ///
  /// Only call for custom (isDefault == false) categories.
  /// Default categories must not be deleted — enforce in the repository impl.
  Future<void> hardDelete(int id) async =>
      _isarService.db.writeTxn(() => _collection.delete(id));
}
