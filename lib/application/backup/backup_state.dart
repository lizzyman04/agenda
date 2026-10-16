import 'package:agenda/core/failures/failure.dart';
import 'package:equatable/equatable.dart';

/// Base sealed class for the Backup screen states.
sealed class BackupState extends Equatable {
  const BackupState();
}

/// Nothing is running; the screen shows its actions.
final class BackupIdle extends BackupState {
  const BackupIdle();
  @override
  List<Object?> get props => [];
}

/// An export is running; actions are disabled.
final class BackupWorking extends BackupState {
  const BackupWorking();
  @override
  List<Object?> get props => [];
}

/// Every file of an export was written.
final class BackupExportDone extends BackupState {
  const BackupExportDone({required this.fileCount, required this.csv});

  /// Number of files saved.
  final int fileCount;

  /// True for the CSV export, false for the JSON backup.
  final bool csv;

  @override
  List<Object?> get props => [fileCount, csv];
}

/// The user cancelled a save dialog; [savedCount] files were already saved.
final class BackupExportCancelled extends BackupState {
  const BackupExportCancelled(this.savedCount);
  final int savedCount;
  @override
  List<Object?> get props => [savedCount];
}

/// A repository or file error. The screen shows a generic message.
final class BackupFailed extends BackupState {
  const BackupFailed(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
