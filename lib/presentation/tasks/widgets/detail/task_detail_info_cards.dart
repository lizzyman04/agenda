import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/presentation/tasks/widgets/detail/task_detail_dates_card.dart';
import 'package:agenda/presentation/tasks/widgets/detail/task_detail_finance_chip.dart';
import 'package:agenda/presentation/tasks/widgets/detail/task_detail_flags_gtd.dart';
import 'package:flutter/material.dart';

/// Conditional Dates/Flags/GTD cards and the finance-link chip, rendered
/// below the hero card when the task carries that kind of data. Each child
/// widget decides for itself whether it has anything to show.
class TaskDetailInfoCards extends StatelessWidget {
  const TaskDetailInfoCards({required this.item, super.key});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TaskDetailDatesCard(item: item),
        TaskDetailFlagsCard(item: item),
        TaskDetailGtdCard(item: item),
        TaskDetailFinanceChip(item: item),
      ],
    );
  }
}
