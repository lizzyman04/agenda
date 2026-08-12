import 'package:agenda/core/constants/finance_colors.dart';
import 'package:agenda/core/utils/amount_formatter.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/domain/finance/transaction_type.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card widget displaying a single financial transaction.
///
/// Supports swipe-to-delete via [Dismissible] and tap-to-edit via [onTap].
/// Uses [FinanceColors] for income/expense semantic colors.
///
/// No Isar imports — only domain types.
class TransactionCard extends StatelessWidget {
  const TransactionCard({
    required this.transaction,
    required this.onDelete,
    required this.onTap,
    required this.categoryName,
    required this.currencySymbol,
    required this.locale,
    super.key,
  });

  final Transaction transaction;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final String categoryName;
  final String currencySymbol;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final isIncome = transaction.type == TransactionType.income;
    final amountColor =
        isIncome ? FinanceColors.incomeGreen : FinanceColors.expenseRed;
    final typeIcon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;

    final formattedAmount = formatAmount(
      transaction.amountCents,
      currencySymbol,
      locale,
    );
    final formattedDate = DateFormat('dd/MM/yyyy').format(transaction.date);
    final hasNote =
        transaction.note != null && transaction.note != categoryName;

    return Dismissible(
      key: Key('tx-${transaction.id}'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            leading: Icon(typeIcon, color: amountColor, size: 24),
            title: Text(
              transaction.note ?? categoryName,
              style: theme.textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$categoryName · $formattedDate',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (hasNote)
                  Chip(
                    label: Text(
                      transaction.note!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    labelStyle: const TextStyle(fontSize: 11),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            trailing: Text(
              formattedAmount,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: amountColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
