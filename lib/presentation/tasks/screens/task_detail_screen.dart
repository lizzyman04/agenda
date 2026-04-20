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

  Color _priorityColor(Priority p, ColorScheme cs) => switch (p) {
        Priority.urgent || Priority.critical => cs.error,
        Priority.high => Colors.orange,
        Priority.medium => cs.primary,
        Priority.low => cs.outline,
      };

  Future<void> _confirmDelete(
      BuildContext context, AppLocalizations l10n) async {
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
          behavior: SnackBarBehavior.floating,
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
    final cs = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.jm();

    final hasDateInfo = item.dueDate != null || item.recurrenceRule != null;
    final hasFlags = item.isUrgent || item.isImportant || item.isNextAction;
    final hasGtd = (item.gtdContext != null && item.gtdContext!.isNotEmpty) ||
        (item.waitingFor != null && item.waitingFor!.isNotEmpty);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l10n.taskDetailTitle),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // ── Hero card: title + description + status/priority badges ──
          Card(
            elevation: 0,
            color: cs.surfaceContainerLow,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status chip row
                  Row(
                    children: [
                      _StatusChip(
                        label: item.isCompleted
                            ? l10n.statusCompleted
                            : l10n.statusPending,
                        color: item.isCompleted ? Colors.green : cs.outline,
                        filled: item.isCompleted,
                      ),
                      const SizedBox(width: 8),
                      _PriorityChip(
                        label: _priorityLabel(item.priority, l10n),
                        color: _priorityColor(item.priority, cs),
                      ),
                      const SizedBox(width: 8),
                      _SizeChip(
                        label: _sizeLabel(item.sizeCategory, l10n),
                        cs: cs,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Title
                  Text(item.title, style: theme.textTheme.headlineSmall),
                  // Description
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
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
          ),

          // ── Dates card ──
          if (hasDateInfo) ...[
            const SizedBox(height: 12),
            _SectionCard(
              icon: Icons.calendar_today_outlined,
              title: 'Dates',
              cs: cs,
              theme: theme,
              children: [
                if (item.dueDate != null)
                  _DetailRow(
                    icon: Icons.event_outlined,
                    label: l10n.fieldDueDate,
                    value: dateFormat.format(item.dueDate!),
                    theme: theme,
                    cs: cs,
                  ),
                if (item.dueTimeMinutes != null)
                  _DetailRow(
                    icon: Icons.access_time_outlined,
                    label: l10n.fieldDueTime,
                    value: timeFormat.format(DateTime(
                      0,
                      1,
                      1,
                      item.dueTimeMinutes! ~/ 60,
                      item.dueTimeMinutes! % 60,
                    )),
                    theme: theme,
                    cs: cs,
                  ),
                if (item.recurrenceRule != null)
                  _DetailRow(
                    icon: Icons.repeat_outlined,
                    label: l10n.recurrence,
                    value: _recurrenceLabel(item.recurrenceRule, l10n),
                    theme: theme,
                    cs: cs,
                  ),
              ],
            ),
          ],

          // ── Flags card ──
          if (hasFlags) ...[
            const SizedBox(height: 12),
            _SectionCard(
              icon: Icons.label_outline,
              title: 'Flags',
              cs: cs,
              theme: theme,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item.isUrgent)
                        _FlagChip(
                          label: l10n.fieldUrgent,
                          icon: Icons.bolt,
                          backgroundColor: cs.errorContainer,
                          foregroundColor: cs.onErrorContainer,
                        ),
                      if (item.isImportant)
                        _FlagChip(
                          label: l10n.fieldImportant,
                          icon: Icons.star,
                          backgroundColor: cs.primaryContainer,
                          foregroundColor: cs.onPrimaryContainer,
                        ),
                      if (item.isNextAction)
                        _FlagChip(
                          label: l10n.fieldNextAction,
                          icon: Icons.arrow_forward,
                          backgroundColor: cs.secondaryContainer,
                          foregroundColor: cs.onSecondaryContainer,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          // ── GTD card ──
          if (hasGtd) ...[
            const SizedBox(height: 12),
            _SectionCard(
              icon: Icons.psychology_outlined,
              title: 'GTD',
              cs: cs,
              theme: theme,
              children: [
                if (item.gtdContext != null && item.gtdContext!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.tag_outlined,
                    label: l10n.fieldGtdContext,
                    value: item.gtdContext!,
                    theme: theme,
                    cs: cs,
                  ),
                if (item.waitingFor != null && item.waitingFor!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.hourglass_empty_outlined,
                    label: l10n.fieldWaitingFor,
                    value: item.waitingFor!,
                    theme: theme,
                    cs: cs,
                  ),
              ],
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, l10n),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.deleteButton),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _navigateToEdit(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.editButton),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable widgets
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.cs,
    required this.theme,
    required this.children,
  });

  final IconData icon;
  final String title;
  final ColorScheme cs;
  final ThemeData theme;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Icon(icon, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    required this.cs,
  });

  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.filled,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: filled ? color : color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.label, required this.cs});

  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: foregroundColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
