import 'package:agenda/app.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:flutter/material.dart';

/// Application entry point.
///
/// Execution order (D-17):
/// 1. WidgetsFlutterBinding.ensureInitialized — required for
///    async work before runApp.
/// 2. configureDependencies — builds the GetIt graph; pre-resolves
///    async singletons (SharedPreferences). Must complete before
///    runApp so all call sites resolve.
/// 3. IsarService.open — opens the Isar database (called at app
///    shell level once schemas are defined in Phase 2).
/// 4. runApp — starts the widget tree.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const AgendaApp());
}
