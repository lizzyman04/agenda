// Safety backup management on the repository (plan 04-20, WR-04): count,
// newest copy and delete-all over generated-name files only. Real files in a
// temp directory; the IsarService is never touched.

import 'dart:io';
import 'dart:typed_data';

import 'package:agenda/core/failures/result.dart';
import 'package:agenda/data/backup/dao/backup_dao.dart';
import 'package:agenda/data/backup/import/safety_backup_store.dart';
import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/infrastructure/backup/backup_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIsarService extends Mock implements IsarService {}

Uint8List bytes(String s) => Uint8List.fromList(s.codeUnits);

T ok<T>(Result<T> r) => switch (r) {
  Success(:final value) => value,
  Err(:final failure) => fail('expected success, got ${failure.message}'),
};

bool get canDenyReads =>
    Platform.isLinux &&
    Process.runSync('id', ['-u']).stdout.toString().trim() != '0';

void main() {
  late Directory base;
  late BackupRepositoryImpl repository;
  late Future<Directory> Function() originalResolver;

  setUp(() {
    base = Directory.systemTemp.createTempSync('agenda_safety_repo_');
    originalResolver = SafetyBackupStore.directoryResolver;
    SafetyBackupStore.directoryResolver = () async => base;
    repository = BackupRepositoryImpl(BackupDao(MockIsarService()));
  });

  tearDown(() {
    SafetyBackupStore.directoryResolver = originalResolver;
    final backups = Directory('${base.path}/backups');
    if (backups.existsSync() && canDenyReads) {
      Process.runSync('chmod', ['755', backups.path]);
    }
    base.deleteSync(recursive: true);
  });

  Future<void> writeTwo() async {
    var minute = 0;
    final store = SafetyBackupStore(
      baseDirectory: base,
      clock: () => DateTime(2026, 10, 16, 9, minute++),
    );
    await store.write(bytes('older'));
    await store.write(bytes('newer'));
  }

  test('with no files: count 0 and no latest copy', () async {
    expect(ok(await repository.safetyBackupCount()), 0);
    expect(ok(await repository.latestSafetyBackup()), isNull);
    expect(ok(await repository.deleteSafetyBackups()), 0);
  });

  test('count and latest copy reflect the files on disk', () async {
    await writeTwo();

    expect(ok(await repository.safetyBackupCount()), 2);
    final latest = ok(await repository.latestSafetyBackup())!;
    expect(latest.name, 'safety-backup-20261016-090100.json');
    expect(latest.bytes, bytes('newer'));
    expect(latest.name, isNot(contains('/')));
  });

  test('deleteSafetyBackups removes generated files only', () async {
    await writeTwo();
    File('${base.path}/backups/notes.txt').writeAsStringSync('keep me');

    expect(ok(await repository.deleteSafetyBackups()), 2);
    expect(ok(await repository.safetyBackupCount()), 0);
    expect(File('${base.path}/backups/notes.txt').existsSync(), isTrue);
  });

  test(
    'a filesystem error becomes an Err carrying only the type',
    () async {
      await writeTwo();
      Process.runSync('chmod', ['000', '${base.path}/backups']);

      final results = <Result<Object?>>[
        await repository.safetyBackupCount(),
        await repository.latestSafetyBackup(),
        await repository.deleteSafetyBackups(),
      ];

      for (final result in results) {
        switch (result) {
          case Err(:final failure):
            expect(failure.message, matches(r'^\w+ failed: \w+$'));
            expect(failure.message, isNot(contains(base.path)));
          case Success():
            fail('expected a failure');
        }
      }
    },
    skip: canDenyReads ? false : 'needs a non-root POSIX user to deny reads',
  );
}
