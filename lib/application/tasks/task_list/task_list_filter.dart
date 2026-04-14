import 'package:agenda/domain/tasks/eisenhower_quadrant.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:equatable/equatable.dart';

/// Multi-criteria filter for the task list (TASK-12).
///
/// All fields are optional — null means "no filter on this axis".
/// Passed to ItemRepository.filterItems() by TaskListCubit.
class TaskListFilter extends Equatable {
  const TaskListFilter({
    this.itemType,
    this.quadrant,
    this.gtdContext,
    this.dueDateFrom,
    this.dueDateTo,
    this.projectId,
    this.showCompleted = false,
  });

  final ItemType? itemType;
  final EisenhowerQuadrant? quadrant;
  final String? gtdContext;
  final DateTime? dueDateFrom;
  final DateTime? dueDateTo;

  /// Filter to a specific project's subtasks.
  final int? projectId;

  /// When false (default), completed items are excluded.
  final bool showCompleted;

  /// Convenience constant: no filters applied.
  static const empty = TaskListFilter();

  @override
  List<Object?> get props => [
        itemType,
        quadrant,
        gtdContext,
        dueDateFrom,
        dueDateTo,
        projectId,
        showCompleted,
      ];
}
