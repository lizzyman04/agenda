import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/form/widgets/form_primitives.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Priority, due date/time, and recurrence fields inside the advanced
/// options card.
///
/// Presentational only: the screen owns every value and reacts to the
/// callbacks with `setState`.
class ScheduleFields extends StatelessWidget {
  const ScheduleFields({
    required this.l10n,
    required this.theme,
    required this.cs,
    required this.priority,
    required this.dueDate,
    required this.dueTime,
    required this.recurrenceRule,
    required this.onPriorityChanged,
    required this.onPickDate,
    required this.onClearDate,
    required this.onPickTime,
    required this.onRecurrenceChanged,
    super.key,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final ColorScheme cs;
  final Priority priority;
  final DateTime? dueDate;
  final TimeOfDay? dueTime;
  final String? recurrenceRule;
  final ValueChanged<Priority> onPriorityChanged;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;
  final VoidCallback onPickTime;
  final ValueChanged<String?> onRecurrenceChanged;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Column(
      children: [
        FieldRow(
          icon: Icons.flag_outlined,
          child: DropdownButtonFormField<Priority>(
            initialValue: priority,
            decoration: InputDecoration(
              labelText: l10n.fieldPriority,
              border: InputBorder.none,
              isDense: true,
            ),
            items: Priority.values
                .map((p) => DropdownMenuItem(
                    value: p, child: Text(_priorityLabel(l10n, p))))
                .toList(),
            onChanged: (val) => val != null ? onPriorityChanged(val) : null,
          ),
        ),
        const FieldDivider(),
        FieldRow(
          icon: Icons.calendar_today_outlined,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l10n.fieldDueDate,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
            subtitle: Text(
              dueDate != null ? dateFormat.format(dueDate!) : l10n.noDueDate,
              style: theme.textTheme.bodyMedium,
            ),
            trailing: dueDate != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: onClearDate)
                : IconButton(
                    icon: const Icon(Icons.edit_calendar_outlined),
                    onPressed: onPickDate),
            onTap: onPickDate,
          ),
        ),
        if (dueDate != null) ...[
          const FieldDivider(),
          FieldRow(
            icon: Icons.access_time_outlined,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(l10n.fieldDueTime,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
              subtitle: Text(
                dueTime != null
                    ? '${dueTime!.hour.toString().padLeft(2, '0')}:'
                        '${dueTime!.minute.toString().padLeft(2, '0')}'
                    : l10n.noDueTime,
                style: theme.textTheme.bodyMedium,
              ),
              trailing: IconButton(
                  icon: const Icon(Icons.schedule_outlined),
                  onPressed: onPickTime),
              onTap: onPickTime,
            ),
          ),
          const FieldDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(l10n.recurrence,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ),
          ...[
            null, 'FREQ=DAILY', 'FREQ=WEEKLY',
            'FREQ=MONTHLY;BYMONTHDAY=${dueDate!.day}', 'FREQ=YEARLY',
          ].map((rule) => RadioListTile<String?>(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(_recurrenceLabel(l10n, rule)),
                value: rule,
                groupValue: recurrenceRule,
                onChanged: onRecurrenceChanged,
              )),
        ],
      ],
    );
  }
}

String _priorityLabel(AppLocalizations l10n, Priority priority) {
  return switch (priority) {
    Priority.low => l10n.priorityLow,
    Priority.medium => l10n.priorityMedium,
    Priority.high => l10n.priorityHigh,
    Priority.critical => l10n.priorityCritical,
    Priority.urgent => l10n.priorityUrgent,
  };
}

String _recurrenceLabel(AppLocalizations l10n, String? rule) {
  if (rule == null) return l10n.noRecurrence;
  if (rule.contains('DAILY')) return l10n.daily;
  if (rule.contains('WEEKLY')) return l10n.weekly;
  if (rule.contains('MONTHLY')) return l10n.monthly;
  if (rule.contains('YEARLY')) return l10n.yearly;
  return rule;
}
