import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:isar_community/isar.dart';

/// Raw Isar query access for [TransactionModel].
///
/// Every query applies .deletedAtIsNull(). [findAll] is the only capped list
/// query — it is sorted newest-first (.sortByDateDesc()) BEFORE the 500-row
/// cap is applied, so the cap discards the oldest rows, not the newest
/// (CR-04). [findAllForAggregates], [findByMonth], and [findByLinkedGoal]
/// are all deliberately UNCAPPED: they feed money totals (dashboard
/// balance, budget spend, goal progress), not display lists, and a capped
/// total is silently WRONG rather than obviously incomplete (CR-04, BL-01 —
/// see each method's own doc comment).
/// Never use findSync, putSync, deleteSync — async only.
class TransactionDao {
  const TransactionDao(this._isarService);

  final IsarService _isarService;

  IsarCollection<TransactionModel> get _collection =>
      _isarService.db.collection<TransactionModel>();

  // --- Reads ---

  Future<TransactionModel?> findById(int id) async => _collection.get(id);

  /// Returns EVERY active (non-deleted) transaction — deliberately uncapped.
  ///
  /// Dashboard aggregates (balance, net worth, category spend) are
  /// order-independent sums, so no sort is applied; but they must see every
  /// row, so no limit is applied either. A capped aggregate read produces a
  /// silently WRONG total rather than an obviously missing one — that was
  /// CR-04. Use [findAll] for anything that merely renders a list.
  Future<List<TransactionModel>> findAllForAggregates() async =>
      _collection.filter().deletedAtIsNull().findAll();

  /// Returns the NEWEST 500 active (non-deleted) transactions.
  ///
  /// The descending date sort is load-bearing, not cosmetic: Isar returns
  /// rows in id order, so capping without sorting first keeps the OLDEST
  /// 500 and discards everything the user logged most recently (CR-04).
  /// Never aggregate from this — use [findAllForAggregates].
  Future<List<TransactionModel>> findAll() async => _collection
      .filter()
      .deletedAtIsNull()
      .sortByDateDesc()
      .limit(500)
      .findAll();

  /// Returns EVERY expense transaction for a given month and year —
  /// deliberately uncapped.
  ///
  /// Feeds `BudgetCubit._reload`'s per-category spend and over-limit
  /// warning, an order-independent sum, so no sort is applied; but it must
  /// see every row, so no limit is applied either. A capped read here
  /// produces a silently WRONG budget total rather than an obviously
  /// missing one (BL-01, the same failure class as CR-04). Never add
  /// .limit() back to this query.
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
        .findAll();
  }

  /// Returns EVERY active transaction tagged with [goalId] — deliberately
  /// uncapped.
  ///
  /// Feeds `GoalCubit._refreshGoal`'s `taggedCents`, half of
  /// `SavingsGoal.progressPercent` — an order-independent sum, so no sort
  /// is applied; but it must see every row, so no limit is applied either.
  /// A capped read here produces a silently WRONG goal-progress figure
  /// rather than an obviously missing one (BL-01, the same failure class
  /// as CR-04). Never add .limit() back to this query. Used to compute
  /// goal progress from tagged transactions (D-11).
  Future<List<TransactionModel>> findByLinkedGoal(int goalId) async =>
      _collection
          .filter()
          .linkedGoalIdEqualTo(goalId)
          .and()
          .deletedAtIsNull()
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
