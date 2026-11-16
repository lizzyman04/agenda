import 'package:agenda/config/di/injection.dart';
import 'package:agenda/config/startup/app_lock_startup.dart';
import 'package:agenda/core/constants/secure_storage_keys.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/data/database/isar_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ThrowingStorage extends Mock implements FlutterSecureStorage {}

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

  test('never throws when nothing is registered', () async {
    await getIt.reset();
    await expectLater(startAppLock(), completes);
  });
}
