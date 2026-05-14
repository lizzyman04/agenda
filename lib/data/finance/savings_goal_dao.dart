import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/savings_goal_model.dart';
import 'package:isar_community/isar.dart';

/// Raw Isar query access for [SavingsGoalModel].
///
/// Active goals are those without a deletedAt. Contributions are embedded
/// on the goal model — no separate collection.
class SavingsGoalDao {
  const SavingsGoalDao(this._isarService);

  final IsarService _isarService;

  IsarCollection<SavingsGoalModel> get _collection =>
      _isarService.db.collection<SavingsGoalModel>();

  // --- Reads ---

  Future<SavingsGoalModel?> findById(int id) async => _collection.get(id);

  /// Returns all active (non-deleted) savings goals. Limit 500.
  Future<List<SavingsGoalModel>> findAll() async => _collection
      .filter()
      .deletedAtIsNull()
      .limit(500)
      .findAll();

  // --- Writes ---

  Future<int> save(SavingsGoalModel model) async =>
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
      _isarService.db.collection<SavingsGoalModel>().watchLazy();
}
