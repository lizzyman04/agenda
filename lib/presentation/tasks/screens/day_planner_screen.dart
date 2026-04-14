import 'package:agenda/application/tasks/day_planner/day_planner_cubit.dart';
import 'package:agenda/application/tasks/day_planner/day_planner_state.dart';
import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/widgets/slot_section.dart';
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
    _SlotSize slotSize,
    List<Item> availableItems,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: context.read<DayPlannerCubit>(),
          child: _TaskPickerSheet(
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
                _WarningBanner(l10n: l10n),

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
                          _SlotSize.big,
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
                          _SlotSize.medium,
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
                          _SlotSize.small,
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

enum _SlotSize { big, medium, small }

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.amber.shade200,
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.amber.shade900, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.slotLimitWarning,
              style: TextStyle(
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for picking a task to assign to a slot.
class _TaskPickerSheet extends StatelessWidget {
  const _TaskPickerSheet({
    required this.items,
    required this.slotSize,
  });

  final List<Item> items;
  final _SlotSize slotSize;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      builder: (context, scrollController) {
        if (items.isEmpty) {
          return const Center(child: Icon(Icons.inbox_outlined, size: 48));
        }
        return ListView.builder(
          controller: scrollController,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              title: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                final cubit = context.read<DayPlannerCubit>();
                switch (slotSize) {
                  case _SlotSize.big:
                    cubit.assignBig(item);
                  case _SlotSize.medium:
                    cubit.assignMedium(item);
                  case _SlotSize.small:
                    cubit.assignSmall(item);
                }
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }
}
