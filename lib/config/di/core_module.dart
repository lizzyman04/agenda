import 'package:agenda/data/database/isar_service.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// DI registrations for cross-cutting infrastructure (database, preferences).
///
/// [IsarService] is a process-wide singleton — only one Isar connection exists.
/// [SharedPreferences] is pre-resolved async so it is available synchronously
/// after configureDependencies() completes.
@module
abstract class CoreModule {
  /// Registers [IsarService.instance] as a singleton.
  ///
  /// The instance manages its own open/close lifecycle. DI consumers call
  /// [IsarService.db] after the app shell has called [IsarService.open].
  @singleton
  IsarService get isarService => IsarService.instance;

  /// Registers [SharedPreferences] as a pre-resolved async singleton.
  ///
  /// [SharedPreferences.getInstance()] is awaited during configureDependencies.
  /// All classes that need [SharedPreferences] (e.g. LocaleCubit) receive it
  /// via constructor injection.
  @preResolve
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();
}
