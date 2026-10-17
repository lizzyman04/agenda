import 'package:agenda/data/backup/import/backup_snapshot.dart';
import 'package:agenda/domain/backup/import_preview.dart';
import 'package:isar_community/isar.dart';

/// Highest id the assigner will hand out. Isar ids are 64-bit; this keeps a
/// wide margin below the limit so later auto-increments cannot overflow.
const int _maxAssignedId = 1 << 62;

/// Gives every row whose id is blank ([Isar.autoIncrement]) a concrete id,
/// before the snapshot is written (WR-01).
///
/// Isar assigns auto ids at put time, so a blank row can take a value that a
/// LATER explicit row owns, and that later put then overwrites it without any
/// error: the import reports N rows and stores N-1. Numbering blanks above the
/// highest explicit id of their own collection, in file order, makes every id
/// distinct up front. Explicit ids are never changed; collections the snapshot
/// does not supply (null) are not touched.
///
/// Mutates the models in place: the commit consumes the snapshot.
void assignMissingIds(BackupSnapshot snapshot) {
  _assign(snapshot.items, 'items', (m) => m.id, (m, id) => m.id = id);
  _assign(
    snapshot.transactions,
    'transactions',
    (m) => m.id,
    (m, id) => m.id = id,
  );
  _assign(
    snapshot.categories,
    'categories',
    (m) => m.id,
    (m, id) => m.id = id,
  );
  _assign(snapshot.budgets, 'budgets', (m) => m.id, (m, id) => m.id = id);
  _assign(snapshot.goals, 'goals', (m) => m.id, (m, id) => m.id = id);
  _assign(snapshot.debts, 'debts', (m) => m.id, (m, id) => m.id = id);
  _assign(
    snapshot.recurringPayments,
    'recurringPayments',
    (m) => m.id,
    (m, id) => m.id = id,
  );
}

void _assign<T>(
  List<T>? rows,
  String collection,
  int Function(T) getId,
  void Function(T, int) setId,
) {
  if (rows == null) return;
  var counter = 0;
  for (final row in rows) {
    final id = getId(row);
    if (id != Isar.autoIncrement && id > counter) counter = id;
  }
  for (final row in rows) {
    if (getId(row) != Isar.autoIncrement) continue;
    counter++;
    if (counter > _maxAssignedId) {
      throw BackupImportException(
        ImportErrorCode.invalid,
        'ids exhausted in $collection',
      );
    }
    setId(row, counter);
  }
}
