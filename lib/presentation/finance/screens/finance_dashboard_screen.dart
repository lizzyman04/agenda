import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/screens/budget_overview_screen.dart';
import 'package:agenda/presentation/finance/screens/debt_list_screen.dart';
import 'package:agenda/presentation/finance/screens/goal_list_screen.dart';
import 'package:agenda/presentation/finance/screens/recurring_payment_screen.dart';
import 'package:agenda/presentation/finance/screens/transaction_list_screen.dart';
import 'package:flutter/material.dart';

/// Root screen for the Finance tab.
///
/// Wraps all finance sub-screens in a [DefaultTabController] with 6 tabs:
/// Resumo, Transações, Orçamentos, Objetivos, Dívidas, Recorrências.
///
/// The finance cubits are provided above [MaterialApp] in `app.dart` so that
/// both these tabs and any pushed form routes inherit the same instances.
/// The _DashboardTab placeholder is replaced in plan 03-05.
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

/// Placeholder dashboard tab — replaced in plan 03-05 with charts.
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Resumo — ver plano 03-05'),
    );
  }
}
