// SafetyBackupStore (plan 04-11): generated names, rotation, containment.

import 'dart:io';
import 'dart:typed_data';

import 'package:agenda/data/backup/import/safety_backup_store.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List bytes(String s) => Uint8List.fromList(s.codeUnits);

void main() {
  late Directory base;

  setUp(() {
    base = Directory.systemTemp.createTempSync('agenda_safety_test_');
  });

  tearDown(() {
    base.deleteSync(recursive: true);
  });

  List<String> names() =>
      Directory(
          '${base.path}/backups',
        ).listSync().map((e) => e.uri.pathSegments.last).toList()
        ..sort();

  test('writes the bytes under backups/ with a generated name', () async {
    final store = SafetyBackupStore(
      baseDirectory: base,
      clock: () => DateTime(2026, 10, 16, 9, 8, 7),
    );

    final path = await store.write(bytes('hello'));

    expect(File(path).readAsBytesSync(), bytes('hello'));
    expect(path, startsWith(base.absolute.path));
    expect(path, endsWith('safety-backup-20261016-090807.json'));
    expect(
      File(
        path,
      ).parent.uri.pathSegments[File(path).parent.uri.pathSegments.length - 2],
      'backups',
    );
  });

  test('a fifth write leaves exactly the newest three', () async {
    var minute = 0;
    final store = SafetyBackupStore(
      baseDirectory: base,
      clock: () => DateTime(2026, 10, 16, 9, minute++),
    );
    for (var i = 0; i < 5; i++) {
      await store.write(bytes('v$i'));
    }

    expect(names(), [
      'safety-backup-20261016-090200.json',
      'safety-backup-20261016-090300.json',
      'safety-backup-20261016-090400.json',
    ]);
  });

  test('a same-second collision gets a numeric suffix', () async {
    final store = SafetyBackupStore(
      baseDirectory: base,
      clock: () => DateTime(2026, 10, 16, 9),
    );
    final first = await store.write(bytes('1'));
    final second = await store.write(bytes('2'));
    final third = await store.write(bytes('3'));

    expect(first, endsWith('090000.json'));
    expect(second, endsWith('090000-1.json'));
    expect(third, endsWith('090000-2.json'));
    expect(File(second).readAsBytesSync(), bytes('2'));
  });

  test('rotation keeps the newest suffixed file, not the oldest', () async {
    final store = SafetyBackupStore(
      baseDirectory: base,
      clock: () => DateTime(2026, 10, 16, 9),
    );
    for (var i = 0; i < 4; i++) {
      await store.write(bytes('$i'));
    }

    expect(names(), [
      'safety-backup-20261016-090000-1.json',
      'safety-backup-20261016-090000-2.json',
      'safety-backup-20261016-090000-3.json',
    ]);
  });

  test(
    'a rotation deletion error never blocks the new backup (WR-05)',
    () async {
      var minute = 0;
      final store = SafetyBackupStore(
        baseDirectory: base,
        clock: () => DateTime(2026, 10, 16, 9, minute++),
        fileDeleter: (_) async => throw const FileSystemException('locked'),
      );
      late String last;
      for (var i = 0; i < 4; i++) {
        last = await store.write(bytes('v$i'));
      }

      expect(File(last).existsSync(), isTrue);
      expect(names(), hasLength(4), reason: 'surplus left in place');
    },
  );

  test('unrelated files in backups/ are never deleted', () async {
    Directory('${base.path}/backups').createSync(recursive: true);
    File('${base.path}/backups/notes.txt').writeAsStringSync('keep me');
    var minute = 0;
    final store = SafetyBackupStore(
      baseDirectory: base,
      clock: () => DateTime(2026, 10, 16, 9, minute++),
    );
    for (var i = 0; i < 5; i++) {
      await store.write(bytes('v'));
    }

    expect(names(), contains('notes.txt'));
    expect(names(), hasLength(4));
  });
}
