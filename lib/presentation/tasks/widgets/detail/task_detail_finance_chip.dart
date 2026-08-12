import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Chip linking to the goal or debt this task funds, when one is linked.
/// Renders nothing otherwise, so callers can place it unconditionally in a
/// `Column`.
class TaskDetailFinanceChip extends StatelessWidget {
  const TaskDetailFinanceChip({required this.item, super.key});

  final Item item;

  @override
  Widget build(BuildContext context) {
    if (item.linkedGoalId == null && item.linkedDebtId == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isGoal = item.linkedGoalId != null;
    final kindLabel = isGoal ? l10n.goalsTabLabel : l10n.debtsTabLabel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Wrap(
        children: [
          ActionChip(
            avatar: const Icon(Icons.link, size: 16),
            label: Text(
              '${l10n.linkedTo} $kindLabel '
              '#${item.linkedGoalId ?? item.linkedDebtId}',
            ),
            backgroundColor: cs.secondaryContainer,
            onPressed: () {
              // Navigation to finance detail is deferred to plan 03-05 when
              // deep-link routing is set up.
            },
          ),
        ],
      ),
    );
  }
}
