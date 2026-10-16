// Tracer coverage for the JSON export engine (plan 04-04): the items
// collection travels DAO -> codec -> envelope -> repository -> bytes against
// a REAL Isar instance, 600 rows, 100 of them soft-deleted. Only IsarService
// (a thin wrapper whose `db` getter the DAO calls) is mocked.

import 'dart:convert';

import 'package:agenda/core/config/app_config.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/backup/dao/backup_dao.dart';
import 'package:agenda/data/backup/json/backup_envelope.dart';
import 'package:agenda/data/backup/json/item_json_codec.dart';
import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:agenda/domain/backup/backup_file.dart';
import 'package:agenda/infrastructure/backup/backup_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/isar_test_harness.dart';

class MockIsarService extends Mock implements IsarService {}

ItemModel _item(int i) {
  final base = DateTime(2026).add(Duration(minutes: i));
  final item = ItemModel()
    ..id = i
    ..type = ItemType.values[i % ItemType.values.length]
    ..parentId = i.isEven ? null : i - 1
    ..title = 'Item $i'
    ..description = i % 3 == 0 ? 'Desc $i' : null
    ..priority = Priority.values[i % Priority.values.length]
    ..isUrgent = i.isEven
    ..isImportant = i % 3 == 0
    ..sizeCategory = SizeCategory.values[i % SizeCategory.values.length]
    ..isNextAction = i % 5 == 0
    ..gtdContext = i % 4 == 0 ? '@home' : null
    ..waitingFor = i % 7 == 0 ? 'Ana' : null
    ..isCompleted = i % 6 == 0
    ..completedAt = i % 6 == 0 ? base : null
    ..deletedAt = i <= 100 ? base : null
    ..dueDate = i.isEven ? base.add(const Duration(days: 1)) : null
    ..linkedGoalId = i % 11 == 0 ? i : null
    ..linkedDebtId = i % 13 == 0 ? i : null
    ..createdAt = base
    ..updatedAt = base.add(const Duration(seconds: 5));
  if (i.isEven) {
    item.timeInfo = TimeInfo(dueTimeMinutes: 540, recurrenceRule: 'FREQ=DAILY');
  }
  if (i % 3 == 0) {
    item.moneyInfo = MoneyInfo(amount: 12.5, currencyCode: 'MZN');
  }
  return item;
}

bool _same(DateTime? a, DateTime? b) =>
    a == null ? b == null : (b != null && a.isAtSameMomentAs(b));

void main() {
  late IsarTestHarness harness;
  late Isar isar;
  late BackupRepositoryImpl repository;

  setUp(() async {
    harness = IsarTestHarness();
    isar = await harness.open([ItemModelSchema]);
    final service = MockIsarService();
    when(() => service.db).thenReturn(isar);
    repository = BackupRepositoryImpl(BackupDao(service));
  });

  tearDown(() async {
    await harness.close();
  });

  test('exports all 600 items, soft-deleted included, field for field',
      () async {
    final seeded = [for (var i = 1; i <= 600; i++) _item(i)];
    await isar.writeTxn(() => isar.collection<ItemModel>().putAll(seeded));

    final result = await repository.exportJson(now: DateTime(2026, 10, 12));

    final file = (result as Success<BackupFile>).value;
    expect(file.name, 'agenda-backup-2026-10-12.json');
    final parsed = parseBackupEnvelope(jsonDecode(utf8.decode(file.bytes)));
    expect(parsed.formatVersion, backupFormatVersion);
    expect(parsed.formatVersion, 1);
    expect(parsed.schemaVersion, AppConfig.schemaVersion);

    final rows = parsed.rows(BackupJsonKeys.items);
    expect(rows.length, 600, reason: 'soft-deleted rows must be exported');

    final decoded = rows.map(itemFromJson).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (var i = 0; i < 600; i++) {
      final a = seeded[i];
      final b = decoded[i];
      expect(b.id, a.id);
      expect(b.type, a.type);
      expect(b.parentId, a.parentId);
      expect(b.title, a.title);
      expect(b.description, a.description);
      expect(b.priority, a.priority);
      expect(b.isUrgent, a.isUrgent);
      expect(b.isImportant, a.isImportant);
      expect(b.sizeCategory, a.sizeCategory);
      expect(b.isNextAction, a.isNextAction);
      expect(b.gtdContext, a.gtdContext);
      expect(b.waitingFor, a.waitingFor);
      expect(b.isCompleted, a.isCompleted);
      expect(_same(b.completedAt, a.completedAt), isTrue);
      expect(_same(b.deletedAt, a.deletedAt), isTrue);
      expect(_same(b.dueDate, a.dueDate), isTrue);
      expect(b.timeInfo?.dueTimeMinutes, a.timeInfo?.dueTimeMinutes);
      expect(b.timeInfo?.recurrenceRule, a.timeInfo?.recurrenceRule);
      expect(b.timeInfo == null, a.timeInfo == null);
      expect(b.moneyInfo?.amount, a.moneyInfo?.amount);
      expect(b.moneyInfo?.currencyCode, a.moneyInfo?.currencyCode);
      expect(b.moneyInfo == null, a.moneyInfo == null);
      expect(b.linkedGoalId, a.linkedGoalId);
      expect(b.linkedDebtId, a.linkedDebtId);
      expect(_same(b.createdAt, a.createdAt), isTrue);
      expect(_same(b.updatedAt, a.updatedAt), isTrue);
    }
    expect(decoded.where((m) => m.deletedAt != null).length, 100);
  });
}
