import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:equatable/equatable.dart';

/// State for the 1-3-5 Rule day planner (TASK-08).
///
/// Slot counts are read from AppConstants — never hardcoded.
/// slotLimitWarning is true when any slot is over capacity (soft warning only).
final class DayPlannerState extends Equatable {
  const DayPlannerState({
    this.bigTask,
    this.mediumTasks = const [],
    this.smallTasks = const [],
    this.slotLimitWarning = false,
  });

  /// Max 1 big task — AppConstants.rule135BigTasks.
  final Item? bigTask;

  /// Max 3 medium tasks — AppConstants.rule135MediumTasks.
  final List<Item> mediumTasks;

  /// Max 5 small tasks — AppConstants.rule135SmallTasks.
  final List<Item> smallTasks;

  /// True when an assignment exceeds a slot limit (soft warning; not a block).
  final bool slotLimitWarning;

  bool get isBigSlotFull => bigTask != null;
  bool get areMediumSlotsFull =>
      mediumTasks.length >= AppConstants.rule135MediumTasks;
  bool get areSmallSlotsFull =>
      smallTasks.length >= AppConstants.rule135SmallTasks;

  @override
  List<Object?> get props => [
        bigTask,
        mediumTasks,
        smallTasks,
        slotLimitWarning,
      ];
}
