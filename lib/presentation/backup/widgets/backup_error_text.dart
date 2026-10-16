import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/domain/backup/import_preview.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';

/// Maps a backup [failure] to localized text by its import error code.
///
/// The raw `Failure.message` is never shown: it can carry file details. An
/// `importFailed` code with a known [safetyBackupPath] says the data is
/// unchanged and where the safety backup is (D-12); without a path, and for
/// any unknown code, the generic message is used.
String backupErrorMessage(
  AppLocalizations l10n,
  Failure failure, {
  String? safetyBackupPath,
}) {
  return switch (importErrorCodeOf(failure)) {
    ImportErrorCode.unsupported ||
    ImportErrorCode.invalid ||
    ImportErrorCode.empty => l10n.backupErrorUnsupported,
    ImportErrorCode.tooLarge => l10n.backupErrorTooLarge,
    ImportErrorCode.newerVersion => l10n.backupErrorNewerVersion,
    ImportErrorCode.mixed => l10n.backupErrorMixed,
    ImportErrorCode.duplicate => l10n.backupErrorDuplicate,
    ImportErrorCode.importFailed when safetyBackupPath != null => l10n
        .backupErrorImportFailed(safetyBackupPath),
    _ => l10n.backupErrorGeneric,
  };
}
