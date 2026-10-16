import 'package:agenda/application/finance/budget/budget_cubit.dart';
import 'package:agenda/application/finance/dashboard/home_dashboard_cubit.dart';
import 'package:agenda/application/finance/debt/debt_cubit.dart';
import 'package:agenda/application/finance/goal/goal_list_cubit.dart';
import 'package:agenda/application/finance/recurring/recurring_payment_cubit.dart';
import 'package:agenda/application/finance/transaction/transaction_cubit.dart';
import 'package:agenda/application/shared/locale/locale_cubit.dart';
import 'package:agenda/application/shared/locale/locale_state.dart';
import 'package:agenda/application/tasks/day_planner/day_planner_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/domain/notifications/notification_reconciler.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AgendaApp extends StatelessWidget {
  const AgendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Finance cubits are provided ABOVE MaterialApp (above the
    // Navigator) so that every pushed route inherits them. Providers
    // placed in MaterialApp.home sit below the Navigator and are NOT
    // visible to pushed routes — re-providing them per-route via
    // BlocProvider.value duplicated a single instance across two live
    // InheritedProviders and triggered a `_dependents.isEmpty`
    // framework assertion.
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocaleCubit>(create: (_) => getIt<LocaleCubit>()),
        BlocProvider<TransactionCubit>(
          create: (_) => getIt<TransactionCubit>(),
        ),
        BlocProvider<BudgetCubit>(create: (_) => getIt<BudgetCubit>()),
        BlocProvider<GoalListCubit>(create: (_) => getIt<GoalListCubit>()),
        BlocProvider<DebtCubit>(create: (_) => getIt<DebtCubit>()),
        BlocProvider<RecurringPaymentCubit>(
          create: (_) => getIt<RecurringPaymentCubit>(),
        ),
        BlocProvider<HomeDashboardCubit>(
          create: (_) => getIt<HomeDashboardCubit>(),
        ),
      ],
      // A language change refreshes the text of already-scheduled
      // notifications (Pitfall 9).
      child: BlocListener<LocaleCubit, LocaleState>(
        listenWhen: (previous, current) => previous.locale != current.locale,
        listener:
            (context, state) => getIt<NotificationReconciler>()
                .requestReconcile(ReconcileReason.localeChange),
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
                child: const AppShell(),
              ),
            );
          },
        ),
      ),
    );
  }
}
