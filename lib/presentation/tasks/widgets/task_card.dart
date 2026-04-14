import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/priority.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Reusable card for a single [Item].
///
/// Displays title, priority chip, due date, Eisenhower quadrant label,
/// a completion checkbox, and a delete icon button.
///
/// Does NOT import Isar — only domain types are used.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.item,
    required this.onComplete,
    required this.onDelete,
    required this.onTap,
  });

  final Item item;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  static const _dateFormat = 'dd/MM/yyyy';

  Color _priorityColor(BuildContext context, Priority priority) {
    final cs = Theme.of(context).colorScheme;
    return switch (priority) {
      Priority.urgent => cs.error,
      Priority.critical => cs.errorContainer,
      Priority.high => cs.tertiaryContainer,
      Priority.medium => cs.secondaryContainer,
      Priority.low => cs.surfaceContainerHighest,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dueDateText = item.dueDate != null
        ? DateFormat(_dateFormat).format(item.dueDate!)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: item.isCompleted,
                onChanged: (_) => onComplete(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        Chip(
                          label: Text(
                            item.priority.name,
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor:
                              _priorityColor(context, item.priority),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        if (dueDateText != null)
                          Chip(
                            label: Text(
                              dueDateText,
                              style: const TextStyle(fontSize: 11),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        Chip(
                          label: Text(
                            item.eisenhowerQuadrant.name,
                            style: const TextStyle(fontSize: 11),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
