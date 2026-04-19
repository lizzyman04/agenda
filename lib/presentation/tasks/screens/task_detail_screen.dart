import 'dart:async';

import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/domain/tasks/size_category.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/screens/task_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({required this.item, super.key});

  final Item item;

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

  String _recurrenceLabel(String? rule, AppLocalizations l10n) {
    if (rule == null) return l10n.noRecurrence;
    if (rule.contains('FREQ=DAILY')) return l10n.daily;
    if (rule.contains('FREQ=WEEKLY')) return l10n.weekly;
    if (rule.contains('FREQ=MONTHLY')) return l10n.monthly;
    if (rule.contains('FREQ=YEARLY')) return l10n.yearly;
    return rule;
  }

  Future<void> _confirmDelete(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text(l10n.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      unawaited(context.read<TaskListCubit>().softDelete(item.id));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppConstants.undoSnackbarDuration,
          content: Text(l10n.taskDeleted),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () =>
                unawaited(context.read<TaskListCubit>().restoreItem(item.id)),
          ),
        ),
      );
    }
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<TaskListCubit>(),
          child: TaskFormScreen(item: item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.jm();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.taskDetailTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(item.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          if (item.description != null && item.description!.isNotEmpty) ...[
            Text(item.description!, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
          ],
          const Divider(),
          _InfoRow(
            label: l10n.labelStatus,
            value: item.isCompleted ? l10n.statusCompleted : l10n.statusPending,
            valueColor: item.isCompleted
                ? Colors.green
                : theme.colorScheme.onSurface,
          ),
          _InfoRow(label: l10n.fieldPriority, value: _priorityLabel(item.priority, l10n)),
          if (item.dueDate != null)
            _InfoRow(
              label: l10n.fieldDueDate,
              value: dateFormat.format(item.dueDate!),
            ),
          if (item.dueTimeMinutes != null)
            _InfoRow(
              label: l10n.fieldDueTime,
              value: timeFormat.format(
                DateTime(0, 1, 1, item.dueTimeMinutes! ~/ 60, item.dueTimeMinutes! % 60),
              ),
            ),
          _InfoRow(
            label: l10n.recurrence,
            value: _recurrenceLabel(item.recurrenceRule, l10n),
          ),
          const Divider(),
          _InfoRow(label: l10n.fieldSize, value: _sizeLabel(item.sizeCategory, l10n)),
          if (item.gtdContext != null && item.gtdContext!.isNotEmpty)
            _InfoRow(label: l10n.fieldGtdContext, value: item.gtdContext!),
          if (item.waitingFor != null && item.waitingFor!.isNotEmpty)
            _InfoRow(label: l10n.fieldWaitingFor, value: item.waitingFor!),
          if (item.isNextAction || item.isUrgent || item.isImportant) ...[
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (item.isUrgent)
                  Chip(
                    label: Text(l10n.fieldUrgent),
                    backgroundColor: theme.colorScheme.errorContainer,
                    labelStyle: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                if (item.isImportant)
                  Chip(
                    label: Text(l10n.fieldImportant),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    labelStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                  ),
                if (item.isNextAction)
                  Chip(
                    label: Text(l10n.fieldNextAction),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    labelStyle: TextStyle(color: theme.colorScheme.onSecondaryContainer),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, l10n),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.deleteButton),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _navigateToEdit(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.editButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
