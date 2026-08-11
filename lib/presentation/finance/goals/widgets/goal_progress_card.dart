import 'dart:math';

import 'package:agenda/core/constants/finance_colors.dart';
import 'package:agenda/core/utils/amount_formatter.dart';
import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card widget displaying progress for a single savings goal.
///
/// Shows goal title, progress bar, saved vs. target amounts, and optional
/// deadline. Tapping the card navigates to the goal detail screen.
///
/// Per Phase 3 UI-SPEC Goal Progress Card Contract.
class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({
    required this.goal, required this.taggedTransactionsCents, required this.onTap, required this.currencySymbol, required this.locale, super.key,
  });

  final SavingsGoal goal;

  /// Sum of amountCents for all transactions tagged to this goal.
  final int taggedTransactionsCents;

  final VoidCallback onTap;
  final String currencySymbol;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final progressRatio = goal.progressPercent(taggedTransactionsCents);
    final cappedRatio = min(1.0, progressRatio);
    final percentText = '${(cappedRatio * 100).toStringAsFixed(0)}%';
    final savedCents = goal.amountSavedCents(taggedTransactionsCents);

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (goal.isCompleted)
                    const Icon(
                      Icons.check_circle,
                      color: FinanceColors.incomeGreen,
                      size: 20,
                    )
                  else
                    Text(
                      percentText,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${formatAmount(savedCents, currencySymbol, locale)} de '
                '${formatAmount(goal.targetAmountCents, currencySymbol, locale)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: cappedRatio,
                  minHeight: 8,
                  color: cs.primary,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
              if (goal.deadline != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Prazo: ${DateFormat('dd/MM/yyyy').format(goal.deadline!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
