import 'package:agenda/data/backup/import/backup_snapshot.dart';
import 'package:agenda/data/backup/import/snapshot_validator.dart';
import 'package:agenda/domain/backup/backup_entity.dart';
import 'package:agenda/domain/backup/import_preview.dart';

/// Summarises what committing [s] would do. Pure; nothing is written.
///
/// Counts are active rows for entities with a deletion mark and every row
/// for budgets and categories. Only supplied entities appear in the preview,
/// so a CSV preview is partial.
ImportPreview buildImportPreview(BackupSnapshot s, ValidationReport report) {
  final counts = <BackupEntity, int>{};
  final created = <DateTime>[];

  void add<T>(
    BackupEntity entity,
    List<T>? rows,
    DateTime? Function(T) deletedAt,
    DateTime Function(T) createdAt,
  ) {
    if (rows == null) return;
    counts[entity] = rows.where((r) => deletedAt(r) == null).length;
    created.addAll(rows.map(createdAt));
  }

  add(BackupEntity.tasks, s.items, (m) => m.deletedAt, (m) => m.createdAt);
  add(
    BackupEntity.transactions,
    s.transactions,
    (m) => m.deletedAt,
    (m) => m.createdAt,
  );
  add(BackupEntity.categories, s.categories, (_) => null, (m) => m.createdAt);
  add(BackupEntity.budgets, s.budgets, (_) => null, (m) => m.createdAt);
  add(BackupEntity.goals, s.goals, (m) => m.deletedAt, (m) => m.createdAt);
  add(BackupEntity.debts, s.debts, (m) => m.deletedAt, (m) => m.createdAt);
  add(
    BackupEntity.recurringPayments,
    s.recurringPayments,
    (m) => m.deletedAt,
    (m) => m.createdAt,
  );

  created.sort();
  return ImportPreview(
    source: s.source,
    counts: counts,
    softDeletedCount: report.softDeleted,
    earliest: created.isEmpty ? null : created.first,
    latest: created.isEmpty ? null : created.last,
    exportedAt: s.exportedAt,
    danglingLinks: report.danglingLinks,
    replaced: counts.keys.toSet(),
  );
}
