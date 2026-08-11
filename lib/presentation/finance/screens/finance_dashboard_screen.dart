import 'dart:async';

import 'package:agenda/application/finance/dashboard/home_dashboard_cubit.dart';
import 'package:agenda/application/finance/dashboard/home_dashboard_state.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/screens/budget_overview_screen.dart';
import 'package:agenda/presentation/finance/screens/debt_list_screen.dart';
import 'package:agenda/presentation/finance/goals/screens/goal_list_screen.dart';
import 'package:agenda/presentation/finance/screens/recurring_payment_screen.dart';
import 'package:agenda/presentation/finance/screens/transaction_list_screen.dart';
import 'package:agenda/presentation/finance/widgets/dashboard_summary_card.dart';
import 'package:agenda/presentation/finance/widgets/finance_empty_state.dart';
import 'package:agenda/presentation/finance/widgets/spending_bar_chart.dart';
import 'package:agenda/presentation/finance/widgets/spending_pie_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Dev-default currency symbol (MZN per D-16). Matches the hardcoded symbol
/// used by every other finance screen until a currency setting exists.
const String _currencySymbol = 'MT';

/// Root screen for the Finance tab.
///
/// Wraps all finance sub-screens in a [DefaultTabController] with 6 tabs:
/// Resumo, Transações, Orçamentos, Objetivos, Dívidas, Recorrências.
///
/// The finance cubits are provided above [MaterialApp] in `app.dart` so that
/// both these tabs and any pushed form routes inherit the same instances.
class FinanceDashboardScreen extends StatelessWidget {
  const FinanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.financeTabLabel),
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 1,
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.dashboardTabLabel),
              Tab(text: l10n.transactionsTabLabel),
              Tab(text: l10n.budgetsTabLabel),
              Tab(text: l10n.goalsTabLabel),
              Tab(text: l10n.debtsTabLabel),
              Tab(text: l10n.recurringTabLabel),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DashboardTab(),
            TransactionListScreen(),
            BudgetOverviewScreen(),
            GoalListScreen(),
            DebtListScreen(),
            RecurringPaymentScreen(),
          ],
        ),
      ),
    );
  }
}

/// Resumo tab — balance + net worth summary, month navigation, and the
/// spending pie + bar charts driven by [HomeDashboardCubit].
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
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
                _MonthNavigationHeader(
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
                  _EmptyChartMessage(selectedMonth: month, locale: locale)
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

/// Previous/next month navigation header. [onNext] is null when the current
/// calendar month is selected, which disables the forward arrow (D-10).
class _MonthNavigationHeader extends StatelessWidget {
  const _MonthNavigationHeader({
    required this.selectedMonth,
    required this.onPrev,
    required this.onNext,
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
class _EmptyChartMessage extends StatelessWidget {
  const _EmptyChartMessage({
    required this.selectedMonth,
    required this.locale,
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
