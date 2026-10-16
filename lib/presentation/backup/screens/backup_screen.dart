import 'dart:async';

import 'package:agenda/application/backup/backup_cubit.dart';
import 'package:agenda/application/backup/backup_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/backup/screens/import_confirm_screen.dart';
import 'package:agenda/presentation/backup/widgets/backup_action_card.dart';
import 'package:agenda/presentation/backup/widgets/backup_outcome_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Backup page: export as JSON or CSV, import a backup (DATA-02..04).
///
/// Self-contained route with its own cubit, so Phase 5 can mount it in
/// Settings unchanged. A prepared import opens [ImportConfirmScreen].
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

  void _onState(BuildContext context, BackupState state) {
    final cubit = context.read<BackupCubit>();
    if (state is BackupImportPreviewReady) {
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder:
                (_) => BlocProvider.value(
                  value: cubit,
                  child: ImportConfirmScreen(preview: state.preview),
                ),
          ),
        ),
      );
      return;
    }
    final message = backupOutcomeMessage(AppLocalizations.of(context), state);
    if (message == null) return;
    // Hide the current SnackBar first: ScaffoldMessenger queues them FIFO.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    cubit.acknowledge();
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
              const SizedBox(height: 16),
              Text(l10n.backupImportHeader, style: textTheme.titleMedium),
              const SizedBox(height: 8),
              BackupActionCard(
                icon: Icons.upload_file_outlined,
                title: l10n.backupImportAction,
                description: l10n.backupImportDesc,
                onPressed:
                    busy
                        ? null
                        : () => cubit.pickAndPrepareImport(
                          dialogTitle: l10n.backupImportAction,
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
