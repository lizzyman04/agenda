import 'package:agenda/core/config/app_config.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sequential schema migration runner.
///
/// Design (D-16):
/// - [AppConfig.schemaVersion] is the target — bump it when a new migration
///   block is added here.
/// - The current version is stored in [SharedPreferences] under
///   [StorageKeys.schemaVersion] — readable BEFORE Isar opens.
/// - [run] is called inside IsarService.open on every cold start.
/// - Migrations execute once in ascending order; each successful run writes
///   the new version to prefs before executing the next block.
class MigrationRunner {
  MigrationRunner._();

  /// Runs all pending migrations from current+1 up to
  /// [AppConfig.schemaVersion].
  ///
  /// No-op when the stored version is already current.
  static Future<void> run(Isar isar, SharedPreferences prefs) async {
    final current = prefs.getInt(StorageKeys.schemaVersion) ?? 0;
    const target = AppConfig.schemaVersion;

    if (current >= target) return;

    for (var v = current + 1; v <= target; v++) {
      await _runMigration(isar, v);
      await prefs.setInt(StorageKeys.schemaVersion, v);
    }
  }

  static Future<void> _runMigration(Isar isar, int toVersion) async {
    switch (toVersion) {
      case 1:
        // Initial schema — no data migration needed.
        return;
      case 2:
        // Add ItemModel collection (tasks, projects, subtasks).
        // No data migration needed — new empty collection.
        return;
    }
  }
}
