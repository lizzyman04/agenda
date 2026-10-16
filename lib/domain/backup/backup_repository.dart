import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/backup/backup_file.dart';

/// Contract for exporting (and, in later plans, importing) user data.
///
/// Every fallible method returns [AsyncResult] and never throws. The
/// implementation lives in `lib/infrastructure/backup/`.
// Single member for now; import is added by a later plan (04-11).
// ignore: one_member_abstracts
abstract interface class BackupRepository {
  /// Serialises every row of all seven collections, soft-deleted rows
  /// included, into a versioned JSON document.
  ///
  /// The returned file is named `agenda-backup-YYYY-MM-DD.json` after [now]
  /// (defaults to the current time). Failures map to `BackupFailure`.
  AsyncResult<BackupFile> exportJson({DateTime? now});
}
