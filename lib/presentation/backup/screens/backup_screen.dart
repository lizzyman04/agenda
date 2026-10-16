import 'package:agenda/application/backup/backup_cubit.dart';
import 'package:agenda/application/backup/backup_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/backup/widgets/backup_action_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Backup page: export the data as JSON or CSV (DATA-02, DATA-03).
///
/// Self-contained route with its own cubit, so Phase 5 can mount it in
/// Settings unchanged. Plan 04-17 adds the import controls here.
class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BackupCubit>(),
      child: const _BackupView(),
    );
  }
}

class _BackupView extends StatelessWidget {
  const _BackupView();

  String? _message(AppLocalizations l10n, BackupState state) {
    return switch (state) {
      BackupExportDone(csv: false) => l10n.backupExportDone,
      BackupExportDone(:final fileCount) => l10n.backupExportCsvDone(fileCount),
      BackupExportCancelled() => l10n.backupExportCancelled,
      BackupFailed() => l10n.backupErrorGeneric,
      _ => null,
    };
  }

  void _onState(BuildContext context, BackupState state) {
    final message = _message(AppLocalizations.of(context), state);
    if (message == null) return;
    // Hide the current SnackBar first: ScaffoldMessenger queues them FIFO.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    context.read<BackupCubit>().acknowledge();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupScreenTitle)),
      body: BlocConsumer<BackupCubit, BackupState>(
        listener: _onState,
        builder: (context, state) {
          final cubit = context.read<BackupCubit>();
          final busy = state is BackupWorking;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.backupExportHeader, style: textTheme.titleMedium),
              const SizedBox(height: 8),
              BackupActionCard(
                icon: Icons.data_object,
                title: l10n.backupExportJson,
                description: l10n.backupExportJsonDesc,
                onPressed:
                    busy
                        ? null
                        : () => cubit.exportJson(
                          dialogTitle: l10n.backupExportSaveTitle,
                        ),
              ),
              BackupActionCard(
                icon: Icons.table_chart_outlined,
                title: l10n.backupExportCsv,
                description: l10n.backupExportCsvDesc,
                onPressed:
                    busy
                        ? null
                        : () => cubit.exportCsv(
                          languageCode:
                              Localizations.localeOf(context).languageCode,
                          dialogTitle: l10n.backupExportSaveTitle,
                        ),
              ),
              if (busy) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
                const SizedBox(height: 4),
                Text(l10n.backupWorking, style: textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              Text(l10n.backupPrivacyNote, style: textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(l10n.backupReinstallNote, style: textTheme.bodySmall),
            ],
          );
        },
      ),
    );
  }
}
