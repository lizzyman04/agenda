import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/screens/budget_overview_screen.dart';
import 'package:agenda/presentation/finance/screens/debt_list_screen.dart';
import 'package:agenda/presentation/finance/goals/screens/goal_list_screen.dart';
import 'package:agenda/presentation/finance/screens/recurring_payment_screen.dart';
import 'package:agenda/presentation/finance/screens/transaction_list_screen.dart';
import 'package:agenda/presentation/finance/widgets/dashboard/dashboard_tab.dart';
import 'package:agenda/presentation/shell/shell_navigation.dart';
import 'package:flutter/material.dart';

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
      child: _SubTabRequestListener(
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
              DashboardTab(),
              TransactionListScreen(),
              BudgetOverviewScreen(),
              GoalListScreen(),
              DebtListScreen(),
              RecurringPaymentScreen(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Applies [financeSubTabRequest] to the surrounding [DefaultTabController].
///
/// Notification taps ask for a sub-tab through the notifier; the request is
/// consumed once and reset to null.
class _SubTabRequestListener extends StatefulWidget {
  const _SubTabRequestListener({required this.child});

  final Widget child;

  @override
  State<_SubTabRequestListener> createState() => _SubTabRequestListenerState();
}

class _SubTabRequestListenerState extends State<_SubTabRequestListener> {
  @override
  void initState() {
    super.initState();
    financeSubTabRequest.addListener(_apply);
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  void _apply() {
    final index = financeSubTabRequest.value;
    if (index == null || !mounted) return;
    final controller = DefaultTabController.of(context);
    if (index >= 0 && index < controller.length) controller.animateTo(index);
    financeSubTabRequest.value = null;
  }

  @override
  void dispose() {
    financeSubTabRequest.removeListener(_apply);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
