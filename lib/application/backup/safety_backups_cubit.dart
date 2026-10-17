import 'package:agenda/application/backup/safety_backups_state.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/backup/backup_file.dart';
import 'package:agenda/domain/backup/backup_file_gateway.dart';
import 'package:agenda/domain/backup/backup_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Drives the safety-backups section of the Backup screen (WR-04).
///
/// The safety backups are plaintext copies written before every import (D-12).
/// This cubit lets the user count them, save the newest to a place they
/// choose through the system save dialog (no share_plus), and delete them.
/// Restoring is the existing Import action on a saved copy. It never reads,
/// logs or displays a path or file content. Factory: one per screen.
@injectable
class SafetyBackupsCubit extends Cubit<SafetyBackupsState> {
  SafetyBackupsCubit(this._repository, this._gateway)
    : super(const SafetyBackupsState());

  final BackupRepository _repository;
  final BackupFileGateway _gateway;

  /// Reads how many safety backups exist. A repository error keeps the
  /// previous count and announces nothing.
  Future<void> load() async {
    final result = await _repository.safetyBackupCount();
    if (result is Success<int>) emit(state.copyWith(count: result.value));
  }

  /// Saves the newest safety backup where the user chooses.
  ///
  /// Outcomes: `none` (no backup yet), `saved`, `cancelled` (dialog dismissed)
  /// or `failed`. Ignored while another request is running.
  Future<void> saveLatestCopy({required String dialogTitle}) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true, clearOutcome: true));
    final latest = await _repository.latestSafetyBackup();
    if (latest is Err<BackupFile?>) {
      return _finish(SafetyBackupsOutcome.failed);
    }
    final file = (latest as Success<BackupFile?>).value;
    if (file == null) return _finish(SafetyBackupsOutcome.none);
    final saved = await _gateway.saveFile(dialogTitle: dialogTitle, file: file);
    _finish(switch (saved) {
      Success(value: true) => SafetyBackupsOutcome.saved,
      Success() => SafetyBackupsOutcome.cancelled,
      Err() => SafetyBackupsOutcome.failed,
    });
  }

  /// Deletes every safety backup. On success the count becomes 0 and the
  /// outcome is `deleted`; on error the outcome is `failed` and the count is
  /// read again. Ignored while another request is running.
  Future<void> deleteAll() async {
    if (state.busy) return;
    emit(state.copyWith(busy: true, clearOutcome: true));
    final result = await _repository.deleteSafetyBackups();
    if (result is Success<int>) {
      emit(const SafetyBackupsState(outcome: SafetyBackupsOutcome.deleted));
      return;
    }
    final count = await _repository.safetyBackupCount();
    emit(
      state.copyWith(
        busy: false,
        count: count is Success<int> ? count.value : null,
        outcome: SafetyBackupsOutcome.failed,
      ),
    );
  }

  /// Clears the announced outcome and nothing else.
  void acknowledge() => emit(state.copyWith(clearOutcome: true));

  void _finish(SafetyBackupsOutcome outcome) =>
      emit(state.copyWith(busy: false, outcome: outcome));
}
