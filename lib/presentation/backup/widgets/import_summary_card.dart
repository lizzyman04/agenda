import 'package:agenda/domain/backup/backup_entity.dart';
import 'package:agenda/domain/backup/import_preview.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// What an import would replace: record counts per entity, the date range,
/// the export date, soft-deleted rows and warnings (D-11).
class ImportSummaryCard extends StatelessWidget {
  const ImportSummaryCard({required this.preview, super.key});

  final ImportPreview preview;

  static String _label(AppLocalizations l10n, BackupEntity entity) {
    return switch (entity) {
      BackupEntity.tasks => l10n.backupEntityTasks,
      BackupEntity.transactions => l10n.backupEntityTransactions,
      BackupEntity.categories => l10n.backupEntityCategories,
      BackupEntity.budgets => l10n.backupEntityBudgets,
      BackupEntity.goals => l10n.backupEntityGoals,
      BackupEntity.debts => l10n.backupEntityDebts,
      BackupEntity.recurringPayments => l10n.backupEntityPayments,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final format = DateFormat.yMd(Localizations.localeOf(context).toString());
    final earliest = preview.earliest;
    final latest = preview.latest;
    final exportedAt = preview.exportedAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entity in BackupEntity.values)
              if (preview.replaced.contains(entity))
                Text(
                  l10n.backupCountLine(
                    _label(l10n, entity),
                    preview.counts[entity] ?? 0,
                  ),
                  style: textTheme.bodyLarge,
                ),
            const SizedBox(height: 12),
            if (earliest != null && latest != null)
              Text(
                l10n.backupConfirmDateRange(
                  format.format(earliest),
                  format.format(latest),
                ),
              ),
            if (exportedAt != null)
              Text(l10n.backupConfirmExportedAt(format.format(exportedAt))),
            if (preview.softDeletedCount > 0)
              Text(l10n.backupConfirmDeletedIncluded(preview.softDeletedCount)),
            if (preview.danglingLinks > 0) ...[
              const SizedBox(height: 12),
              Text(
                l10n.backupConfirmWarningsTitle,
                style: textTheme.titleSmall,
              ),
              Text(l10n.backupWarnDanglingLinks(preview.danglingLinks)),
            ],
          ],
        ),
      ),
    );
  }
}
