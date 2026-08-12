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
import 'package:agenda/application/shared/locale/locale_cubit.dart' as _i101;
import 'package:agenda/application/tasks/day_planner/day_planner_cubit.dart'
    as _i1073;
import 'package:agenda/application/tasks/project/project_cubit.dart' as _i646;
import 'package:agenda/application/tasks/task_list/task_list_cubit.dart'
    as _i726;
import 'package:agenda/config/di/core_module.dart' as _i84;
import 'package:agenda/config/di/finance_module.dart' as _i650;
import 'package:agenda/config/di/tasks_module.dart' as _i619;
import 'package:agenda/data/database/isar_service.dart' as _i43;
import 'package:agenda/data/finance/budget_dao.dart' as _i337;
import 'package:agenda/data/finance/budget_mapper.dart' as _i289;
import 'package:agenda/data/finance/debt_dao.dart' as _i647;
import 'package:agenda/data/finance/debt_mapper.dart' as _i630;
import 'package:agenda/data/finance/goal_mapper.dart' as _i1064;
import 'package:agenda/data/finance/recurring_payment_dao.dart' as _i488;
import 'package:agenda/data/finance/recurring_payment_mapper.dart' as _i352;
import 'package:agenda/data/finance/savings_goal_dao.dart' as _i782;
import 'package:agenda/data/finance/transaction_category_dao.dart' as _i514;
import 'package:agenda/data/finance/transaction_category_mapper.dart' as _i906;
import 'package:agenda/data/finance/transaction_dao.dart' as _i264;
import 'package:agenda/data/finance/transaction_mapper.dart' as _i851;
import 'package:agenda/data/tasks/item_dao.dart' as _i409;
import 'package:agenda/data/tasks/item_mapper.dart' as _i546;
import 'package:agenda/domain/finance/budget/budget_repository.dart' as _i877;
import 'package:agenda/domain/finance/category/transaction_category_repository.dart'
    as _i200;
import 'package:agenda/domain/finance/debt/debt_repository.dart' as _i169;
import 'package:agenda/domain/finance/goal/goal_repository.dart' as _i858;
import 'package:agenda/domain/finance/recurring/recurring_payment_repository.dart'
    as _i385;
import 'package:agenda/domain/finance/transaction/transaction_repository.dart'
    as _i585;
import 'package:agenda/domain/tasks/item_repository.dart' as _i565;
import 'package:agenda/domain/tasks/recurrence_engine.dart' as _i44;
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
import 'package:agenda/infrastructure/tasks/item_repository_impl.dart' as _i215;
import 'package:agenda/infrastructure/tasks/recurrence_engine_impl.dart'
    as _i317;
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
    final tasksModule = _$TasksModule();
    gh.factory<_i1073.DayPlannerCubit>(() => _i1073.DayPlannerCubit());
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => coreModule.sharedPreferences,
      preResolve: true,
    );
    gh.singleton<_i43.IsarService>(() => coreModule.isarService);
    gh.lazySingleton<_i851.TransactionMapper>(
      () => financeModule.transactionMapper,
    );
    gh.lazySingleton<_i906.TransactionCategoryMapper>(
      () => financeModule.transactionCategoryMapper,
    );
    gh.lazySingleton<_i289.BudgetMapper>(() => financeModule.budgetMapper);
    gh.lazySingleton<_i1064.GoalMapper>(() => financeModule.goalMapper);
    gh.lazySingleton<_i630.DebtMapper>(() => financeModule.debtMapper);
    gh.lazySingleton<_i352.RecurringPaymentMapper>(
      () => financeModule.recurringPaymentMapper,
    );
    gh.lazySingleton<_i546.ItemMapper>(() => tasksModule.itemMapper);
    gh.lazySingleton<_i264.TransactionDao>(
      () => financeModule.transactionDao(gh<_i43.IsarService>()),
    );
    gh.lazySingleton<_i514.TransactionCategoryDao>(
      () => financeModule.transactionCategoryDao(gh<_i43.IsarService>()),
    );
    gh.lazySingleton<_i337.BudgetDao>(
      () => financeModule.budgetDao(gh<_i43.IsarService>()),
    );
    gh.lazySingleton<_i782.SavingsGoalDao>(
      () => financeModule.savingsGoalDao(gh<_i43.IsarService>()),
    );
    gh.lazySingleton<_i647.DebtDao>(
      () => financeModule.debtDao(gh<_i43.IsarService>()),
    );
    gh.lazySingleton<_i488.RecurringPaymentDao>(
      () => financeModule.recurringPaymentDao(gh<_i43.IsarService>()),
    );
    gh.lazySingleton<_i409.ItemDao>(
      () => tasksModule.itemDao(gh<_i43.IsarService>()),
    );
    gh.lazySingleton<_i877.BudgetRepository>(
      () => _i576.BudgetRepositoryImpl(
        gh<_i337.BudgetDao>(),
        gh<_i289.BudgetMapper>(),
      ),
    );
    gh.lazySingleton<_i200.TransactionCategoryRepository>(
      () => _i986.TransactionCategoryRepositoryImpl(
        gh<_i514.TransactionCategoryDao>(),
        gh<_i906.TransactionCategoryMapper>(),
      ),
    );
    gh.lazySingleton<_i858.GoalRepository>(
      () => _i904.GoalRepositoryImpl(
        gh<_i782.SavingsGoalDao>(),
        gh<_i1064.GoalMapper>(),
      ),
    );
    gh.lazySingleton<_i585.TransactionRepository>(
      () => _i47.TransactionRepositoryImpl(
        gh<_i264.TransactionDao>(),
        gh<_i851.TransactionMapper>(),
      ),
    );
    gh.lazySingleton<_i44.RecurrenceEngine>(
      () => const _i317.RecurrenceEngineImpl(),
    );
    gh.factory<_i665.GoalListCubit>(
      () => _i665.GoalListCubit(gh<_i858.GoalRepository>()),
    );
    gh.factory<_i1065.TransactionCubit>(
      () => _i1065.TransactionCubit(gh<_i585.TransactionRepository>()),
    );
    gh.factory<_i101.LocaleCubit>(
      () => _i101.LocaleCubit(gh<_i460.SharedPreferences>()),
    );
    gh.factory<_i759.BudgetCubit>(
      () => _i759.BudgetCubit(
        gh<_i585.TransactionRepository>(),
        gh<_i877.BudgetRepository>(),
        gh<_i200.TransactionCategoryRepository>(),
      ),
    );
    gh.lazySingleton<_i169.DebtRepository>(
      () =>
          _i763.DebtRepositoryImpl(gh<_i647.DebtDao>(), gh<_i630.DebtMapper>()),
    );
    gh.factory<_i316.GoalCubit>(
      () => _i316.GoalCubit(
        gh<_i858.GoalRepository>(),
        gh<_i585.TransactionRepository>(),
      ),
    );
    gh.lazySingleton<_i385.RecurringPaymentRepository>(
      () => _i574.RecurringPaymentRepositoryImpl(
        gh<_i488.RecurringPaymentDao>(),
        gh<_i352.RecurringPaymentMapper>(),
      ),
    );
    gh.lazySingleton<_i565.ItemRepository>(
      () => _i215.ItemRepositoryImpl(
        gh<_i409.ItemDao>(),
        gh<_i546.ItemMapper>(),
        gh<_i44.RecurrenceEngine>(),
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
    gh.factory<_i710.DebtCubit>(
      () => _i710.DebtCubit(gh<_i169.DebtRepository>()),
    );
    return this;
  }
}

class _$CoreModule extends _i84.CoreModule {}

class _$FinanceModule extends _i650.FinanceModule {}

class _$TasksModule extends _i619.TasksModule {}
