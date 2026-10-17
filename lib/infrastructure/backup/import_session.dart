import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/backup/dao/backup_dao.dart';
import 'package:agenda/data/backup/import/backup_importer.dart';
import 'package:agenda/data/backup/import/backup_snapshot.dart';
import 'package:agenda/data/backup/import/csv_category_resolver.dart';
import 'package:agenda/data/backup/import/import_preview_builder.dart';
import 'package:agenda/data/backup/import/safety_backup_store.dart';
import 'package:agenda/data/backup/import/snapshot_parser.dart';
import 'package:agenda/data/backup/import/snapshot_validator.dart';
import 'package:agenda/domain/backup/backup_file.dart';
import 'package:agenda/domain/backup/import_preview.dart';

/// The two-phase import behind `BackupRepositoryImpl`: prepare validates a file
/// in memory, commit writes a safety backup and then replaces data
/// atomically. Holds at most one prepared snapshot.
///
/// Privacy: file content is never logged; failures carry an error code plus
/// a row or path, or an exception type.
final class ImportSession {
  ImportSession({
    required BackupDao dao,
    required BackupImporter importer,
    required SafetyBackupStore store,
    required AsyncResult<BackupFile> Function({DateTime? now}) exportJson,
  }) : _dao = dao,
       _importer = importer,
       _store = store,
       _exportJson = exportJson;

  final BackupDao _dao;
  final BackupImporter _importer;
  final SafetyBackupStore _store;
  final AsyncResult<BackupFile> Function({DateTime? now}) _exportJson;

  BackupSnapshot? _pending;
  bool _committing = false;

  /// Path of the safety backup written by THIS import, or null until it
  /// exists. Reset at the start of every commit, so a failed import never
  /// names an earlier import's file (D-12: the path shown after a failure
  /// must belong to the failed import). Kept after a failed replace so the UI
  /// can show where the user's previous data is.
  String? lastSafetyBackupPath;

  /// Drops the prepared import, if any.
  void discard() => _pending = null;

  /// Parses and validates [files]; writes nothing.
  AsyncResult<ImportPreview> prepare(List<BackupFile> files) async {
    _pending = null;
    try {
      final now = DateTime.now();
      final snapshot = parseBackupFiles(files, now: now);
      final report = validateSnapshot(snapshot);
      if (report.errors.isNotEmpty) {
        throw BackupImportException(
          ImportErrorCode.invalid,
          report.errors.join('; '),
        );
      }
      if (snapshot.source == ImportSource.csv) {
        // Dry run: unresolvable category rows fail here, not at commit.
        resolveCsvCategories(snapshot, await _dao.readCategories(), now: now);
      }
      _pending = snapshot;
      return Success(buildImportPreview(snapshot, report));
    } on BackupImportException catch (e) {
      return Err(BackupFailure(e.toString()));
    } on Object catch (e) {
      return Err(BackupFailure('${ImportErrorCode.invalid}: ${e.runtimeType}'));
    }
  }

  /// Safety backup first, then one atomic replace.
  AsyncResult<ImportResult> commit() async {
    final snapshot = _pending;
    if (snapshot == null || _committing) {
      return const Err(
        BackupFailure('${ImportErrorCode.empty}: no import is prepared'),
      );
    }
    _committing = true;
    _pending = null;
    lastSafetyBackupPath = null;
    try {
      final now = DateTime.now();
      final backup = await _exportJson(now: now);
      if (backup is! Success<BackupFile>) {
        return const Err(
          BackupFailure(
            '${ImportErrorCode.importFailed}: safety backup failed',
          ),
        );
      }
      final path =
          lastSafetyBackupPath = await _store.write(
            backup.value.bytes,
          );
      final counts = await _importer.replace(snapshot, now: now);
      return Success(
        ImportResult(counts: countsByEntity(counts), safetyBackupPath: path),
      );
    } on Object catch (e) {
      return Err(
        BackupFailure('${ImportErrorCode.importFailed}: ${e.runtimeType}'),
      );
    } finally {
      _committing = false;
    }
  }
}
