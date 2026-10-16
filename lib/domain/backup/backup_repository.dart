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
}
