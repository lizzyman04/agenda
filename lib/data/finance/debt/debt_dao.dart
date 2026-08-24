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

  /// Returns EVERY active (non-deleted) debt — deliberately uncapped.
  ///
  /// Dual-use: feeds list screens/pickers AND
  /// `HomeDashboardCubit._reload`'s `computeDebtTotal`, an
  /// order-independent sum that folds into `computeNetWorth`. A capped read
  /// here produces a silently WRONG net-worth total rather than an
  /// obviously missing one (BL-01, the same failure class as CR-04). Never
  /// add .limit() back to this query.
  Future<List<DebtModel>> findAll() async =>
      _collection.filter().deletedAtIsNull().findAll();

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
