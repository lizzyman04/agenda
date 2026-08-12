import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:isar_community/isar.dart';

/// Raw Isar query access for [TransactionModel].
///
/// All list queries apply .deletedAtIsNull() and .limit(500).
/// Never use findSync, putSync, deleteSync — async only.
class TransactionDao {
  const TransactionDao(this._isarService);

  final IsarService _isarService;

  IsarCollection<TransactionModel> get _collection =>
      _isarService.db.collection<TransactionModel>();

  // --- Reads ---

  Future<TransactionModel?> findById(int id) async => _collection.get(id);

  /// Returns all active (non-deleted) transactions. Limit 500.
  Future<List<TransactionModel>> findAll() async => _collection
      .filter()
      .deletedAtIsNull()
      .limit(500)
      .findAll();

  /// Returns expense transactions for a given month and year.
  ///
  /// Used for budget progress computation and chart rendering.
  /// Exclusive upper bound: [DateTime(year, month + 1, 1)].
  Future<List<TransactionModel>> findByMonth(int month, int year) async {
    final from = DateTime(year, month);
    final to = DateTime(year, month + 1);
    return _collection
        .filter()
        .deletedAtIsNull()
        .and()
        .typeEqualTo(TransactionType.expense)
        .and()
        .dateBetween(from, to, includeUpper: false)
        .limit(500)
        .findAll();
  }

  /// Returns all active transactions tagged with [goalId].
  ///
  /// Used to compute goal progress from tagged transactions (D-11).
  Future<List<TransactionModel>> findByLinkedGoal(int goalId) async =>
      _collection
          .filter()
          .linkedGoalIdEqualTo(goalId)
          .and()
          .deletedAtIsNull()
          .limit(500)
          .findAll();

  // --- Writes ---

  Future<int> save(TransactionModel model) async =>
      _isarService.db.writeTxn(() => _collection.put(model));

  Future<void> softDelete(int id) async {
    await _isarService.db.writeTxn(() async {
      final model = await _collection.get(id);
      if (model == null) return;
      model.deletedAt = DateTime.now();
      await _collection.put(model);
    });
  }

  // --- Watch ---

  Stream<void> watchLazy() =>
      _isarService.db.collection<TransactionModel>().watchLazy();
}
