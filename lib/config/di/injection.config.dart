// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:agenda/application/shared/locale/locale_cubit.dart' as _i101;
import 'package:agenda/config/di/core_module.dart' as _i84;
import 'package:agenda/data/database/isar_service.dart' as _i43;
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
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => coreModule.sharedPreferences,
      preResolve: true,
    );
    gh.singleton<_i43.IsarService>(() => coreModule.isarService);
    gh.factory<_i101.LocaleCubit>(
      () => _i101.LocaleCubit(gh<_i460.SharedPreferences>()),
    );
    return this;
  }
}

class _$CoreModule extends _i84.CoreModule {}
