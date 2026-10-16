import 'package:agenda/application/backup/backup_state.dart';
import 'package:agenda/application/backup/post_import_hooks.dart';
import 'package:agenda/application/notifications/budget_alert_evaluator.dart';
import 'package:agenda/application/notifications/goal_alert_evaluator.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/backup/backup_file.dart';
import 'package:agenda/domain/backup/backup_file_gateway.dart';
import 'package:agenda/domain/backup/backup_repository.dart';
import 'package:agenda/domain/backup/import_preview.dart';
import 'package:agenda/domain/notifications/notification_reconciler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Owns the export and import flows of the Backup screen.
///
/// Exports: the repository builds the bytes, the gateway saves them (D-12).
/// Imports: the gateway picks, the repository prepares then commits after
/// confirmation, then `reseedAfterImport` and a reconcile run through
/// [runPostImportHooks]. File content is never logged. Factory: one per screen.
@injectable
class BackupCubit extends Cubit<BackupState> {
  BackupCubit(
    this._repository,
    this._gateway,
    this._budgetAlerts,
    this._goalAlerts,
    this._reconciler,
  ) : super(const BackupIdle());

  final BackupRepository _repository;
  final BackupFileGateway _gateway;
  final BudgetAlertEvaluator _budgetAlerts;
  final GoalAlertEvaluator _goalAlerts;
  final NotificationReconciler _reconciler;

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

  /// Exports the six CSV files, one save dialog each, in order.
  ///
  /// Cancelling any dialog stops the export and reports how many files were
  /// already saved; later files are not offered.
  Future<void> exportCsv({
    required String languageCode,
    required String dialogTitle,
  }) async {
    if (state is BackupWorking) return;
    emit(const BackupWorking());
    final exported = await _repository.exportCsv(languageCode: languageCode);
    if (exported is Err<List<BackupFile>>) {
      emit(BackupFailed(exported.failure));
      return;
    }
    await _saveAll(
      (exported as Success<List<BackupFile>>).value,
      dialogTitle: dialogTitle,
      csv: true,
    );
  }

  /// Lets the user pick a JSON backup or CSV files and validates them.
  ///
  /// Writes nothing: success emits [BackupImportPreviewReady] for the
  /// confirmation screen; a cancelled picker returns to idle.
  Future<void> pickAndPrepareImport({required String dialogTitle}) async {
    if (state is BackupWorking) return;
    emit(const BackupWorking());
    final picked = await _gateway.pickFiles(dialogTitle: dialogTitle);
    switch (picked) {
      case Err<List<BackupFile>?>(:final failure):
        emit(BackupFailed(failure));
      case Success<List<BackupFile>?>(value: null):
        emit(const BackupIdle());
      case Success<List<BackupFile>?>(:final value?):
        final prepared = await _repository.prepareImport(value);
        emit(switch (prepared) {
          Success<ImportPreview>(:final value) => BackupImportPreviewReady(
            value,
          ),
          Err<ImportPreview>(:final failure) => BackupFailed(failure),
        });
    }
  }

  /// Commits the prepared import (only from the preview state), then runs
  /// the isolated post-import hooks (reseed alerts, reconcile).
  Future<void> confirmImport() async {
    if (state is! BackupImportPreviewReady) return;
    emit(const BackupWorking());
    final committed = await _repository.commitImport();
    switch (committed) {
      case Err<ImportResult>(:final failure):
        emit(BackupImportFailed(failure, _repository.lastSafetyBackupPath));
      case Success<ImportResult>(:final value):
        await runPostImportHooks(
          budgetAlerts: _budgetAlerts,
          goalAlerts: _goalAlerts,
          reconciler: _reconciler,
        );
        emit(BackupImportDone(value));
    }
  }

  /// Drops the prepared import and returns to idle.
  void cancelImport() {
    _repository.discardImport();
    emit(const BackupIdle());
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
