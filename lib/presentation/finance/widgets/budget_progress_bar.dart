import 'dart:math';

import 'package:agenda/core/constants/finance_colors.dart';
import 'package:agenda/core/utils/amount_formatter.dart';
import 'package:flutter/material.dart';

/// Progress bar widget for a single expense budget category.
///
/// Shows current spend vs. limit with a three-state color:
/// - 0–79%: cs.primary (normal)
/// - 80–99%: [FinanceColors.warningAmber] (approaching limit)
/// - ≥100%: cs.error (over limit)
///
/// Per Phase 3 UI-SPEC Budget Progress Card Contract.
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    required this.categoryName, required this.spentCents, required this.limitCents, required this.currencySymbol, required this.locale, super.key,
    this.noLimitLabel = 'Sem limite definido',
  });

  final String categoryName;
  final int spentCents;
  final int limitCents;
  final String currencySymbol;
  final Locale locale;

  /// Label shown when [limitCents] == 0. Defaults to PT-BR string.
  final String noLimitLabel;

  Color _progressColor(BuildContext context, double ratio) {
    final cs = Theme.of(context).colorScheme;
    if (ratio >= 1.0) return cs.error;
    if (ratio >= 0.80) return FinanceColors.warningAmber;
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (limitCents == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              categoryName,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              noLimitLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final ratio = spentCents / limitCents;
    final cappedRatio = min(1.0, ratio);
    final progressColor = _progressColor(context, ratio);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            categoryName,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatAmount(spentCents, currencySymbol, locale),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              Text(
                formatAmount(limitCents, currencySymbol, locale),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cappedRatio,
              minHeight: 8,
              color: progressColor,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
