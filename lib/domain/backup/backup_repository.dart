import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/backup/backup_file.dart';

/// Contract for exporting (and, in later plans, importing) user data.
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
}
