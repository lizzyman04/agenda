import 'package:agenda/domain/finance/recurring_cycle.dart';
import 'package:agenda/presentation/finance/widgets/finance_form_primitives.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The cycle-and-next-due-date half of the recurring payment form card.
///
/// Split out of [RecurringPaymentFormFields] so both stay under the
/// architecture line-count limit. Renders as a bare [Column] of [FieldRow]s so
/// the caller keeps ownership of the surrounding [FormCard].
class RecurringPaymentScheduleFields extends StatelessWidget {
  const RecurringPaymentScheduleFields({
    required this.cycle,
    required this.nextDueDate,
    required this.onCycleChanged,
    required this.onPickDate,
    super.key,
  });

  final RecurringCycle cycle;
  final DateTime nextDueDate;
  final ValueChanged<RecurringCycle> onCycleChanged;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      children: [
        FieldRow(
          icon: Icons.repeat_outlined,
          child: DropdownButtonFormField<RecurringCycle>(
            initialValue: cycle,
            decoration: const InputDecoration(
              labelText: 'Ciclo',
              border: InputBorder.none,
              isDense: true,
            ),
            items:
                RecurringCycle.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(cycleLabel(c)),
                      ),
                    )
                    .toList(),
            onChanged: (val) {
              if (val != null) onCycleChanged(val);
            },
          ),
        ),
        const FieldDivider(),
        FieldRow(
          icon: Icons.calendar_today_outlined,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              'Próximo vencimento',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            subtitle: Text(
              DateFormat('dd/MM/yyyy').format(nextDueDate),
              style: theme.textTheme.bodyMedium,
            ),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: onPickDate,
          ),
        ),
      ],
    );
  }
}

/// PT-BR label for a [RecurringCycle], shared by the form and the list card.
String cycleLabel(RecurringCycle cycle) => switch (cycle) {
  RecurringCycle.daily => 'Diário',
  RecurringCycle.weekly => 'Semanal',
  RecurringCycle.biweekly => 'Quinzenal',
  RecurringCycle.monthly => 'Mensal',
  RecurringCycle.quarterly => 'Trimestral',
  RecurringCycle.yearly => 'Anual',
};
