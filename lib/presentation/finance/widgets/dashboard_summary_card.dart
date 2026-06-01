import 'package:agenda/core/utils/amount_formatter.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Primary visual anchor of the dashboard Resumo tab.
///
/// Shows the lifetime balance (D-07) in `displaySmall` as the dominant value,
/// with net worth (D-08) below it in `bodyLarge`.
///
/// Pure presentation widget — both amounts are formatted via [formatAmount]
/// and displayed read-only.
class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({
    required this.balanceCents,
    required this.netWorthCents,
    required this.currencySymbol,
    required this.locale,
    super.key,
  });

  /// Lifetime balance (D-07) shown as the primary value.
  final int balanceCents;

  /// Net worth (D-08) shown below the balance.
  final int netWorthCents;

  /// Currency symbol prepended to amounts (e.g. 'MT').
  final String currencySymbol;

  /// Locale used by [formatAmount] for separators.
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 1,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.currentBalance,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatAmount(balanceCents, currencySymbol, locale),
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  l10n.netWorth,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  formatAmount(netWorthCents, currencySymbol, locale),
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
