// Source-text contract for the iOS backup exclusion (plan 04-18, CR-01).
//
// On iOS the Documents directory is included in iCloud and iTunes backups by
// default. The Isar database and the plaintext safety backups live there, so
// AppDelegate marks it excluded at every launch. The exclusion can only be
// confirmed on a device, so this pins the text that makes it work. It is the
// iOS counterpart of test/infrastructure/notifications/manifest_contract_test
// for Android (D-13).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path must exist');
  return file.readAsStringSync();
}

void main() {
  const swiftPath = 'ios/Runner/AppDelegate.swift';
  const safetyStorePath = 'lib/data/backup/import/safety_backup_store.dart';
  const isarServicePath = 'lib/data/database/isar_service.dart';

  group('iOS backup exclusion (CR-01)', () {
    late String swift;
    setUpAll(() => swift = _read(swiftPath));

    test('marks the documents directory excluded from backup', () {
      expect(swift, contains('isExcludedFromBackup = true'));
      expect(swift, contains('setResourceValues'));
      expect(swift, contains('.documentDirectory'));
    });

    test('declares excludeUserDataFromBackup', () {
      expect(
        swift,
        contains(RegExp(r'func\s+excludeUserDataFromBackup\s*\(')),
      );
    });

    test('runs the exclusion on every launch before Dart starts', () {
      final match = RegExp(
        r'didFinishLaunchingWithOptions(.*?)return super\.application\(',
        dotAll: true,
      ).firstMatch(swift);
      expect(match, isNotNull, reason: 'launch method must be intact');
      expect(
        match!.group(1),
        contains('excludeUserDataFromBackup()'),
        reason: 'the call must sit inside didFinishLaunchingWithOptions, '
            'before `return super.application(`',
      );
    });

    test('the backups directory name matches SafetyBackupStore', () {
      expect(swift, contains('"backups"'));
      final store = _read(safetyStorePath);
      expect(store, contains(RegExp(r"}\$\{Platform\.pathSeparator\}backups'")));
    });

    test('both storage paths resolve through the documents directory', () {
      const docs = 'getApplicationDocumentsDirectory';
      expect(_read(isarServicePath), contains(docs));
      expect(_read(safetyStorePath), contains(docs));
    });

    test('no lib/ file uses a persistent root the exclusion does not cover',
        () {
      // Built from parts so this file is the only place that spells them.
      final forbidden = [
        'getApplicationSupport',
        'getLibrary',
        'getExternalStorage',
        'getDownloads',
      ].map((p) => '${p}Director').toList();
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final normalized = entity.path.replaceAll(r'\', '/');
        if (normalized.startsWith('lib/generated/')) continue;
        final text = entity.readAsStringSync();
        for (final name in forbidden) {
          if (text.contains(name)) offenders.add('$normalized uses $name*');
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'A new persistent storage root is not excluded from iCloud '
            'and iTunes backup. Extend excludeUserDataFromBackup in '
            'ios/Runner/AppDelegate.swift (and this test) before adding it.',
      );
    });
  });
}
