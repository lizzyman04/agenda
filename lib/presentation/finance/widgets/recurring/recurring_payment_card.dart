import 'package:agenda/core/utils/amount_formatter.dart';
import 'package:agenda/domain/finance/recurring/recurring_cycle.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A single recurring payment row: title, cycle, next due date, amount, and
/// an active-status toggle.
class RecurringPaymentCard extends StatelessWidget {
  const RecurringPaymentCard({
    required this.payment,
    required this.currencySymbol,
    required this.locale,
    required this.onTap,
    required this.onToggleActive,
    super.key,
  });

  final RecurringPayment payment;
  final String currencySymbol;
  final Locale locale;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;

  String _cycleLabel(RecurringCycle cycle) => switch (cycle) {
    RecurringCycle.daily => 'Diário',
    RecurringCycle.weekly => 'Semanal',
    RecurringCycle.biweekly => 'Quinzenal',
    RecurringCycle.monthly => 'Mensal',
    RecurringCycle.quarterly => 'Trimestral',
    RecurringCycle.yearly => 'Anual',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final nextDueLabel = DateFormat(
      'dd/MM/yyyy',
    ).format(payment.nextDueDate);

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.repeat),
              title: Text(
                payment.title,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                '${_cycleLabel(payment.cycle)} · Próximo: $nextDueLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              trailing: Text(
                formatAmount(payment.amountCents, currencySymbol, locale),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SwitchListTile(
              dense: true,
              title: Text(
                payment.isActive ? 'Ativo' : 'Pausado',
                style: theme.textTheme.bodySmall,
              ),
              value: payment.isActive,
              onChanged: (_) => onToggleActive(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ],
        ),
      ),
    );
  }
}
