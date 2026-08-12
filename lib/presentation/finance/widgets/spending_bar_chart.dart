import 'dart:math';

import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/presentation/finance/widgets/spending_pie_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Horizontal-comparison bar chart of expense spending per category.
///
/// Renders one [BarChartGroupData] per entry in [categorySpend]
/// (categoryId → totalCents), using the same color palette as
/// [SpendingPieChart] so slices and bars stay visually consistent.
///
/// When [categorySpend] is empty, no [BarChart] is built — a centered
/// [emptyChartMessage] is shown instead (RESEARCH Pitfall A2 /
/// threat T-03-05-04).
class SpendingBarChart extends StatelessWidget {
  const SpendingBarChart({
    required this.categorySpend,
    required this.categories,
    required this.currencySymbol,
    required this.locale,
    required this.emptyChartMessage,
    super.key,
  });

  /// Expense spending grouped by categoryId for the selected month.
  final Map<int, int> categorySpend;

  /// All categories used to resolve short labels for the bottom axis.
  final List<TransactionCategory> categories;

  /// Currency symbol — kept for API parity with [SpendingPieChart].
  final String currencySymbol;

  /// Locale — kept for API parity with [SpendingPieChart].
  final Locale locale;

  /// Centered message shown when [categorySpend] is empty.
  final String emptyChartMessage;

  String _shortName(int categoryId) {
    var name = '#$categoryId';
    for (final c in categories) {
      if (c.id == categoryId) {
        name = c.namePtBr;
        break;
      }
    }
    return name.length > 6 ? '${name.substring(0, 5)}…' : name;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (categorySpend.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            emptyChartMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final entries = categorySpend.entries.toList();
    final maxCents = entries.map((e) => e.value).reduce(max);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          barGroups: [
            for (final indexed in entries.asMap().entries)
              BarChartGroupData(
                x: indexed.key,
                barRods: [
                  BarChartRodData(
                    toY: indexed.value.value / 100.0,
                    color: SpendingPieChart.categoryColor(indexed.value.key),
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _shortName(entries[index].key),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          maxY: maxCents / 100.0 * 1.1,
        ),
      ),
    );
  }
}
