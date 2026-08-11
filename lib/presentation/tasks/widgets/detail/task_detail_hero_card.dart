import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/domain/tasks/size_category.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/widgets/detail/task_detail_chips.dart';
import 'package:flutter/material.dart';

/// Status/priority/size chip row + title + optional description at the top
/// of the task detail screen.
class TaskDetailHeroCard extends StatelessWidget {
  const TaskDetailHeroCard({required this.item, super.key});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status chip row
            Row(
              children: [
                StatusChip(
                  label: item.isCompleted
                      ? l10n.statusCompleted
                      : l10n.statusPending,
                  color: item.isCompleted ? Colors.green : cs.outline,
                  filled: item.isCompleted,
                ),
                const SizedBox(width: 8),
                PriorityChip(
                  label: _priorityLabel(item.priority, l10n),
                  color: _priorityColor(item.priority, cs),
                ),
                const SizedBox(width: 8),
                SizeChip(
                  label: _sizeLabel(item.sizeCategory, l10n),
                  cs: cs,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Title
            Text(item.title, style: theme.textTheme.headlineSmall),
            // Description
            if (item.description != null && item.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                item.description!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _priorityLabel(Priority p, AppLocalizations l10n) => switch (p) {
      Priority.low => l10n.priorityLow,
      Priority.medium => l10n.priorityMedium,
      Priority.high => l10n.priorityHigh,
      Priority.critical => l10n.priorityCritical,
      Priority.urgent => l10n.priorityUrgent,
    };

String _sizeLabel(SizeCategory s, AppLocalizations l10n) => switch (s) {
      SizeCategory.big => l10n.sizeBig,
      SizeCategory.medium => l10n.sizeMedium,
      SizeCategory.small => l10n.sizeSmall,
      SizeCategory.none => l10n.sizeNone,
    };

Color _priorityColor(Priority p, ColorScheme cs) => switch (p) {
      Priority.urgent || Priority.critical => cs.error,
      Priority.high => Colors.orange,
      Priority.medium => cs.primary,
      Priority.low => cs.outline,
    };
