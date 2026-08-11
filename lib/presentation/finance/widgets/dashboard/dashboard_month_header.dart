import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Previous/next month navigation header. [onNext] is null when the current
/// calendar month is selected, which disables the forward arrow (D-10).
class MonthNavigationHeader extends StatelessWidget {
  const MonthNavigationHeader({
    required this.selectedMonth,
    required this.onPrev,
    required this.onNext,
    super.key,
  });

  final DateTime selectedMonth;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final label =
        DateFormat('MMMM yyyy', locale.toString()).format(selectedMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: l10n.previousMonth,
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
        ),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          tooltip: l10n.nextMonth,
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// Centered "no expenses this month" text shown in the chart area when the
/// selected month has transactions elsewhere but no expense categories.
/// Per UI-SPEC: keep the chart section visible, do not hide it.
class EmptyChartMessage extends StatelessWidget {
  const EmptyChartMessage({
    required this.selectedMonth,
    required this.locale,
    super.key,
  });

  final DateTime selectedMonth;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final monthName =
        DateFormat('MMMM', locale.toString()).format(selectedMonth);

    return SizedBox(
      height: 180,
      child: Center(
        child: Text(
          l10n.noExpensesInMonth(monthName),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
