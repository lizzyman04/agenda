import 'package:agenda/application/shared/locale/locale_cubit.dart';
import 'package:agenda/application/shared/locale/locale_state.dart';
import 'package:agenda/application/tasks/day_planner/day_planner_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/screens/day_planner_screen.dart';
import 'package:agenda/presentation/tasks/screens/eisenhower_screen.dart';
import 'package:agenda/presentation/tasks/screens/gtd_filter_screen.dart';
import 'package:agenda/presentation/tasks/screens/task_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AgendaApp extends StatelessWidget {
  const AgendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LocaleCubit>(
      create: (_) => getIt<LocaleCubit>(),
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          return MaterialApp(
            title: 'AGENDA',
            locale: localeState.locale,
            supportedLocales: LocaleCubit.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: MultiBlocProvider(
              providers: [
                BlocProvider<TaskListCubit>(
                  create: (_) => getIt<TaskListCubit>(),
                ),
                BlocProvider<DayPlannerCubit>(
                  create: (_) => getIt<DayPlannerCubit>(),
                ),
              ],
              child: const _AppShell(),
            ),
          );
        },
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _selectedIndex = 0;

  static const _screens = [
    TaskListScreen(),
    EisenhowerScreen(),
    DayPlannerScreen(),
    GtdFilterScreen(usedAsTab: true),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
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
        ],
      ),
    );
  }
}
