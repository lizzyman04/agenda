// Source-text and API contract for the Phase 5 platform setup (plan 05-01).
//
// The biometric prompt theme, the USE_BIOMETRIC permission and the Face ID
// usage string can only be exercised on a device, so this pins the text that
// makes them work (same approach as
// test/infrastructure/notifications/manifest_contract_test.dart). The
// "API smoke" group compiles against the real local_auth 3.0.1,
// local_auth_android 2.0.8, flutter_secure_storage 10.0.0 and crypto 3.0.7
// symbols so later plans code against confirmed names. It makes no platform
// channel calls.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

String _read(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path must exist');
  return file.readAsStringSync();
}

bool _isComment(String line) => line.trimLeft().startsWith('#');

void main() {
  group('platform contract', () {
    late List<String> pubspecLines;
    late List<String> activeLines;

    setUpAll(() {
      pubspecLines = _read('pubspec.yaml').split('\n');
      activeLines = pubspecLines.where((l) => !_isComment(l)).toList();
    });

    test('Phase 5 packages are exact, uncommented pins', () {
      for (final pin in [
        'crypto: 3.0.7',
        'flutter_secure_storage: 10.0.0',
        'local_auth: 3.0.1',
        'local_auth_android: 2.0.8',
      ]) {
        expect(activeLines, contains('  $pin'), reason: pin);
      }
    });

    test('flutter_screen_lock appears only on a commented line', () {
      final hits = pubspecLines.where((l) => l.contains('flutter_screen_lock'));
      expect(hits, isNotEmpty);
      expect(hits.every(_isComment), isTrue, reason: hits.join('\n'));
    });

    test(
      'no network or telemetry package is a direct dependency (T-05-01)',
      () {
        final forbidden = RegExp(
          r'^\s+(http|dio|firebase_[a-z_]*|sentry_flutter|connectivity_plus):',
        );
        final hits = activeLines.where(forbidden.hasMatch).toList();
        expect(hits, isEmpty);
      },
    );

    test('manifest declares USE_BIOMETRIC', () {
      final manifest = _read('android/app/src/main/AndroidManifest.xml');
      expect(
        manifest,
        contains(
          '<uses-permission android:name="android.permission.USE_BIOMETRIC"/>',
        ),
      );
    });

    test('LaunchTheme and NormalTheme inherit AppCompat, light and night '
        '(T-05-02)', () {
      const expected = {
        'android/app/src/main/res/values/styles.xml':
            'Theme.AppCompat.Light.NoActionBar',
        'android/app/src/main/res/values-night/styles.xml':
            'Theme.AppCompat.NoActionBar',
      };
      for (final MapEntry(key: path, value: parent) in expected.entries) {
        final xml = _read(path);
        expect(
          RegExp(r'Theme\.AppCompat').allMatches(xml).length,
          2,
          reason: path,
        );
        for (final style in ['LaunchTheme', 'NormalTheme']) {
          expect(
            xml,
            contains('<style name="$style" parent="$parent">'),
            reason: '$path / $style',
          );
        }
        expect(xml, contains('@drawable/launch_background'), reason: path);
        expect(xml, contains('?android:colorBackground'), reason: path);
      }
    });

    test('Info.plist carries NSFaceIDUsageDescription', () {
      final plist = _read('ios/Runner/Info.plist');
      expect(
        plist,
        contains(
          '<key>NSFaceIDUsageDescription</key>\n'
          '\t<string>AGENDA uses Face ID to unlock the app instead of the '
          'PIN.</string>',
        ),
      );
    });

    test('MainActivity is still a FlutterFragmentActivity', () {
      final kt = _read(
        'android/app/src/main/kotlin/com/omeu/space/agenda/MainActivity.kt',
      );
      expect(kt, contains('class MainActivity : FlutterFragmentActivity()'));
    });
  });

  group('API smoke', () {
    test('local_auth 3.0.1 surface', () {
      final auth = LocalAuthentication();
      expect(auth, isA<LocalAuthentication>());

      // authenticate() named parameters, referenced without invoking the
      // platform channel.
      expect(
        auth.authenticate,
        isA<
          Future<bool> Function({
            required String localizedReason,
            Iterable<AuthMessages> authMessages,
            bool biometricOnly,
            bool sensitiveTransaction,
            bool persistAcrossBackgrounding,
          })
        >(),
      );

      const codes = [
        LocalAuthExceptionCode.userCanceled,
        LocalAuthExceptionCode.noCredentialsSet,
        LocalAuthExceptionCode.noBiometricsEnrolled,
        LocalAuthExceptionCode.noBiometricHardware,
        LocalAuthExceptionCode.temporaryLockout,
        LocalAuthExceptionCode.biometricLockout,
      ];
      expect(codes.toSet(), hasLength(6));

      const error = LocalAuthException(
        code: LocalAuthExceptionCode.userCanceled,
      );
      expect(error.code, LocalAuthExceptionCode.userCanceled);
      expect(BiometricType.values, contains(BiometricType.strong));
    });

    test('local_auth_android 2.0.8 AndroidAuthMessages', () {
      const messages = AndroidAuthMessages(
        signInTitle: 't',
        signInHint: 'h',
        cancelButton: 'c',
      );
      expect(messages.signInTitle, 't');
      expect(messages.signInHint, 'h');
      expect(messages.cancelButton, 'c');
      expect(messages, isA<AuthMessages>());
    });

    test(
      'flutter_secure_storage 10.0.0 round-trip on the mock store',
      () async {
        FlutterSecureStorage.setMockInitialValues({});
        const storage = FlutterSecureStorage(
          // Explicit on purpose: later plans construct AndroidOptions() and
          // must know resetOnError defaults to true in 10.0.0 (Pitfall 5).
          // ignore: avoid_redundant_argument_values, use_named_constants
          aOptions: AndroidOptions(),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

        await storage.write(key: 'k', value: 'v');
        expect(await storage.read(key: 'k'), 'v');
        await storage.delete(key: 'k');
        expect(await storage.read(key: 'k'), isNull);
      },
    );

    test('crypto 3.0.7 Hmac(sha256)', () {
      final digest = Hmac(sha256, utf8.encode('k')).convert(utf8.encode('m'));
      expect(digest.bytes, hasLength(32));
      // RFC 2104 HMAC-SHA256(key "k", message "m"), checked with python hmac.
      expect(
        digest.toString(),
        'b60090e3052297aeb5a080889ce2fc4bca957e756faeb4df7d31800ca1e771ec',
      );
    });
  });
}
