import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/screens/finance_dashboard_screen.dart';
import 'package:agenda/presentation/notifications/routing/notification_tap_listener.dart';
import 'package:agenda/presentation/shell/shell_navigation.dart';
import 'package:agenda/presentation/tasks/screens/day_planner_screen.dart';
import 'package:agenda/presentation/tasks/screens/eisenhower_screen.dart';
import 'package:agenda/presentation/tasks/screens/gtd_filter_screen.dart';
import 'package:agenda/presentation/tasks/screens/task_list_screen.dart';
import 'package:flutter/material.dart';

/// Bottom-navigation shell holding the five top-level tabs.
///
/// The selected tab lives in [appTabIndex] so a notification tap can change
/// it. Must sit below the app `Navigator` and the task cubit providers, which
/// is where `AgendaApp` mounts it.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const List<Widget> _screens = [
    TaskListScreen(),
    EisenhowerScreen(),
    DayPlannerScreen(),
    GtdFilterScreen(usedAsTab: true),
    FinanceDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return NotificationTapListener(
      child: ValueListenableBuilder<int>(
        valueListenable: appTabIndex,
        builder: (context, selectedIndex, _) {
          return Scaffold(
            body: IndexedStack(index: selectedIndex, children: _screens),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => appTabIndex.value = index,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.check_box_outline_blank),
                  selectedIcon: const Icon(Icons.check_box),
                  label: l10n.navTasks,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.grid_4x4_outlined),
                  selectedIcon: const Icon(Icons.grid_4x4),
                  label: l10n.navEisenhower,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.today_outlined),
                  selectedIcon: const Icon(Icons.today),
                  label: l10n.navDayPlanner,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.label_outline),
                  selectedIcon: const Icon(Icons.label),
                  label: l10n.navGtd,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: const Icon(Icons.account_balance_wallet),
                  label: l10n.financeTabLabel,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
