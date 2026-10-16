// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:agenda/application/finance/budget/budget_cubit.dart' as _i759;
import 'package:agenda/application/finance/dashboard/home_dashboard_cubit.dart'
    as _i428;
import 'package:agenda/application/finance/debt/debt_cubit.dart' as _i710;
import 'package:agenda/application/finance/goal/goal_cubit.dart' as _i316;
import 'package:agenda/application/finance/goal/goal_list_cubit.dart' as _i665;
import 'package:agenda/application/finance/recurring/recurring_payment_cubit.dart'
    as _i275;
import 'package:agenda/application/finance/transaction/transaction_cubit.dart'
    as _i1065;
import 'package:agenda/application/notifications/budget_alert_evaluator.dart'
    as _i892;
import 'package:agenda/application/notifications/goal_alert_evaluator.dart'
    as _i708;
import 'package:agenda/application/notifications/notification_settings_cubit.dart'
    as _i290;
import 'package:agenda/application/shared/locale/locale_cubit.dart' as _i101;
import 'package:agenda/application/tasks/day_planner/day_planner_cubit.dart'
    as _i1073;
import 'package:agenda/application/tasks/project/project_cubit.dart' as _i646;
import 'package:agenda/application/tasks/task_list/task_list_cubit.dart'
    as _i726;
import 'package:agenda/config/di/backup_module.dart' as _i180;
import 'package:agenda/config/di/core_module.dart' as _i84;
import 'package:agenda/config/di/finance_module.dart' as _i650;
import 'package:agenda/config/di/infrastructure_module.dart' as _i728;
import 'package:agenda/config/di/notifications_module.dart' as _i71;
import 'package:agenda/config/di/tasks_module.dart' as _i619;
import 'package:agenda/data/backup/dao/backup_dao.dart' as _i728;
import 'package:agenda/data/database/isar_service.dart' as _i43;
import 'package:agenda/data/finance/budget/budget_dao.dart' as _i1035;
import 'package:agenda/data/finance/budget/budget_mapper.dart' as _i233;
import 'package:agenda/data/finance/category/transaction_category_dao.dart'
    as _i404;
import 'package:agenda/data/finance/category/transaction_category_mapper.dart'
    as _i9;
import 'package:agenda/data/finance/debt/debt_dao.dart' as _i731;
import 'package:agenda/data/finance/debt/debt_mapper.dart' as _i539;
import 'package:agenda/data/finance/goal/goal_mapper.dart' as _i249;
import 'package:agenda/data/finance/goal/savings_goal_dao.dart' as _i514;
import 'package:agenda/data/finance/recurring/recurring_payment_dao.dart'
    as _i1024;
import 'package:agenda/data/finance/recurring/recurring_payment_mapper.dart'
    as _i568;
import 'package:agenda/data/finance/transaction/transaction_dao.dart' as _i357;
import 'package:agenda/data/finance/transaction/transaction_mapper.dart'
    as _i536;
import 'package:agenda/data/tasks/item_dao.dart' as _i409;
import 'package:agenda/data/tasks/item_mapper.dart' as _i546;
import 'package:agenda/domain/backup/backup_repository.dart' as _i357;
import 'package:agenda/domain/finance/budget/budget_repository.dart' as _i877;
import 'package:agenda/domain/finance/category/transaction_category_repository.dart'
    as _i200;
import 'package:agenda/domain/finance/debt/debt_repository.dart' as _i169;
import 'package:agenda/domain/finance/goal/goal_repository.dart' as _i858;
import 'package:agenda/domain/finance/recurring/recurring_payment_repository.dart'
    as _i385;
import 'package:agenda/domain/finance/transaction/transaction_repository.dart'
    as _i585;
import 'package:agenda/domain/notifications/alert_state_store.dart' as _i183;
import 'package:agenda/domain/notifications/local_notification_gateway.dart'
    as _i114;
import 'package:agenda/domain/notifications/notification_permission_service.dart'
    as _i300;
import 'package:agenda/domain/notifications/notification_prefs_repository.dart'
    as _i944;
import 'package:agenda/domain/notifications/notification_reconciler.dart'
    as _i173;
import 'package:agenda/domain/notifications/planner/reminder_planner.dart'
    as _i363;
import 'package:agenda/domain/tasks/item_repository.dart' as _i565;
import 'package:agenda/domain/tasks/recurrence_engine.dart' as _i44;
import 'package:agenda/infrastructure/backup/backup_repository_impl.dart'
    as _i466;
import 'package:agenda/infrastructure/finance/budget_repository_impl.dart'
    as _i576;
import 'package:agenda/infrastructure/finance/debt_repository_impl.dart'
    as _i763;
import 'package:agenda/infrastructure/finance/goal_repository_impl.dart'
    as _i904;
import 'package:agenda/infrastructure/finance/recurring_payment_repository_impl.dart'
    as _i574;
import 'package:agenda/infrastructure/finance/transaction_category_repository_impl.dart'
    as _i986;
import 'package:agenda/infrastructure/finance/transaction_repository_impl.dart'
    as _i47;
import 'package:agenda/infrastructure/notifications/content/notification_content_builder.dart'
    as _i441;
import 'package:agenda/infrastructure/notifications/gateway/flutter_local_notifications_gateway.dart'
    as _i322;
import 'package:agenda/infrastructure/notifications/gateway/notification_permission_service_impl.dart'
    as _i789;
import 'package:agenda/infrastructure/notifications/prefs/alert_state_store_impl.dart'
    as _i829;
import 'package:agenda/infrastructure/notifications/prefs/notification_prefs_repository_impl.dart'
    as _i958;
import 'package:agenda/infrastructure/notifications/sync/immediate_alert_dispatcher.dart'
    as _i745;
import 'package:agenda/infrastructure/notifications/sync/notification_sync_coordinator.dart'
    as _i380;
import 'package:agenda/infrastructure/notifications/sync/permission_gate.dart'
    as _i478;
import 'package:agenda/infrastructure/notifications/sync/reconcile_runner.dart'
    as _i154;
import 'package:agenda/infrastructure/notifications/sync/snapshot_loader.dart'
    as _i61;
import 'package:agenda/infrastructure/tasks/item_repository_impl.dart' as _i215;
import 'package:agenda/infrastructure/tasks/recurrence_engine_impl.dart'
    as _i317;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as _i163;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final coreModule = _$CoreModule();
    final financeModule = _$FinanceModule();
    final infrastructureModule = _$InfrastructureModule();
    final notificationsModule = _$NotificationsModule();
    final tasksModule = _$TasksModule();
    final backupModule = _$BackupModule();
    gh.factory<_i1073.DayPlannerCubit>(() => _i1073.DayPlannerCubit());
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => coreModule.sharedPreferences,
      preResolve: true,
    );
    gh.singleton<_i43.IsarService>(() => coreModule.isarService);
    gh.lazySingleton<_i536.TransactionMapper>(
      () => financeModule.transactionMapper,
    );
    gh.lazySingleton<_i9.TransactionCategoryMapper>(
      () => financeModule.transactionCategoryMapper,
    );
    gh.lazySingleton<_i233.BudgetMapper>(() => financeModule.budgetMapper);
    gh.lazySingleton<_i249.GoalMapper>(() => financeModule.goalMapper);
    gh.lazySingleton<_i539.DebtMapper>(() => financeModule.debtMapper);
    gh.lazySingleton<_i568.RecurringPaymentMapper>(
      () => financeModule.recurringPaymentMapper,
    );
    gh.lazySingleton<_i163.FlutterLocalNotificationsPlugin>(
      () => infrastructureModule.notificationsPlugin,
    );
    gh.lazySingleton<_i363.ReminderPlanner>(
      () => notificationsModule.reminderPlanner,
    );
    gh.lazySingleton<_i546.ItemMapper>(() => tasksModule.itemMapper);
    gh.lazySingleton<_i441.NotificationContentBuilder>(
      () => const _i441.NotificationContentBuilder(),
    );
    gh.lazySingleton<_i728.BackupDao>(
      () => backupModule.backupDao(gh<_i43.IsarService>()),
    );
    gh.lazySingleton<_i357.TransactionDao>(
      () => financeModule.transactionDao(gh<_i43.IsarService>()),
    );
    gh.lazySingleton<_i404.TransactionCategoryDao>(
      () => financeModule.transactionCategoryDao(gh<_i43.IsarService>()),
    );
    gh.lazySingleton<_i1035.BudgetDao>(
      () => financeModule.budgetDao(gh<_i43.IsarService>()),
    );
    gh.lazySingleton<_i514.SavingsGoalDao>(
      () => financeModule.savingsGoalDao(gh<_i43.IsarService>()),
    );
    gh.lazySingleton<_i731.DebtDao>(
      () => financeModule.debtDao(gh<_i43.IsarService>()),
    );
    gh.lazySingleton<_i1024.RecurringPaymentDao>(
      () => financeModule.recurringPaymentDao(gh<_i43.IsarService>()),
    );
    gh.lazySingleton<_i409.ItemDao>(
      () => tasksModule.itemDao(gh<_i43.IsarService>()),
    );
    gh.lazySingleton<_i858.GoalRepository>(
      () => _i904.GoalRepositoryImpl(
        gh<_i514.SavingsGoalDao>(),
        gh<_i249.GoalMapper>(),
      ),
    );
    gh.lazySingleton<_i183.AlertStateStore>(
      () => _i829.AlertStateStoreImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i944.NotificationPrefsRepository>(
      () =>
          _i958.NotificationPrefsRepositoryImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i44.RecurrenceEngine>(
      () => const _i317.RecurrenceEngineImpl(),
    );
    gh.lazySingleton<_i357.BackupRepository>(
      () => _i466.BackupRepositoryImpl(gh<_i728.BackupDao>()),
    );
    gh.factory<_i665.GoalListCubit>(
      () => _i665.GoalListCubit(gh<_i858.GoalRepository>()),
    );
    gh.lazySingleton<_i385.RecurringPaymentRepository>(
      () => _i574.RecurringPaymentRepositoryImpl(
        gh<_i1024.RecurringPaymentDao>(),
        gh<_i568.RecurringPaymentMapper>(),
      ),
    );
    gh.lazySingleton<_i169.DebtRepository>(
      () =>
          _i763.DebtRepositoryImpl(gh<_i731.DebtDao>(), gh<_i539.DebtMapper>()),
    );
    gh.lazySingleton<_i114.LocalNotificationGateway>(
      () => _i322.FlutterLocalNotificationsGateway(
        gh<_i163.FlutterLocalNotificationsPlugin>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_i710.DebtCubit>(
      () => _i710.DebtCubit(gh<_i169.DebtRepository>()),
    );
    gh.factory<_i101.LocaleCubit>(
      () => _i101.LocaleCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i585.TransactionRepository>(
      () => _i47.TransactionRepositoryImpl(
        gh<_i357.TransactionDao>(),
        gh<_i536.TransactionMapper>(),
      ),
    );
    gh.lazySingleton<_i300.NotificationPermissionService>(
      () => _i789.NotificationPermissionServiceImpl(
        gh<_i163.FlutterLocalNotificationsPlugin>(),
      ),
    );
    gh.lazySingleton<_i200.TransactionCategoryRepository>(
      () => _i986.TransactionCategoryRepositoryImpl(
        gh<_i404.TransactionCategoryDao>(),
        gh<_i9.TransactionCategoryMapper>(),
      ),
    );
    gh.factory<_i316.GoalCubit>(
      () => _i316.GoalCubit(
        gh<_i858.GoalRepository>(),
        gh<_i585.TransactionRepository>(),
      ),
    );
    gh.lazySingleton<_i565.ItemRepository>(
      () => _i215.ItemRepositoryImpl(
        gh<_i409.ItemDao>(),
        gh<_i546.ItemMapper>(),
        gh<_i44.RecurrenceEngine>(),
      ),
    );
    gh.lazySingleton<_i877.BudgetRepository>(
      () => _i576.BudgetRepositoryImpl(
        gh<_i1035.BudgetDao>(),
        gh<_i233.BudgetMapper>(),
      ),
    );
    gh.factory<_i275.RecurringPaymentCubit>(
      () => _i275.RecurringPaymentCubit(gh<_i385.RecurringPaymentRepository>()),
    );
    gh.factory<_i428.HomeDashboardCubit>(
      () => _i428.HomeDashboardCubit(
        gh<_i585.TransactionRepository>(),
        gh<_i858.GoalRepository>(),
        gh<_i169.DebtRepository>(),
        gh<_i200.TransactionCategoryRepository>(),
      ),
    );
    gh.factory<_i646.ProjectCubit>(
      () => _i646.ProjectCubit(gh<_i565.ItemRepository>()),
    );
    gh.factory<_i726.TaskListCubit>(
      () => _i726.TaskListCubit(
        gh<_i565.ItemRepository>(),
        gh<_i44.RecurrenceEngine>(),
      ),
    );
    gh.lazySingleton<_i478.PermissionGate>(
      () => _i478.PermissionGate(
        gh<_i300.NotificationPermissionService>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_i1065.TransactionCubit>(
      () => _i1065.TransactionCubit(
        gh<_i585.TransactionRepository>(),
        gh<_i200.TransactionCategoryRepository>(),
      ),
    );
    gh.lazySingleton<_i61.SnapshotLoader>(
      () => _i61.SnapshotLoader(
        gh<_i565.ItemRepository>(),
        gh<_i169.DebtRepository>(),
        gh<_i858.GoalRepository>(),
        gh<_i385.RecurringPaymentRepository>(),
        gh<_i585.TransactionRepository>(),
        gh<_i944.NotificationPrefsRepository>(),
        gh<_i183.AlertStateStore>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.lazySingleton<_i154.ReconcileRunner>(
      () => _i154.ReconcileRunner(
        gh<_i61.SnapshotLoader>(),
        gh<_i363.ReminderPlanner>(),
        gh<_i441.NotificationContentBuilder>(),
        gh<_i114.LocalNotificationGateway>(),
        gh<_i300.NotificationPermissionService>(),
        gh<_i478.PermissionGate>(),
        gh<_i183.AlertStateStore>(),
      ),
    );
    gh.factory<_i759.BudgetCubit>(
      () => _i759.BudgetCubit(
        gh<_i585.TransactionRepository>(),
        gh<_i877.BudgetRepository>(),
        gh<_i200.TransactionCategoryRepository>(),
      ),
    );
    gh.lazySingleton<_i745.ImmediateAlertDispatcher>(
      () => _i745.ImmediateAlertDispatcher(
        gh<_i114.LocalNotificationGateway>(),
        gh<_i944.NotificationPrefsRepository>(),
        gh<_i300.NotificationPermissionService>(),
        gh<_i478.PermissionGate>(),
        gh<_i441.NotificationContentBuilder>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.lazySingleton<_i173.NotificationReconciler>(
      () => _i380.NotificationSyncCoordinator(
        gh<_i154.ReconcileRunner>(),
        gh<_i565.ItemRepository>(),
        gh<_i169.DebtRepository>(),
        gh<_i858.GoalRepository>(),
        gh<_i585.TransactionRepository>(),
        gh<_i385.RecurringPaymentRepository>(),
        gh<_i944.NotificationPrefsRepository>(),
      ),
    );
    gh.lazySingleton<_i708.GoalAlertEvaluator>(
      () => _i708.GoalAlertEvaluator(
        gh<_i858.GoalRepository>(),
        gh<_i585.TransactionRepository>(),
        gh<_i183.AlertStateStore>(),
        gh<_i745.ImmediateAlertDispatcher>(),
        gh<_i944.NotificationPrefsRepository>(),
      ),
    );
    gh.factory<_i290.NotificationSettingsCubit>(
      () => _i290.NotificationSettingsCubit(
        gh<_i944.NotificationPrefsRepository>(),
        gh<_i300.NotificationPermissionService>(),
        gh<_i173.NotificationReconciler>(),
      ),
    );
    gh.lazySingleton<_i892.BudgetAlertEvaluator>(
      () => _i892.BudgetAlertEvaluator(
        gh<_i585.TransactionRepository>(),
        gh<_i877.BudgetRepository>(),
        gh<_i200.TransactionCategoryRepository>(),
        gh<_i183.AlertStateStore>(),
        gh<_i745.ImmediateAlertDispatcher>(),
        gh<_i944.NotificationPrefsRepository>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    return this;
  }
}

class _$CoreModule extends _i84.CoreModule {}

class _$FinanceModule extends _i650.FinanceModule {}

class _$InfrastructureModule extends _i728.InfrastructureModule {}

class _$NotificationsModule extends _i71.NotificationsModule {}

class _$TasksModule extends _i619.TasksModule {}

class _$BackupModule extends _i180.BackupModule {}
