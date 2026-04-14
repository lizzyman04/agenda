// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:agenda/application/shared/locale/locale_cubit.dart' as _i101;
import 'package:agenda/application/tasks/day_planner/day_planner_cubit.dart'
    as _i1073;
import 'package:agenda/application/tasks/project/project_cubit.dart' as _i646;
import 'package:agenda/application/tasks/task_list/task_list_cubit.dart'
    as _i726;
import 'package:agenda/config/di/core_module.dart' as _i84;
import 'package:agenda/config/di/tasks_module.dart' as _i619;
import 'package:agenda/data/database/isar_service.dart' as _i43;
import 'package:agenda/data/tasks/item_dao.dart' as _i409;
import 'package:agenda/data/tasks/item_mapper.dart' as _i546;
import 'package:agenda/domain/tasks/item_repository.dart' as _i565;
import 'package:agenda/domain/tasks/recurrence_engine.dart' as _i44;
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
    final tasksModule = _$TasksModule();
    gh.factory<_i1073.DayPlannerCubit>(() => _i1073.DayPlannerCubit());
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => coreModule.sharedPreferences,
      preResolve: true,
    );
    gh.singleton<_i43.IsarService>(() => coreModule.isarService);
    gh.lazySingleton<_i546.ItemMapper>(() => tasksModule.itemMapper);
    gh.lazySingleton<_i409.ItemDao>(
      () => tasksModule.itemDao(gh<_i43.IsarService>()),
    );
    gh.lazySingleton<_i44.RecurrenceEngine>(
      () => const _i317.RecurrenceEngineImpl(),
    );
    gh.factory<_i101.LocaleCubit>(
      () => _i101.LocaleCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i565.ItemRepository>(
      () => _i215.ItemRepositoryImpl(
        gh<_i409.ItemDao>(),
        gh<_i546.ItemMapper>(),
        gh<_i44.RecurrenceEngine>(),
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
    return this;
  }
}

class _$CoreModule extends _i84.CoreModule {}

class _$TasksModule extends _i619.TasksModule {}
