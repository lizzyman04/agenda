import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_model.dart';
import 'package:isar_community/isar.dart';

/// Raw Isar query access for [RecurringPaymentModel].
///
/// Active payments are those with isActive == true and no deletedAt.
/// Phase 4 notification system reads nextDueDate from this collection.
class RecurringPaymentDao {
  const RecurringPaymentDao(this._isarService);

  final IsarService _isarService;

  IsarCollection<RecurringPaymentModel> get _collection =>
      _isarService.db.collection<RecurringPaymentModel>();

  // --- Reads ---

  Future<RecurringPaymentModel?> findById(int id) async => _collection.get(id);

  /// Returns all active (isActive == true, non-deleted) recurring payments.
  ///
  /// Limit 500 — same cap as other list queries.
  Future<List<RecurringPaymentModel>> findAll() async => _collection
      .filter()
      .isActiveEqualTo(true)
      .and()
      .deletedAtIsNull()
      .limit(500)
      .findAll();

  // --- Writes ---

  Future<int> save(RecurringPaymentModel model) async =>
      _isarService.db.writeTxn(() => _collection.put(model));

  Future<void> softDelete(int id) async {
    await _isarService.db.writeTxn(() async {
      final model = await _collection.get(id);
      if (model == null) return;
      model.deletedAt = DateTime.now();
      await _collection.put(model);
    });
  }
}
