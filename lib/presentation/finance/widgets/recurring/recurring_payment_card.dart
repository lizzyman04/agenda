import 'package:agenda/core/utils/amount_formatter.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/widgets/recurring/recurring_payment_schedule_fields.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A single recurring payment row: title, cycle, next due date, amount, and
/// an active-status toggle.
///
/// A paused payment (isActive == false) renders dimmed behind a localized
/// "paused" label, but its toggle stays at full opacity on purpose: that
/// switch is the only control anywhere that can resume the payment (CR-02),
/// so it must never read as disabled along with the rest of the row.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final isPaused = !payment.isActive;
    final nextDueLabel = DateFormat(
      'dd/MM/yyyy',
    ).format(payment.nextDueDate);

    return Card(
      elevation: 0,
      color: isPaused ? cs.surfaceContainerLowest : cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Opacity(
              opacity: isPaused ? 0.55 : 1,
              child: ListTile(
                leading: Icon(
                  isPaused ? Icons.pause_circle_outline : Icons.repeat,
                ),
                title: Text(
                  payment.title,
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  '${cycleLabel(payment.cycle)} · Próximo: $nextDueLabel',
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
            ),
            SwitchListTile(
              dense: true,
              title: Text(
                isPaused ? l10n.recurringPaused : l10n.recurringActive,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isPaused ? cs.onSurfaceVariant : null,
                ),
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
