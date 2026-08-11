import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/presentation/tasks/widgets/detail/task_detail_hero_card.dart';
import 'package:agenda/presentation/tasks/widgets/detail/task_detail_info_cards.dart';
import 'package:flutter/material.dart';

/// Scrollable body of the task detail screen: the hero card followed by the
/// conditional Dates/Flags/GTD cards and the finance-link chip.
class TaskDetailBody extends StatelessWidget {
  const TaskDetailBody({required this.item, super.key});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // ── Hero card: title + description + status/priority badges ──
        TaskDetailHeroCard(item: item),
        TaskDetailInfoCards(item: item),
      ],
    );
  }
}
