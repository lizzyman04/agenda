import 'package:agenda/core/utils/amount_formatter.dart';
import 'package:agenda/domain/finance/savings_goal_contribution.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Read-only history of manual contributions on a savings goal, newest first.
///
/// Renders nothing when [contributions] is empty, so callers can drop it into
/// a list without guarding.
///
/// Presentation-only: no cubit, no persistence, domain types only.
class ContributionHistoryList extends StatelessWidget {
  const ContributionHistoryList({
    required this.contributions,
    required this.currencySymbol,
    required this.locale,
    super.key,
  });

  final List<SavingsGoalContribution> contributions;
  final String currencySymbol;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    if (contributions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Histórico de contribuições',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ...contributions.reversed.map(
          (c) => _ContributionTile(
            contribution: c,
            currencySymbol: currencySymbol,
            locale: locale,
          ),
        ),
      ],
    );
  }
}

class _ContributionTile extends StatelessWidget {
  const _ContributionTile({
    required this.contribution,
    required this.currencySymbol,
    required this.locale,
  });

  final SavingsGoalContribution contribution;
  final String currencySymbol;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = contribution.note;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.add_circle_outline),
        title: Text(
          formatAmount(contribution.amountCents, currencySymbol, locale),
          style: theme.textTheme.bodyLarge,
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy').format(contribution.date),
          style: theme.textTheme.bodySmall,
        ),
        trailing: note != null
            ? Text(
                note,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              )
            : null,
      ),
    );
  }
}
