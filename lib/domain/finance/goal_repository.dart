import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:agenda/domain/finance/savings_goal_contribution.dart';

/// Abstract repository interface for savings goals.
///
/// All methods return [AsyncResult] or [Stream] — never throw.
/// Implementations live in lib/infrastructure/finance/.
abstract class GoalRepository {
  /// Creates a new savings goal and returns it with the assigned Isar id.
  AsyncResult<SavingsGoal> createGoal(SavingsGoal goal);

  /// Returns the goal with [id], or Err(DatabaseFailure) if not found.
  AsyncResult<SavingsGoal> getGoal(int id);

  /// Returns all active (non-deleted) savings goals.
  AsyncResult<List<SavingsGoal>> getActiveGoals();

  /// Overwrites the stored goal with [goal].
  /// The implementation updates updatedAt = DateTime.now() before writing.
  AsyncResult<SavingsGoal> updateGoal(SavingsGoal goal);

  /// Appends [contribution] to the goal's contribution list and saves.
  /// Returns the updated goal with the new contribution included.
  AsyncResult<SavingsGoal> addContribution(
    int goalId,
    SavingsGoalContribution contribution,
  );

  /// Soft-deletes by setting deletedAt = DateTime.now().
  /// Returns the updated goal (with deletedAt set).
  AsyncResult<SavingsGoal> softDelete(int id);

  /// Stream that fires whenever the SavingsGoalModel collection changes.
  /// Cubits subscribe via start() and call _reload() on each emission.
  Stream<void> watchChanges();
}
