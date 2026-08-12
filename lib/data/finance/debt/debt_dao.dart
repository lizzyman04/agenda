import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/debt/debt_model.dart';
import 'package:isar_community/isar.dart';

/// Raw Isar query access for [DebtModel].
///
/// Active debts are those without a deletedAt. Soft delete pattern.
class DebtDao {
  const DebtDao(this._isarService);

  final IsarService _isarService;

  IsarCollection<DebtModel> get _collection =>
      _isarService.db.collection<DebtModel>();

  // --- Reads ---

  Future<DebtModel?> findById(int id) async => _collection.get(id);

  /// Returns all active (non-deleted) debts. Limit 500.
  Future<List<DebtModel>> findAll() async => _collection
      .filter()
      .deletedAtIsNull()
      .limit(500)
      .findAll();

  // --- Writes ---

  Future<int> save(DebtModel model) async =>
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
      _isarService.db.collection<DebtModel>().watchLazy();
}
