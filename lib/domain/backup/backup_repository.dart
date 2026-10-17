import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/backup/backup_file.dart';
import 'package:agenda/domain/backup/import_preview.dart';

/// Contract for exporting and importing user data.
///
/// Every fallible method returns [AsyncResult] and never throws. The
/// implementation lives in `lib/infrastructure/backup/`.
abstract interface class BackupRepository {
  /// Serialises every row of all seven collections, soft-deleted rows
  /// included, into a versioned JSON document.
  ///
  /// The returned file is named `agenda-backup-YYYY-MM-DD.json` after [now]
  /// (defaults to the current time). Failures map to `BackupFailure`.
  AsyncResult<BackupFile> exportJson({DateTime? now});

  /// Exports one CSV file per entity (tasks, transactions, budgets, goals,
  /// debts, recurring_payments), in that order.
  ///
  /// Files are named `agenda-<stem>-YYYY-MM-DD.csv` after [now] (defaults to
  /// the current time) and contain only ACTIVE rows (soft-deleted rows are
  /// excluded). [languageCode] selects the dialect: `en` writes `,` between
  /// fields and `.` as decimal separator, any other code (PT-BR) writes `;`
  /// and `,`. Headers are always the canonical English column names.
  /// Failures map to `BackupFailure`.
  AsyncResult<List<BackupFile>> exportCsv({
    required String languageCode,
    DateTime? now,
  });

  /// Parses and validates [files] (one JSON backup, or CSV files) entirely
  /// in memory and returns what an import would do. Writes nothing.
  ///
  /// Failures map to `BackupFailure` whose message starts with an
  /// `ImportErrorCode` (see `importErrorCodeOf`). The repository holds at
  /// most one prepared import; calling this again replaces it.
  AsyncResult<ImportPreview> prepareImport(List<BackupFile> files);

  /// Commits the prepared import: writes a safety backup of the CURRENT
  /// data, then replaces data in one atomic transaction. JSON replaces all
  /// seven collections; CSV replaces only the entities it supplied.
  ///
  /// Returns an `empty` error when nothing is prepared or another commit is
  /// running. If the replace fails the database is unchanged and
  /// [lastSafetyBackupPath] still names the safety backup.
  AsyncResult<ImportResult> commitImport();

  /// Forgets the prepared import without writing anything.
  void discardImport();

  /// Path of the newest safety backup written by [commitImport], or null.
  String? get lastSafetyBackupPath;

  /// How many safety backups exist on the device (0 to 3).
  ///
  /// Never throws; failures map to `BackupFailure`.
  AsyncResult<int> safetyBackupCount();

  /// The newest safety backup as an ordinary JSON backup, or `Success(null)`
  /// when none exists.
  ///
  /// The returned name is the generated file name, never a path. Never
  /// throws; failures map to `BackupFailure`.
  AsyncResult<BackupFile?> latestSafetyBackup();

  /// Deletes every safety backup and returns how many were removed.
  ///
  /// Only files with a generated safety-backup name are touched. Never
  /// throws; failures map to `BackupFailure`.
  AsyncResult<int> deleteSafetyBackups();
}
