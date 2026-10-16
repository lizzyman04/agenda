// Source-text contract for the Phase 4 platform configuration (plan 04-05).
//
// Gradle merge, desugaring and the manifest can only be exercised on a
// device, so this pins the text that makes them work. Same read-the-real-file
// approach as test/data/finance/transaction_dao_ordering_test.dart.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path must exist');
  return file.readAsStringSync();
}

/// Returns the text of the `<receiver ...>` element whose android:name ends
/// with [name], from its opening tag to its closing tag.
String _receiverBlock(String manifest, String name) {
  final match = RegExp(
    '<receiver[^>]*$name[^>]*?(?:/>|>.*?</receiver>)',
    dotAll: true,
  ).firstMatch(manifest);
  expect(match, isNotNull, reason: 'receiver $name must be declared');
  return match!.group(0)!;
}

void main() {
  const manifestPath = 'android/app/src/main/AndroidManifest.xml';
  const domains = ['root', 'file', 'database', 'sharedpref', 'external'];

  group('AndroidManifest.xml', () {
    late String manifest;
    setUpAll(() => manifest = _read(manifestPath));

    test('declares the four notification permissions', () {
      for (final permission in [
        'POST_NOTIFICATIONS',
        'RECEIVE_BOOT_COMPLETED',
        'SCHEDULE_EXACT_ALARM',
        'VIBRATE',
      ]) {
        expect(
          manifest,
          contains('<uses-permission android:name="android.permission.'
              '$permission"'),
        );
      }
      expect(manifest, isNot(contains('USE_EXACT_ALARM')));
    });

    test('both plugin receivers are not exported (T-04-05-02)', () {
      for (final name in [
        'ScheduledNotificationReceiver',
        'ScheduledNotificationBootReceiver',
      ]) {
        final block = _receiverBlock(manifest, name);
        final opening = block.substring(0, block.indexOf('>') + 1);
        expect(opening, contains('android:exported="false"'), reason: name);
        expect(opening, contains('com.dexterous.flutterlocalnotifications.'));
      }
    });

    test('boot receiver listens for the four restore actions (NOTF-11)', () {
      final block = _receiverBlock(
        manifest,
        'ScheduledNotificationBootReceiver',
      );
      for (final action in [
        'android.intent.action.BOOT_COMPLETED',
        'android.intent.action.MY_PACKAGE_REPLACED',
        'android.intent.action.QUICKBOOT_POWERON',
        'com.htc.intent.action.QUICKBOOT_POWERON',
      ]) {
        expect(block, contains('<action android:name="$action"'));
      }
    });

    test('Auto Backup is disabled and rule files are referenced (D-13)', () {
      expect(manifest, contains('android:allowBackup="false"'));
      expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
      expect(
        manifest,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
    });

    test('activity and flutterEmbedding are untouched', () {
      expect(manifest, contains('android:launchMode="singleTop"'));
      expect(manifest, contains('android:name="flutterEmbedding"'));
    });
  });

  group('backup exclusion rules (T-04-05-01)', () {
    test('backup_rules.xml excludes every domain', () {
      final xml = _read('android/app/src/main/res/xml/backup_rules.xml');
      expect(xml, contains('<full-backup-content>'));
      for (final domain in domains) {
        expect(xml, contains('<exclude domain="$domain" path="."/>'));
      }
    });

    test('data_extraction_rules.xml excludes every domain in both sections',
        () {
      final xml = _read(
        'android/app/src/main/res/xml/data_extraction_rules.xml',
      );
      for (final section in ['cloud-backup', 'device-transfer']) {
        final match = RegExp(
          '<$section>(.*?)</$section>',
          dotAll: true,
        ).firstMatch(xml);
        expect(match, isNotNull, reason: '$section section');
        for (final domain in domains) {
          expect(
            match!.group(1),
            contains('<exclude domain="$domain" path="."/>'),
            reason: '$section / $domain',
          );
        }
      }
    });
  });

  group('Gradle and activity', () {
    test('core library desugaring is enabled at 2.1.4', () {
      final gradle = _read('android/app/build.gradle.kts');
      expect(gradle, contains('isCoreLibraryDesugaringEnabled = true'));
      expect(
        gradle,
        contains('coreLibraryDesugaring("com.android.tools:'
            'desugar_jdk_libs:2.1.4")'),
      );
      expect(gradle, contains('JavaVersion.VERSION_17'));
    });

    test('MainActivity is still a FlutterFragmentActivity', () {
      final kt = _read(
        'android/app/src/main/kotlin/com/omeu/space/agenda/MainActivity.kt',
      );
      expect(kt, contains('class MainActivity : FlutterFragmentActivity()'));
    });
  });

  group('iOS AppDelegate', () {
    test('sets the UNUserNotificationCenter delegate', () {
      final swift = _read('ios/Runner/AppDelegate.swift');
      expect(swift, contains('import UserNotifications'));
      expect(
        swift,
        contains('UNUserNotificationCenter.current().delegate = self as '
            'UNUserNotificationCenterDelegate'),
      );
      expect(swift, contains('FlutterImplicitEngineDelegate'));
    });
  });

  group('pubspec.yaml', () {
    late List<String> activeLines;
    setUpAll(() {
      activeLines = _read('pubspec.yaml')
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('#'))
          .toList();
    });

    test('Phase 4 packages are exact, uncommented pins', () {
      for (final pin in [
        'csv: 8.0.0',
        'file_picker: 11.0.2',
        'flutter_local_notifications: 21.0.0',
        'flutter_timezone: 5.0.2',
        'timezone: 0.11.0',
      ]) {
        expect(activeLines, contains('  $pin'));
      }
    });

    test('no forbidden network or telemetry package is a direct dependency',
        () {
      final forbidden = RegExp(
        r'^\s+(http|dio|firebase_[a-z_]*|sentry_flutter|connectivity_plus|'
        'share_plus|to_csv|json2csv_dart|flutter_native_timezone):',
      );
      final hits = activeLines.where(forbidden.hasMatch).toList();
      expect(hits, isEmpty);
    });
  });
}
