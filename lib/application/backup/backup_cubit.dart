import 'package:agenda/application/backup/backup_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/backup/backup_file.dart';
import 'package:agenda/domain/backup/backup_file_gateway.dart';
import 'package:agenda/domain/backup/backup_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Owns the export flows of the Backup screen.
///
/// Exports go repository -> file gateway: the repository builds the bytes,
/// the gateway lets the user pick where each file lands (D-12). File content
/// is never logged.
///
/// Factory (not singleton) — a fresh instance per Backup screen.
@injectable
class BackupCubit extends Cubit<BackupState> {
  BackupCubit(this._repository, this._gateway) : super(const BackupIdle());

  final BackupRepository _repository;
  final BackupFileGateway _gateway;

  /// Exports the full JSON backup through one save dialog.
  Future<void> exportJson({required String dialogTitle}) async {
    if (state is BackupWorking) return;
    emit(const BackupWorking());
    final exported = await _repository.exportJson();
    if (exported is Err<BackupFile>) {
      emit(BackupFailed(exported.failure));
      return;
    }
    await _saveAll(
      [(exported as Success<BackupFile>).value],
      dialogTitle: dialogTitle,
      csv: false,
    );
  }

  /// Returns to idle after the screen has shown the outcome.
  void acknowledge() => emit(const BackupIdle());

  Future<void> _saveAll(
    List<BackupFile> files, {
    required String dialogTitle,
    required bool csv,
  }) async {
    var saved = 0;
    for (final file in files) {
      final result = await _gateway.saveFile(
        dialogTitle: dialogTitle,
        file: file,
      );
      switch (result) {
        case Err<bool>(:final failure):
          emit(BackupFailed(failure));
          return;
        case Success<bool>(value: false):
          emit(BackupExportCancelled(saved));
          return;
        case Success<bool>():
          saved++;
      }
    }
    emit(BackupExportDone(fileCount: saved, csv: csv));
  }
}
