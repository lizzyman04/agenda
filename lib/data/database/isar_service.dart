import 'package:agenda/data/database/migration_runner.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton wrapper around the [Isar] database instance.
///
/// Usage:
/// ```dart
/// await IsarService.instance.open([/* schemas */]);
/// final isar = IsarService.instance.db;
/// ```
///
/// [open] is idempotent — calling it multiple times is safe.
/// Register via DI in CoreModule so call sites never call [open] directly.
class IsarService {
  IsarService._();

  /// The process-wide singleton instance.
  static final IsarService instance = IsarService._();

  Isar? _isar;

  /// The open [Isar] instance.
  ///
  /// Throws [AssertionError] if accessed before [open] completes.
  Isar get db {
    assert(_isar != null, 'IsarService not initialised. Call open() first.');
    return _isar!;
  }

  /// Opens the database at the application documents directory.
  ///
  /// Runs [MigrationRunner] on every cold start. If the database is already
  /// open, this method returns immediately without opening a second connection.
  ///
  /// [schemas] — pass all [CollectionSchema] objects for the current schema
  /// version. In Phase 1 the list is empty; Phase 2 adds task schemas.
  Future<void> open(List<CollectionSchema<dynamic>> schemas) async {
    if (_isar != null && _isar!.isOpen) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(schemas, directory: dir.path);

    final prefs = await SharedPreferences.getInstance();
    await MigrationRunner.run(_isar!, prefs);
  }

  /// Closes the database and releases the instance.
  ///
  /// Call in test teardowns. Not needed in production — the OS reclaims
  /// resources on process exit.
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
