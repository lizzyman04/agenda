import 'package:agenda/app.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:flutter/material.dart';

/// Application entry point.
///
/// Execution order (D-17):
/// 1. WidgetsFlutterBinding.ensureInitialized — required for
///    async work before runApp.
/// 2. configureDependencies — builds the GetIt graph; pre-resolves
///    async singletons (SharedPreferences). Must complete before
///    runApp so all call sites resolve.
/// 3. IsarService.open — opens the Isar database with Phase 2 schemas.
/// 4. runApp — starts the widget tree.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await IsarService.instance.open([ItemModelSchema]);
  runApp(const AgendaApp());
}
