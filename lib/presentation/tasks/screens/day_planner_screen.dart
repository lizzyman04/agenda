import 'package:agenda/application/tasks/day_planner/day_planner_cubit.dart';
import 'package:agenda/application/tasks/day_planner/day_planner_state.dart';
import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/widgets/slot_section.dart';
import 'package:agenda/presentation/tasks/widgets/task_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 1-3-5 Day Planner screen.
///
/// Renders 3 [SlotSection] widgets (big / medium / small) driven by
/// [DayPlannerCubit] state. Shows a global warning banner at the top
/// when [DayPlannerState.slotLimitWarning] is true.
class DayPlannerScreen extends StatelessWidget {
  const DayPlannerScreen({super.key});

  void _showTaskPicker(
    BuildContext context,
    SlotSize slotSize,
    List<Item> availableItems,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: context.read<DayPlannerCubit>(),
          child: TaskPickerSheet(
            items: availableItems,
            slotSize: slotSize,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dayPlannerTitle),
      ),
      body: BlocBuilder<DayPlannerCubit, DayPlannerState>(
        builder: (context, plannerState) {
          // Available tasks come from TaskListCubit (if provided in tree)
          final taskListState = context.watch<TaskListCubit>().state;
          final allItems = switch (taskListState) {
            TaskListLoaded(:final items) => items,
            TaskListWithPendingUndo(:final items) => items,
            _ => <Item>[],
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Global warning banner
              if (plannerState.slotLimitWarning)
                WarningBanner(l10n: l10n),

              // Slot sections
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SlotSection(
                        label: l10n.bigTask,
                        maxSlots: AppConstants.rule135BigTasks,
                        currentItems: plannerState.bigTask != null
                            ? [plannerState.bigTask!]
                            : [],
                        isOverCapacity: false,
                        onTapAdd: () => _showTaskPicker(
                          context,
                          SlotSize.big,
                          allItems,
                        ),
                        onRemove: (id) =>
                            context.read<DayPlannerCubit>().remove(id),
                      ),
                      SlotSection(
                        label: l10n.mediumTasks,
                        maxSlots: AppConstants.rule135MediumTasks,
                        currentItems: plannerState.mediumTasks,
                        isOverCapacity: plannerState.areMediumSlotsFull,
                        onTapAdd: () => _showTaskPicker(
                          context,
                          SlotSize.medium,
                          allItems,
                        ),
                        onRemove: (id) =>
                            context.read<DayPlannerCubit>().remove(id),
                      ),
                      SlotSection(
                        label: l10n.smallTasks,
                        maxSlots: AppConstants.rule135SmallTasks,
                        currentItems: plannerState.smallTasks,
                        isOverCapacity: plannerState.areSmallSlotsFull,
                        onTapAdd: () => _showTaskPicker(
                          context,
                          SlotSize.small,
                          allItems,
                        ),
                        onRemove: (id) =>
                            context.read<DayPlannerCubit>().remove(id),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
