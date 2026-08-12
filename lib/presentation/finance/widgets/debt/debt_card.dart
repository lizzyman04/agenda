import 'package:agenda/core/utils/amount_formatter.dart';
import 'package:agenda/domain/finance/debt/debt.dart';
import 'package:agenda/domain/finance/debt/debt_direction.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A single debt row: swipe-to-delete, tap to edit, paid-status toggle.
class DebtCard extends StatelessWidget {
  const DebtCard({
    required this.debt,
    required this.currencySymbol,
    required this.locale,
    required this.onTap,
    required this.onTogglePaid,
    required this.onDelete,
    super.key,
  });

  final Debt debt;
  final String currencySymbol;
  final Locale locale;
  final VoidCallback onTap;
  final VoidCallback onTogglePaid;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final directionLabel = debt.direction == DebtDirection.toPay
        ? l10n.toPay
        : l10n.toReceive;

    return Dismissible(
      key: Key('debt-${debt.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  debt.title,
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  '${debt.counterparty} · '
                  '${DateFormat('dd/MM/yyyy').format(debt.dueDate)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatAmount(debt.amountCents, currencySymbol, locale),
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: debt.direction == DebtDirection.toPay
                            ? cs.errorContainer
                            : cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        directionLabel,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                dense: true,
                title: Text(
                  debt.isPaid ? 'Pago' : 'Pendente',
                  style: theme.textTheme.bodySmall,
                ),
                value: debt.isPaid,
                onChanged: (_) => onTogglePaid(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
