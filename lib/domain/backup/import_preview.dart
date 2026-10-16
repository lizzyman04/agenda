import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/domain/backup/backup_entity.dart';

/// Where an import comes from: one JSON document or a set of CSV files.
enum ImportSource { json, csv }

/// What an import would do, computed in memory before anything is written.
final class ImportPreview {
  const ImportPreview({
    required this.source,
    required this.counts,
    required this.softDeletedCount,
    required this.earliest,
    required this.latest,
    required this.exportedAt,
    required this.danglingLinks,
    required this.replaced,
  });

  final ImportSource source;

  /// Rows per supplied entity: active rows for entities with a deletion
  /// mark, all rows for budgets and categories.
  final Map<BackupEntity, int> counts;

  /// Soft-deleted rows carried along (not part of [counts]).
  final int softDeletedCount;

  /// Oldest and newest `createdAt` across every supplied row; null when the
  /// file holds no rows.
  final DateTime? earliest;
  final DateTime? latest;

  /// When the JSON backup was exported; null for CSV.
  final DateTime? exportedAt;

  /// Foreign keys that point at nothing in the file. Warnings only: the app
  /// hard-deletes custom categories, so a user's own export can hold them.
  final int danglingLinks;

  /// Entities whose current data the import replaces.
  final Set<BackupEntity> replaced;

  int get totalRecords => counts.values.fold(0, (a, b) => a + b);

  /// True when only some entities are replaced (every CSV import).
  bool get isPartial => replaced.length < BackupEntity.values.length;
}

/// Outcome of a committed import.
final class ImportResult {
  const ImportResult({required this.counts, required this.safetyBackupPath});

  /// Rows written per replaced entity.
  final Map<BackupEntity, int> counts;

  /// Absolute path of the safety backup taken just before the replace.
  final String safetyBackupPath;
}

/// Machine-readable import error codes. They prefix a `BackupFailure`
/// message as `<code>: <detail>`; the UI maps each to localized text.
abstract final class ImportErrorCode {
  static const String unsupported = 'unsupported';
  static const String tooLarge = 'tooLarge';
  static const String newerVersion = 'newerVersion';
  static const String mixed = 'mixed';
  static const String duplicate = 'duplicate';
  static const String empty = 'empty';
  static const String importFailed = 'importFailed';
  static const String invalid = 'invalid';

  static const Set<String> all = {
    unsupported,
    tooLarge,
    newerVersion,
    mixed,
    duplicate,
    empty,
    importFailed,
    invalid,
  };
}

/// The [ImportErrorCode] of a backup [failure], or null when its message
/// does not start with a known code.
String? importErrorCodeOf(Failure failure) {
  if (failure is! BackupFailure) return null;
  final colon = failure.message.indexOf(':');
  if (colon < 0) return null;
  final code = failure.message.substring(0, colon);
  return ImportErrorCode.all.contains(code) ? code : null;
}
