// assignMissingIds (plan 04-19, WR-01): pure, no Isar. Blank ids become
// max-explicit + 1, +2 ... in file order, per collection.

import 'package:agenda/data/backup/import/backup_snapshot.dart';
import 'package:agenda/data/backup/import/snapshot_id_assigner.dart';
import 'package:agenda/data/finance/goal/savings_goal_model.dart';
import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:agenda/domain/backup/import_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

ItemModel _item({int? id}) {
  final m = ItemModel()..title = 't';
  if (id != null) m.id = id;
  return m;
}

TransactionModel _tx({int? id}) {
  final m = TransactionModel()..amountCents = 1;
  if (id != null) m.id = id;
  return m;
}

SavingsGoalModel _goal({int? id}) {
  final m = SavingsGoalModel()..title = 'g';
  if (id != null) m.id = id;
  return m;
}

void main() {
  List<int> ids(List<Object>? rows) => [
    for (final r in rows!)
      switch (r) {
        ItemModel() => r.id,
        TransactionModel() => r.id,
        SavingsGoalModel() => r.id,
        _ => throw ArgumentError(r),
      },
  ];

  test('no explicit ids numbers rows 1..n in order', () {
    final s = BackupSnapshot(
      source: ImportSource.csv,
      items: [_item(), _item(), _item()],
    );
    assignMissingIds(s);
    expect(ids(s.items), [1, 2, 3]);
  });

  test('only explicit ids changes nothing', () {
    final s = BackupSnapshot(
      source: ImportSource.csv,
      items: [_item(id: 5), _item(id: 2)],
    );
    assignMissingIds(s);
    expect(ids(s.items), [5, 2]);
  });

  test('mixed gives blanks max+1, max+2 in file order', () {
    final s = BackupSnapshot(
      source: ImportSource.csv,
      items: [_item(), _item(id: 2), _item(), _item(id: 9), _item()],
    );
    assignMissingIds(s);
    expect(ids(s.items), [10, 2, 11, 9, 12]);
  });

  test('collections are independent and null ones are untouched', () {
    final s = BackupSnapshot(
      source: ImportSource.csv,
      items: [_item(id: 50), _item()],
      transactions: [_tx(), _tx()],
      goals: [_goal(id: 3), _goal()],
    );
    assignMissingIds(s);
    expect(ids(s.items), [50, 51]);
    expect(ids(s.transactions), [1, 2]);
    expect(ids(s.goals), [3, 4]);
    expect(s.categories, isNull);
    expect(s.debts, isNull);
  });

  test('a counter past 1 << 62 is rejected naming only the collection', () {
    final s = BackupSnapshot(
      source: ImportSource.csv,
      items: [_item(id: 1 << 62), _item()],
    );
    expect(
      () => assignMissingIds(s),
      throwsA(
        isA<BackupImportException>()
            .having((e) => e.code, 'code', ImportErrorCode.invalid)
            .having((e) => e.detail, 'detail', contains('items')),
      ),
    );
  });

  test('an Isar.autoIncrement default is treated as blank', () {
    final s = BackupSnapshot(source: ImportSource.csv, items: [_item()]);
    expect(s.items!.single.id, Isar.autoIncrement);
    assignMissingIds(s);
    expect(s.items!.single.id, 1);
  });
}
