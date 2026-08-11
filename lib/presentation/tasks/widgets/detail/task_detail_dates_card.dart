import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/widgets/detail/task_detail_section_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Due date/time and recurrence card, shown when the task carries any date
/// info. Renders nothing when it doesn't, so callers can place it
/// unconditionally in a `Column`.
class TaskDetailDatesCard extends StatelessWidget {
  const TaskDetailDatesCard({required this.item, super.key});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final hasDateInfo = item.dueDate != null || item.recurrenceRule != null;
    if (!hasDateInfo) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.jm();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SectionCard(
        icon: Icons.calendar_today_outlined,
        title: 'Dates',
        cs: cs,
        theme: theme,
        children: [
          if (item.dueDate != null)
            DetailRow(
              icon: Icons.event_outlined,
              label: l10n.fieldDueDate,
              value: dateFormat.format(item.dueDate!),
              theme: theme,
              cs: cs,
            ),
          if (item.dueTimeMinutes != null)
            DetailRow(
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
            DetailRow(
              icon: Icons.repeat_outlined,
              label: l10n.recurrence,
              value: _recurrenceLabel(item.recurrenceRule, l10n),
              theme: theme,
              cs: cs,
            ),
        ],
      ),
    );
  }
}

String _recurrenceLabel(String? rule, AppLocalizations l10n) {
  if (rule == null) return l10n.noRecurrence;
  if (rule.contains('FREQ=DAILY')) return l10n.daily;
  if (rule.contains('FREQ=WEEKLY')) return l10n.weekly;
  if (rule.contains('FREQ=MONTHLY')) return l10n.monthly;
  if (rule.contains('FREQ=YEARLY')) return l10n.yearly;
  return rule;
}
