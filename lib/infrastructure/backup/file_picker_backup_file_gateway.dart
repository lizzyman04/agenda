import 'dart:io';

import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/backup/import/snapshot_parser.dart';
import 'package:agenda/domain/backup/backup_file.dart';
import 'package:agenda/domain/backup/backup_file_gateway.dart';
import 'package:agenda/domain/backup/import_preview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

/// [BackupFileGateway] over `file_picker` 11.x.
///
/// The only class that touches the file picker. Picked file names are only
/// carried through as labels; every read uses the plugin's cache path. File
/// content and names are never logged, and a failure carries only the
/// exception TYPE (T-04-16-03). The plugin's cached copies of picked files
/// are cleared once the bytes have been read, on every outcome.
@LazySingleton(as: BackupFileGateway)
class FilePickerBackupFileGateway implements BackupFileGateway {
  @override
  AsyncResult<bool> saveFile({
    required String dialogTitle,
    required BackupFile file,
  }) async {
    try {
      // Bytes are always passed: on Android and iOS the plugin writes them
      // itself and returns the saved path; null means the user cancelled.
      final saved = await FilePicker.saveFile(
        dialogTitle: dialogTitle,
        fileName: file.name,
        bytes: file.bytes,
      );
      return Success(saved != null);
    } on Object catch (e) {
      return Err(BackupFailure('saveFailed: ${e.runtimeType}'));
    }
  }

  @override
  AsyncResult<List<BackupFile>?> pickFiles({
    required String dialogTitle,
  }) async {
    var picked = false;
    try {
      // Defaults are kept on purpose: type any (a backup may be .json or
      // .csv, whatever the file manager calls it) and withData false (file
      // content is read below, after the size check).
      final result = await FilePicker.pickFiles(
        dialogTitle: dialogTitle,
        allowMultiple: true,
      );
      if (result == null) return const Success(null);
      picked = true;

      final selection = result.files;
      // Check count and sizes before reading any bytes (T-04-16-02).
      final violation = importLimitViolation(selection.map((f) => f.size));
      if (violation != null) {
        return Err(BackupFailure('${ImportErrorCode.tooLarge}: $violation'));
      }
      final files = <BackupFile>[];
      for (final file in selection) {
        final path = file.path;
        if (path == null) return const Err(BackupFailure('readFailed: path'));
        files.add(
          BackupFile(name: file.name, bytes: await File(path).readAsBytes()),
        );
      }
      return Success(files);
    } on Object catch (e) {
      return Err(BackupFailure('pickFailed: ${e.runtimeType}'));
    } finally {
      if (picked) await _clearPickerCache();
    }
  }

  // The plugin copies every picked file into its cache as plaintext. Once the
  // bytes are in memory those copies are removed (T-04-19-03). Mobile only and
  // best effort: any error is ignored.
  Future<void> _clearPickerCache() async {
    try {
      await FilePicker.clearTemporaryFiles();
    } on Object {
      // Not available on this platform, or nothing to clear.
    }
  }
}
