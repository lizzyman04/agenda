import 'package:agenda/application/backup/backup_state.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/backup/widgets/backup_error_text.dart';

/// The SnackBar text for a finished run, or null for states that show none
/// (idle, working, and the preview, which opens the confirmation screen).
String? backupOutcomeMessage(AppLocalizations l10n, BackupState state) {
  return switch (state) {
    BackupExportDone(csv: false) => l10n.backupExportDone,
    BackupExportDone(:final fileCount) => l10n.backupExportCsvDone(fileCount),
    BackupExportCancelled() => l10n.backupExportCancelled,
    BackupImportDone(:final result) =>
      '${l10n.backupImportDone} ${l10n.backupImportDoneCount(
        result.counts.values.fold(0, (a, b) => a + b),
      )}',
    BackupImportFailed(:final failure, :final safetyBackupPath) =>
      backupErrorMessage(l10n, failure, safetyBackupPath: safetyBackupPath),
    BackupFailed(:final failure) => backupErrorMessage(l10n, failure),
    _ => null,
  };
}
