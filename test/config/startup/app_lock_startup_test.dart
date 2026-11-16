import 'package:agenda/config/di/injection.dart';
import 'package:agenda/config/startup/app_lock_startup.dart';
import 'package:agenda/core/constants/secure_storage_keys.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/domain/lock/secure_window_gateway.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/lock_fakes.dart';

class _ThrowingStorage extends Mock implements FlutterSecureStorage {}

class _FaultyPrefs extends Mock implements SharedPreferences {}

const Map<String, String> _stale = {
  SecureStorageKeys.pinRecord: 'v1:10000:old:old',
  SecureStorageKeys.pinAttempts: '5:1:0',
};

void main() {
  Future<void> boot({
    Map<String, Object> prefs = const {},
    Map<String, String> secure = _stale,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    FlutterSecureStorage.setMockInitialValues(Map.of(secure));
    if (getIt.isRegistered<IsarService>()) await getIt.reset();
    await configureDependencies();
  }

  Future<Map<String, String>> secureEntries() =>
      getIt<FlutterSecureStorage>().readAll();

  bool? marker() =>
      getIt<SharedPreferences>().getBool(StorageKeys.secureStorageInitialized);

  tearDown(() async => getIt.reset());

  test(
    'fresh install wipes stale secure entries and sets the marker',
    () async {
      await boot();
      await startAppLock();
      expect(await secureEntries(), isEmpty);
      expect(marker(), isTrue);
    },
  );

  test('marker already set leaves existing entries untouched', () async {
    await boot(prefs: {StorageKeys.secureStorageInitialized: true});
    await startAppLock();
    expect(await secureEntries(), _stale);
  });

  test('marker absent but PIN configured: no wipe, marker set', () async {
    await boot(prefs: {StorageKeys.pinConfigured: true});
    await startAppLock();
    expect(await secureEntries(), _stale);
    expect(marker(), isTrue);
  });

  test('calling twice is idempotent', () async {
    await boot();
    await startAppLock();
    await getIt<FlutterSecureStorage>().write(
      key: SecureStorageKeys.pinRecord,
      value: 'new',
    );
    await startAppLock();
    expect(await secureEntries(), {SecureStorageKeys.pinRecord: 'new'});
    expect(marker(), isTrue);
  });

  test('a storage fault never throws and leaves the marker unset', () async {
    await boot();
    final storage = _ThrowingStorage();
    when(storage.deleteAll).thenThrow(Exception('keystore'));
    getIt
      ..unregister<FlutterSecureStorage>()
      ..registerSingleton<FlutterSecureStorage>(storage);

    await expectLater(startAppLock(), completes);
    expect(marker(), isNull);
  });

  group('native window shield (D-04)', () {
    late MockSecureWindowGateway shield;

    Future<void> bootWithShield(Map<String, Object> prefs) async {
      await boot(prefs: prefs);
      shield = MockSecureWindowGateway();
      when(
        () => shield.setSecure(enabled: any(named: 'enabled')),
      ).thenAnswer((_) async => true);
      getIt
        ..unregister<SecureWindowGateway>()
        ..registerSingleton<SecureWindowGateway>(shield);
    }

    test('a configured PIN turns the shield on once', () async {
      await bootWithShield({StorageKeys.pinConfigured: true});
      await startAppLock();
      verify(() => shield.setSecure(enabled: true)).called(1);
      verifyNoMoreInteractions(shield);
    });

    test('a configured PIN turns it on on every later start too', () async {
      await bootWithShield({
        StorageKeys.pinConfigured: true,
        StorageKeys.secureStorageInitialized: true,
      });
      await startAppLock();
      verify(() => shield.setSecure(enabled: true)).called(1);
    });

    test('no PIN configured never touches the shield', () async {
      await bootWithShield({StorageKeys.secureStorageInitialized: true});
      await startAppLock();
      verifyZeroInteractions(shield);
    });

    test('fresh install without a PIN never touches the shield', () async {
      await bootWithShield({});
      await startAppLock();
      verifyZeroInteractions(shield);
      expect(marker(), isTrue);
    });

    test('a throwing gateway does not make startAppLock throw', () async {
      await bootWithShield({StorageKeys.pinConfigured: true});
      when(
        () => shield.setSecure(enabled: any(named: 'enabled')),
      ).thenThrow(Exception('channel'));
      await expectLater(startAppLock(), completes);
      expect(marker(), isTrue);
    });

    test('a marker-write fault still applies the shield', () async {
      await bootWithShield({StorageKeys.pinConfigured: true});
      final prefs = _FaultyPrefs();
      when(() => prefs.getBool(StorageKeys.pinConfigured)).thenReturn(true);
      when(
        () => prefs.getBool(StorageKeys.secureStorageInitialized),
      ).thenReturn(null);
      when(
        () => prefs.setBool(StorageKeys.secureStorageInitialized, true),
      ).thenThrow(Exception('disk'));
      getIt
        ..unregister<SharedPreferences>()
        ..registerSingleton<SharedPreferences>(prefs);
      await expectLater(startAppLock(), completes);
      verify(() => shield.setSecure(enabled: true)).called(1);
    });
  });

  test('never throws when nothing is registered', () async {
    await getIt.reset();
    await expectLater(startAppLock(), completes);
  });
}
