import 'package:agenda/core/utils/amount_formatter.dart';
import 'package:agenda/domain/finance/transaction_category.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Donut pie chart of expense spending grouped by category for a month.
///
/// Renders one [PieChartSectionData] per entry in [categorySpend]
/// (categoryId → totalCents). A legend below the chart shows the category
/// name and formatted amount for each slice.
///
/// When [categorySpend] is empty, no [PieChart] is built — instead a centered
/// [emptyChartMessage] is shown. This guards against fl_chart's empty-sections
/// edge case (RESEARCH Pitfall A2 / threat T-03-05-04).
///
/// Pure presentation widget — amount cents are divided by 100.0 for the chart
/// value only and never fed back into business logic (threat T-03-05-01).
class SpendingPieChart extends StatelessWidget {
  const SpendingPieChart({
    required this.categorySpend,
    required this.categories,
    required this.currencySymbol,
    required this.locale,
    required this.emptyChartMessage,
    super.key,
  });

  /// Expense spending grouped by categoryId for the selected month.
  final Map<int, int> categorySpend;

  /// All categories used to resolve display names for the legend.
  final List<TransactionCategory> categories;

  /// Currency symbol prepended to formatted amounts (e.g. 'MT').
  final String currencySymbol;

  /// Locale used by [formatAmount] for thousands/decimal separators.
  final Locale locale;

  /// Centered message shown when [categorySpend] is empty.
  final String emptyChartMessage;

  /// 8-color palette indexed by `categoryId % 8`.
  static const List<Color> _palette = [
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFF00695C),
    Color(0xFFE65100),
    Color(0xFF4E342E),
    Color(0xFF37474F),
    Color(0xFF558B2F),
    Color(0xFFAD1457),
  ];

  /// Deterministic color for [categoryId], wrapping at the palette length.
  static Color categoryColor(int categoryId) =>
      _palette[categoryId % _palette.length];

  String _categoryName(int categoryId) {
    for (final c in categories) {
      if (c.id == categoryId) return c.namePtBr;
    }
    return '#$categoryId';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (categorySpend.isEmpty) {
      return Center(
        child: Text(
          emptyChartMessage,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final entries = categorySpend.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: [
                for (final e in entries)
                  PieChartSectionData(
                    value: e.value / 100.0,
                    title: '',
                    color: categoryColor(e.key),
                    radius: 64,
                  ),
              ],
              centerSpaceRadius: 48,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: categoryColor(e.key),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_categoryName(e.key)} · '
                    '${formatAmount(e.value, currencySymbol, locale)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
