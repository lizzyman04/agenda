import 'package:agenda/application/tasks/day_planner/day_planner_cubit.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Which 1-3-5 slot a [TaskPickerSheet] is assigning to.
enum SlotSize { big, medium, small }

/// Warning banner shown when a slot-size limit has been exceeded.
class WarningBanner extends StatelessWidget {
  const WarningBanner({required this.l10n, super.key});
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
class TaskPickerSheet extends StatelessWidget {
  const TaskPickerSheet({
    required this.items,
    required this.slotSize,
    super.key,
  });

  final List<Item> items;
  final SlotSize slotSize;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
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
                  case SlotSize.big:
                    cubit.assignBig(item);
                  case SlotSize.medium:
                    cubit.assignMedium(item);
                  case SlotSize.small:
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
