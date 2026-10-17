import 'dart:async';

import 'package:agenda/application/backup/backup_cubit.dart';
import 'package:agenda/application/backup/backup_state.dart';
import 'package:agenda/application/backup/safety_backups_cubit.dart';
import 'package:agenda/application/backup/safety_backups_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/backup/widgets/delete_safety_backups_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Safety backups on the Backup screen (WR-04): how many exist, save the
/// newest to a place the user chooses, delete them all.
///
/// Owns its [SafetyBackupsCubit] and reads the surrounding [BackupCubit] only
/// to refresh the count after an import. No path or file name is ever shown.
class SafetyBackupsSection extends StatelessWidget {
  const SafetyBackupsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SafetyBackupsCubit>(
      create: (_) {
        final cubit = getIt<SafetyBackupsCubit>();
        unawaited(cubit.load());
        return cubit;
      },
      child: const _SafetyBackupsView(),
    );
  }
}

class _SafetyBackupsView extends StatelessWidget {
  const _SafetyBackupsView();

  void _announce(BuildContext context, SafetyBackupsState state) {
    final outcome = state.outcome;
    if (outcome == null) return;
    final cubit = context.read<SafetyBackupsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final message = switch (outcome) {
      SafetyBackupsOutcome.saved => l10n.backupSafetySaved,
      SafetyBackupsOutcome.none => l10n.backupSafetyNone,
      SafetyBackupsOutcome.deleted => l10n.backupSafetyDeleted,
      SafetyBackupsOutcome.failed => l10n.backupSafetyFailed,
      SafetyBackupsOutcome.cancelled => null,
    };
    if (message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
    cubit.acknowledge();
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<SafetyBackupsCubit>();
    if (await confirmDeleteSafetyBackups(context)) await cubit.deleteAll();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final error = Theme.of(context).colorScheme.error;
    return MultiBlocListener(
      listeners: [
        BlocListener<BackupCubit, BackupState>(
          listenWhen:
              (_, s) => s is BackupImportDone || s is BackupImportFailed,
          listener:
              (context, _) => unawaited(
                context.read<SafetyBackupsCubit>().load(),
              ),
        ),
        BlocListener<SafetyBackupsCubit, SafetyBackupsState>(
          listenWhen: (_, s) => s.outcome != null,
          listener: _announce,
        ),
      ],
      child: BlocBuilder<SafetyBackupsCubit, SafetyBackupsState>(
        builder: (context, state) {
          final cubit = context.read<SafetyBackupsCubit>();
          final idle = !state.busy && state.count > 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(l10n.backupSafetyHeader, style: textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(l10n.backupSafetyDesc, style: textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(l10n.backupSafetyCount(state.count)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('safetySave'),
                    onPressed:
                        idle
                            ? () => cubit.saveLatestCopy(
                              dialogTitle: l10n.backupExportSaveTitle,
                            )
                            : null,
                    icon: const Icon(Icons.save_alt),
                    label: Text(l10n.backupSafetySaveButton),
                  ),
                  TextButton.icon(
                    key: const Key('safetyDelete'),
                    onPressed: idle ? () => _delete(context) : null,
                    style: TextButton.styleFrom(foregroundColor: error),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.backupSafetyDeleteButton),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
