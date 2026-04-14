import 'package:agenda/application/tasks/day_planner/day_planner_state.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Manages the 1-3-5 Rule day planner session (TASK-08).
///
/// State is in-memory only — does NOT persist slot assignments to Isar.
/// Factory (ephemeral per session) — DayPlannerCubit is NOT a singleton.
///
/// Slot limit violations emit a warning via [DayPlannerState.slotLimitWarning]
/// but DO NOT block the assignment (soft constraint — CONTEXT.md decision).
@injectable
class DayPlannerCubit extends Cubit<DayPlannerState> {
  DayPlannerCubit() : super(const DayPlannerState());

  /// Assigns [item] to the big task slot.
  ///
  /// If the slot is already full, the new item replaces the previous one
  /// and slotLimitWarning is set true.
  void assignBig(Item item) {
    final warning = state.isBigSlotFull;
    emit(DayPlannerState(
      bigTask: item,
      mediumTasks: state.mediumTasks,
      smallTasks: state.smallTasks,
      slotLimitWarning: warning,
    ));
  }

  /// Assigns [item] to the medium tasks slot list.
  ///
  /// Soft warning when already at AppConstants.rule135MediumTasks (3).
  void assignMedium(Item item) {
    final updated = [...state.mediumTasks, item];
    final warning = state.areMediumSlotsFull;
    emit(DayPlannerState(
      bigTask: state.bigTask,
      mediumTasks: updated,
      smallTasks: state.smallTasks,
      slotLimitWarning: warning,
    ));
  }

  /// Assigns [item] to the small tasks slot list.
  ///
  /// Soft warning when already at AppConstants.rule135SmallTasks (5).
  void assignSmall(Item item) {
    final updated = [...state.smallTasks, item];
    final warning = state.areSmallSlotsFull;
    emit(DayPlannerState(
      bigTask: state.bigTask,
      mediumTasks: state.mediumTasks,
      smallTasks: updated,
      slotLimitWarning: warning,
    ));
  }

  /// Removes an item from whichever slot it occupies by [itemId].
  void remove(int itemId) {
    final isBig = state.bigTask?.id == itemId;
    emit(DayPlannerState(
      bigTask: isBig ? null : state.bigTask,
      mediumTasks: state.mediumTasks.where((i) => i.id != itemId).toList(),
      smallTasks: state.smallTasks.where((i) => i.id != itemId).toList(),
    ));
  }

  /// Clears all slot assignments and resets warning.
  void clearAll() => emit(const DayPlannerState());
}
