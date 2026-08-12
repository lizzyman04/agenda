import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/finance/goal_mapper.dart';
import 'package:agenda/data/finance/savings_goal_dao.dart';
import 'package:agenda/data/finance/savings_goal_model.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:agenda/domain/finance/goal/savings_goal_contribution.dart';
import 'package:injectable/injectable.dart';

/// Concrete implementation of [GoalRepository].
///
/// Contributions are stored as an embedded list on SavingsGoalModel.
/// addContribution appends to the growable list and saves in one write.
///
/// Validation (T-03-02-04):
/// - Goal title must not be empty
/// - contribution.amountCents must be > 0 in addContribution
@LazySingleton(as: GoalRepository)
class GoalRepositoryImpl implements GoalRepository {
  const GoalRepositoryImpl(this._dao, this._mapper);

  final SavingsGoalDao _dao;
  final GoalMapper _mapper;

  @override
  AsyncResult<SavingsGoal> createGoal(SavingsGoal goal) async {
    try {
      if (goal.title.isEmpty) {
        return const Err(ValidationFailure('title must not be empty'));
      }
      if (goal.targetAmountCents <= 0) {
        return const Err(
          ValidationFailure('amountCents must be greater than zero'),
        );
      }
      final now = DateTime.now();
      final toSave = goal.copyWith(createdAt: now, updatedAt: now);
      final model = _mapper.toModel(toSave);
      final id = await _dao.save(model);
      final saved = await _dao.findById(id);
      return Success(_mapper.toDomain(saved!));
    } on Object catch (e) {
      return Err(DatabaseFailure('createGoal failed: $e'));
    }
  }

  @override
  AsyncResult<SavingsGoal> getGoal(int id) async {
    try {
      final model = await _dao.findById(id);
      if (model == null) {
        return Err(DatabaseFailure('Goal $id not found'));
      }
      return Success(_mapper.toDomain(model));
    } on Object catch (e) {
      return Err(DatabaseFailure('getGoal failed: $e'));
    }
  }

  @override
  AsyncResult<List<SavingsGoal>> getActiveGoals() async {
    try {
      final models = await _dao.findAll();
      return Success(models.map(_mapper.toDomain).toList());
    } on Object catch (e) {
      return Err(DatabaseFailure('getActiveGoals failed: $e'));
    }
  }

  @override
  AsyncResult<SavingsGoal> updateGoal(SavingsGoal goal) async {
    try {
      if (goal.title.isEmpty) {
        return const Err(ValidationFailure('title must not be empty'));
      }
      final updated = goal.copyWith(updatedAt: DateTime.now());
      final model = _mapper.toModel(updated);
      await _dao.save(model);
      return Success(updated);
    } on Object catch (e) {
      return Err(DatabaseFailure('updateGoal failed: $e'));
    }
  }

  @override
  AsyncResult<SavingsGoal> addContribution(
    int goalId,
    SavingsGoalContribution contribution,
  ) async {
    try {
      // T-03-02-04: validate contribution amount
      if (contribution.amountCents <= 0) {
        return const Err(
          ValidationFailure('amountCents must be greater than zero'),
        );
      }

      final model = await _dao.findById(goalId);
      if (model == null) {
        return Err(DatabaseFailure('Goal $goalId not found'));
      }

      // Rebuild the list rather than mutating it in place. The field
      // initializer in SavingsGoalModel is growable, but that only applies to
      // freshly constructed models: Isar's generated deserializer REPLACES
      // `contributions` with the fixed-length list returned by
      // readObjectList, so `.add()` on a model loaded via findById throws
      // "Unsupported operation: Cannot add to a fixed-length list".
      model.contributions = [
        ...model.contributions,
        GoalContribution()
          ..amountCents = contribution.amountCents
          ..date = contribution.date
          ..note = contribution.note,
      ];
      model.updatedAt = DateTime.now();

      await _dao.save(model);
      final saved = await _dao.findById(goalId);
      return Success(_mapper.toDomain(saved!));
    } on Object catch (e) {
      return Err(DatabaseFailure('addContribution failed: $e'));
    }
  }

  @override
  AsyncResult<SavingsGoal> softDelete(int id) async {
    try {
      await _dao.softDelete(id);
      final model = await _dao.findById(id);
      if (model == null) {
        return Err(DatabaseFailure('Goal $id not found after softDelete'));
      }
      return Success(_mapper.toDomain(model));
    } on Object catch (e) {
      return Err(DatabaseFailure('softDelete goal failed: $e'));
    }
  }

  @override
  Stream<void> watchChanges() => _dao.watchLazy();
}
