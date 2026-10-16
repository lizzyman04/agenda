import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/backup/backup_file.dart';

/// Contract for moving backup files between the app and storage the user
/// chooses through the system file dialogs (D-12).
///
/// The implementation in `lib/infrastructure/backup/` is the only code that
/// touches the file picker. It never uses a picked file's name to build a
/// path, and it never throws: failures map to `BackupFailure`.
abstract interface class BackupFileGateway {
  /// Shows the system save dialog and writes [file] where the user chooses.
  ///
  /// Returns `Success(true)` when the file was written and `Success(false)`
  /// when the user cancelled the dialog.
  AsyncResult<bool> saveFile({
    required String dialogTitle,
    required BackupFile file,
  });

  /// Shows the system file picker (multi-select) and reads the chosen files.
  ///
  /// Returns `Success(null)` when the user cancelled. A file above the import
  /// size cap fails with a `BackupFailure` whose message starts with
  /// `tooLarge`, before any of its bytes are read.
  AsyncResult<List<BackupFile>?> pickFiles({required String dialogTitle});
}
