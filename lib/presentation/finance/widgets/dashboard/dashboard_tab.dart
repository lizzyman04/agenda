import 'dart:async';

import 'package:agenda/application/finance/dashboard/home_dashboard_cubit.dart';
import 'package:agenda/application/finance/dashboard/home_dashboard_state.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/widgets/dashboard/dashboard_month_header.dart';
import 'package:agenda/presentation/finance/widgets/dashboard_summary_card.dart';
import 'package:agenda/presentation/finance/widgets/finance_empty_state.dart';
import 'package:agenda/presentation/finance/widgets/spending_bar_chart.dart';
import 'package:agenda/presentation/finance/widgets/spending_pie_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Dev-default currency symbol (MZN per D-16). Matches the hardcoded symbol
/// used by every other finance screen until a currency setting exists.
const String _currencySymbol = 'MT';

/// Resumo tab — balance + net worth summary, month navigation, and the
/// spending pie + bar charts driven by [HomeDashboardCubit].
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => DashboardTabState();
}

class DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    // The cubit is provided above MaterialApp in app.dart; only start it.
    unawaited(context.read<HomeDashboardCubit>().start());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    return BlocBuilder<HomeDashboardCubit, HomeDashboardState>(
      builder: (context, state) {
        switch (state) {
          case HomeDashboardInitial():
          case HomeDashboardLoading():
            return const Center(child: CircularProgressIndicator());

          case HomeDashboardError(:final failure):
            return Center(child: Text(failure.message));

          case HomeDashboardLoaded():
            return _buildLoaded(context, l10n, locale, state);
        }
      },
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    AppLocalizations l10n,
    Locale locale,
    HomeDashboardLoaded state,
  ) {
    final cubit = context.read<HomeDashboardCubit>();

    // "No data at all" proxy: no balance, no net worth, no spending.
    final hasNoData = state.balanceCents == 0 &&
        state.netWorthCents == 0 &&
        state.categorySpend.isEmpty;

    if (hasNoData) {
      return FinanceEmptyState(
        icon: Icons.bar_chart_outlined,
        heading: l10n.emptyDashboard,
        body: l10n.emptyDashboardBody,
        ctaLabel: l10n.addTransaction,
        onCta: () => DefaultTabController.of(context).animateTo(1),
      );
    }

    final month = state.selectedMonth;
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardSummaryCard(
                  balanceCents: state.balanceCents,
                  netWorthCents: state.netWorthCents,
                  currencySymbol: _currencySymbol,
                  locale: locale,
                ),
                const SizedBox(height: 24),
                MonthNavigationHeader(
                  selectedMonth: month,
                  onPrev: () => cubit.selectMonth(
                    DateTime(month.year, month.month - 1),
                  ),
                  onNext: isCurrentMonth
                      ? null
                      : () => cubit.selectMonth(
                            DateTime(month.year, month.month + 1),
                          ),
                ),
                const SizedBox(height: 16),
                if (state.categorySpend.isEmpty)
                  EmptyChartMessage(selectedMonth: month, locale: locale)
                else ...[
                  Text(
                    l10n.spendingByCategory,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SpendingPieChart(
                    categorySpend: state.categorySpend,
                    categories: state.categories,
                    currencySymbol: _currencySymbol,
                    locale: locale,
                    emptyChartMessage: '',
                  ),
                  const SizedBox(height: 24),
                  SpendingBarChart(
                    categorySpend: state.categorySpend,
                    categories: state.categories,
                    currencySymbol: _currencySymbol,
                    locale: locale,
                    emptyChartMessage: '',
                  ),
                ],
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
