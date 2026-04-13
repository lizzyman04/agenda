import 'package:agenda/config/di/injection.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

/// The global service locator instance.
///
/// Use getIt&lt;T&gt;() to resolve dependencies at call sites.
/// Never call GetIt.instance directly — always use this exported reference
/// so tests can reset the locator without touching global state.
final GetIt getIt = GetIt.instance;

/// Registers all dependencies and runs async pre-resolved singletons.
///
/// Must be awaited in main() before runApp() is called (D-17).
@InjectableInit()
Future<void> configureDependencies() async => getIt.init();
