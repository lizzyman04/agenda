import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/recurring/recurring_payment_model.dart';
import 'package:isar_community/isar.dart';

/// Raw Isar query access for [RecurringPaymentModel].
///
/// isActive is a PAUSE flag, not a delete flag: a paused payment is still a
/// live record the user is tracking. Only deletedAt removes a row from the
/// reads below. Phase 4's notification system reads nextDueDate from this
/// collection and is the one place that should filter on isActive.
class RecurringPaymentDao {
  const RecurringPaymentDao(this._isarService);

  final IsarService _isarService;

  IsarCollection<RecurringPaymentModel> get _collection =>
      _isarService.db.collection<RecurringPaymentModel>();

  // --- Reads ---

  Future<RecurringPaymentModel?> findById(int id) async => _collection.get(id);

  /// Returns every non-deleted recurring payment — paused ones included.
  ///
  /// Deliberately does NOT filter isActive. The list screen renders the only
  /// control that can un-pause a payment, so an active-only query made
  /// pausing an irreversible hide (CR-02). Soft-deleted rows are still
  /// excluded; deletedAt is the delete flag, isActive is not.
  ///
  /// The sort is load-bearing, not cosmetic: Isar returns rows in id order,
  /// so capping without sorting first drops an arbitrary 500 (the CR-04
  /// lesson). Active rows sort first, then soonest-due — which both puts the
  /// paused rows below the live ones and keeps the cap from evicting an
  /// active payment in favour of a paused one.
  ///
  /// Limit 500 — same cap as other list queries.
  Future<List<RecurringPaymentModel>> findAll() async => _collection
      .filter()
      .deletedAtIsNull()
      .sortByIsActiveDesc()
      .thenByNextDueDate()
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
