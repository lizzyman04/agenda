// The repository import pipeline (plan 04-11): prepare writes nothing,
// commit writes a safety backup first and then replaces atomically. Real
// Isar; only IsarService is mocked. Safety files go to a temp directory.

import 'dart:convert';
import 'dart:io';

import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/backup/dao/backup_dao.dart';
import 'package:agenda/data/backup/import/safety_backup_store.dart';
import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/finance/category/transaction_category_model.dart';
import 'package:agenda/domain/backup/backup_entity.dart';
import 'package:agenda/domain/backup/import_preview.dart';
import 'package:agenda/infrastructure/backup/backup_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/backup_seed.dart';
import '../../support/isar_test_harness.dart';

class MockIsarService extends Mock implements IsarService {}

T ok<T>(Result<T> r) => switch (r) {
  Success(:final value) => value,
  Err(:final failure) => fail('expected success, got ${failure.message}'),
};

String errorCode(Result<Object?> r) => switch (r) {
  Err(:final failure) => importErrorCodeOf(failure) ?? failure.message,
  Success() => fail('expected a failure'),
};

void main() {
  late IsarTestHarness harness;
  late Isar isar;
  late BackupDao dao;
  late BackupRepositoryImpl repository;
  late Directory safetyDir;

  setUp(() async {
    harness = IsarTestHarness();
    isar = await harness.open(backupSchemas());
    final service = MockIsarService();
    when(() => service.db).thenReturn(isar);
    dao = BackupDao(service);
    repository = BackupRepositoryImpl(dao);
    safetyDir = Directory.systemTemp.createTempSync('agenda_import_test_');
    SafetyBackupStore.directoryResolver = () async => safetyDir;
  });

  tearDown(() async {
    await harness.close();
    safetyDir.deleteSync(recursive: true);
  });

  Future<Map<String, List<Map<String, Object?>>>> dbJson() async =>
      rowsJson(await dao.readAll());

  group('JSON round trip', () {
    test('prepare shows A and writes nothing; commit restores A', () async {
      final a = seedSnapshot(idBase: 0, tag: 'A');
      final b = seedSnapshot();
      await seedDatabase(isar, a);
      final file = ok(await repository.exportJson());
      await seedDatabase(isar, b);
      final bJson = await dbJson();

      final preview = ok(await repository.prepareImport([file]));

      expect(preview.source, ImportSource.json);
      expect(preview.counts[BackupEntity.tasks], 2);
      expect(preview.counts[BackupEntity.categories], 2);
      expect(preview.isPartial, isFalse);
      expect(await dbJson(), bJson, reason: 'prepare must not write');
      expect(repository.lastSafetyBackupPath, isNull);

      final result = ok(await repository.commitImport());

      expect(await dbJson(), snapshotJson(a));
      expect(result.counts[BackupEntity.tasks], 2);
      expect(repository.lastSafetyBackupPath, result.safetyBackupPath);
      final safety =
          jsonDecode(
                File(result.safetyBackupPath).readAsStringSync(),
              )
              as Map<String, Object?>;
      expect(
        safety['collections'],
        jsonDecode(jsonEncode(bJson)),
        reason: 'the safety file holds the data that was replaced',
      );
    });

    test('a corrupt file leaves the database untouched', () async {
      await seedDatabase(isar, seedSnapshot());
      final before = await dbJson();

      final result = await repository.prepareImport([
        fileOfText('{"app":"agenda", "formatVersion": 1'),
      ]);

      expect(errorCode(result), ImportErrorCode.unsupported);
      expect(await dbJson(), before);
      expect(errorCode(await repository.commitImport()), ImportErrorCode.empty);
    });

    test('a failed validation names the invalid code', () async {
      final bad = seedSnapshot();
      bad.items!.add(bad.items!.first);
      final result = await repository.prepareImport([jsonFileOf(bad)]);
      expect(errorCode(result), ImportErrorCode.invalid);
    });

    test('committing twice fails the second time', () async {
      final file = ok(await repository.exportJson());
      ok(await repository.prepareImport([file]));
      ok(await repository.commitImport());
      expect(errorCode(await repository.commitImport()), ImportErrorCode.empty);
    });

    test('discardImport forgets the prepared import', () async {
      ok(await repository.prepareImport([jsonFileOf(seedSnapshot())]));
      repository.discardImport();
      expect(errorCode(await repository.commitImport()), ImportErrorCode.empty);
    });

    test('dangling links import as-is with a warning count', () async {
      final s = seedSnapshot();
      s.transactions!.single.categoryId = 4242;
      final preview = ok(await repository.prepareImport([jsonFileOf(s)]));
      expect(preview.danglingLinks, 1);
      ok(await repository.commitImport());
      expect((await dao.readAll()).transactions.single.categoryId, 4242);
    });
  });

  group('CSV', () {
    test('known category names resolve to existing categories', () async {
      await seedDatabase(isar, seedSnapshot());
      const csv =
          'id,type,amount_cents,category_name,date\r\n'
          '1,expense,100,mercado b,2026-01-01\r\n'
          '2,expense,200, GROCERY B ,2026-01-02\r\n'
          '3,income,300,Salario B,2026-01-03\r\n';

      final preview = ok(await repository.prepareImport([fileOfText(csv)]));
      expect(preview.isPartial, isTrue);
      expect(preview.replaced, {BackupEntity.transactions});
      ok(await repository.commitImport());

      final rows = await dao.readAll();
      expect(rows.transactions.map((t) => t.categoryId), [101, 101, 102]);
      expect(rows.categories, hasLength(2), reason: 'no category created');
      expect(rows.items, hasLength(2), reason: 'tasks untouched');
    });

    test(
      'a brand-new category name creates exactly one custom category',
      () async {
        await seedDatabase(isar, seedSnapshot());
        const csv =
            'id,type,amount_cents,category_name,date\r\n'
            '1,expense,100,Pets,2026-01-01\r\n'
            '2,expense,200,pets,2026-01-02\r\n';

        ok(await repository.prepareImport([fileOfText(csv)]));
        ok(await repository.commitImport());

        final rows = await dao.readAll();
        final created = rows.categories.where((c) => c.id < 100 || c.id > 102);
        expect(created, hasLength(1));
        expect(created.single.namePtBr, 'Pets');
        expect(created.single.isDefault, isFalse);
        expect(created.single.nameEn, isNull);
        expect(
          rows.transactions.map((t) => t.categoryId).toSet(),
          {created.single.id},
        );
      },
    );

    test('a type-compatible match is required for name resolution', () async {
      await seedDatabase(isar, seedSnapshot());
      // 'Salario B' exists only as income, so an expense row creates its own.
      const csv =
          'id,type,amount_cents,category_name,date\r\n'
          '1,expense,100,Salario B,2026-01-01\r\n';
      ok(await repository.prepareImport([fileOfText(csv)]));
      ok(await repository.commitImport());
      final categories = (await dao.readAll()).categories;
      expect(categories.where((c) => c.namePtBr == 'Salario B'), hasLength(2));
    });

    test('a row with neither a known id nor a name is invalid', () async {
      const csv =
          'id,type,amount_cents,category_id,date\r\n'
          '1,expense,100,777,2026-01-01\r\n';
      final result = await repository.prepareImport([fileOfText(csv)]);
      expect(errorCode(result), ImportErrorCode.invalid);
    });

    test('a goals-only CSV leaves every other collection untouched', () async {
      await seedDatabase(isar, seedSnapshot(idBase: 0, tag: 'A'));
      final before = await dbJson();
      final goals = seedSnapshot(tag: 'G');
      final goalsFile = csvFilesOf(goals)[3];

      ok(await repository.prepareImport([goalsFile]));
      ok(await repository.commitImport());

      final after = await dbJson();
      expect(after['goals']!.single['title'], 'Goal G');
      for (final key in before.keys.where((k) => k != 'goals')) {
        expect(after[key], before[key], reason: key);
      }
    });

    test('blank and explicit task ids all survive (WR-01)', () async {
      const csv =
          'id,type,title\r\n'
          ',task,first\r\n'
          ',task,second\r\n'
          '2,task,explicit\r\n';

      final preview = ok(await repository.prepareImport([fileOfText(csv)]));
      final result = ok(await repository.commitImport());

      final stored = (await dao.readAll()).items;
      expect(preview.counts[BackupEntity.tasks], 3);
      expect(result.counts[BackupEntity.tasks], 3);
      expect(stored, hasLength(3));
      expect(stored.where((m) => m.title == 'explicit').single.id, 2);
    });

    test('a category deleted after prepare fails the commit cleanly', () async {
      await seedDatabase(isar, seedSnapshot());
      const csv =
          'id,type,amount_cents,category_id,date\r\n'
          '1,expense,100,101,2026-01-01\r\n';
      ok(await repository.prepareImport([fileOfText(csv)]));
      await isar.writeTxn(
        () => isar.transactionCategoryModels.delete(101),
      );
      final before = await dbJson();

      final result = await repository.commitImport();

      expect(errorCode(result), ImportErrorCode.importFailed);
      expect(await dbJson(), before);
      expect(repository.lastSafetyBackupPath, isNotNull);
      expect(File(repository.lastSafetyBackupPath!).existsSync(), isTrue);
    });
  });

  test(
    'a failed import never reports an earlier safety backup (WR-03)',
    () async {
      await seedDatabase(isar, seedSnapshot(idBase: 0, tag: 'A'));
      final file = jsonFileOf(seedSnapshot());
      ok(await repository.prepareImport([file]));
      ok(await repository.commitImport());
      expect(repository.lastSafetyBackupPath, isNotNull);

      final blocker = File('${safetyDir.path}/blocker')..writeAsStringSync('x');
      SafetyBackupStore.directoryResolver = () async => Directory(blocker.path);
      ok(await repository.prepareImport([file]));
      final result = await repository.commitImport();

      expect(errorCode(result), ImportErrorCode.importFailed);
      expect(repository.lastSafetyBackupPath, isNull);
    },
  );

  test(
    'a safety backup that cannot be written aborts before any change',
    () async {
      await seedDatabase(isar, seedSnapshot(idBase: 0, tag: 'A'));
      final file = jsonFileOf(seedSnapshot());
      // A regular file where the documents directory should be.
      final blocker = File('${safetyDir.path}/blocker')..writeAsStringSync('x');
      SafetyBackupStore.directoryResolver = () async => Directory(blocker.path);
      final before = await dbJson();

      ok(await repository.prepareImport([file]));
      final result = await repository.commitImport();

      expect(errorCode(result), ImportErrorCode.importFailed);
      expect(await dbJson(), before);
      expect(repository.lastSafetyBackupPath, isNull);
    },
  );
}
