import 'package:agenda/application/backup/backup_cubit.dart';
import 'package:agenda/application/backup/backup_state.dart';
import 'package:agenda/domain/backup/import_preview.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/backup/widgets/import_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Review step before an import replaces data (SC-5, D-11).
///
/// Shows what will be replaced; confirming commits through the cubit and
/// cancelling (button or back) discards the prepared import. The screen closes
/// itself when the cubit reports a result, and the Backup screen shows it.
class ImportConfirmScreen extends StatelessWidget {
  const ImportConfirmScreen({required this.preview, super.key});

  final ImportPreview preview;

  static bool _isResult(BackupState state) =>
      state is BackupImportDone ||
      state is BackupImportFailed ||
      state is BackupFailed ||
      state is BackupIdle;

  /// Pops once: after the first pop the route is no longer current, so the
  /// Idle that follows an acknowledge cannot pop the Backup screen as well.
  void _close(BuildContext context, BackupState state) {
    if (!_isResult(state)) return;
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<BackupCubit>();
    return BlocConsumer<BackupCubit, BackupState>(
      listener: _close,
      builder: (context, state) {
        final working = state is BackupWorking;
        return PopScope(
          canPop: !working,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop && cubit.state is BackupImportPreviewReady) {
              cubit.cancelImport();
            }
          },
          child: Scaffold(
            appBar: AppBar(title: Text(l10n.backupConfirmTitle)),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.backupConfirmWarning),
                if (preview.isPartial) ...[
                  const SizedBox(height: 8),
                  Text(l10n.backupConfirmPartial),
                ],
                const SizedBox(height: 16),
                ImportSummaryCard(preview: preview),
                if (working) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 4),
                  Text(l10n.backupWorking),
                ],
              ],
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          working
                              ? null
                              : () => Navigator.of(context).maybePop(),
                      child: Text(l10n.cancelButton),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: working ? null : cubit.confirmImport,
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: Text(l10n.backupConfirmButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
