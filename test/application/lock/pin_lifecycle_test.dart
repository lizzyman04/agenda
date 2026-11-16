// PinLifecycle write order (RESEARCH Pattern 10, T-05-38, T-05-39): real
// secure store and PBKDF2 hasher, mocked preferences and window channel, a
// real AppLockCubit.

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/setup/pin_lifecycle.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:agenda/domain/lock/pin_record.dart';
import 'package:agenda/infrastructure/lock/excursion_guard_impl.dart';
import 'package:agenda/infrastructure/lock/pbkdf2_pin_hasher.dart';
import 'package:agenda/infrastructure/lock/secure_pin_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/lock_fakes.dart';

class _MockPrefs extends Mock implements SharedPreferences {}

T _value<T>(Result<T> result) => switch (result) {
  Success(:final value) => value,
  Err(:final failure) => throw StateError(failure.message),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final hasher = Pbkdf2PinHasher();
  late SecurePinStore store;
  late _MockPrefs prefs;
  late MockSecureWindowGateway window;
  late AppLockCubit appLock;
  late PinLifecycle lifecycle;
  late List<String> events;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    store = SecurePinStore(const FlutterSecureStorage());
    events = [];
    prefs = _MockPrefs();
    when(() => prefs.getBool(any())).thenReturn(null);
    when(() => prefs.setBool(any(), any())).thenAnswer((inv) async {
      final record = _value(await store.readRecord());
      events.add('flag=${inv.positionalArguments[1]} record=${record != null}');
      return true;
    });
    when(() => prefs.remove(any())).thenAnswer((inv) async {
      events.add('remove ${inv.positionalArguments[0]}');
      return true;
    });
    window = MockSecureWindowGateway();
    when(
      () => window.setSecure(enabled: any(named: 'enabled')),
    ).thenAnswer((inv) async {
      final record = _value(await store.readRecord());
      events.add(
        'secure=${inv.namedArguments[#enabled]} record=${record != null}',
      );
      return true;
    });
    appLock = AppLockCubit(prefs, ExcursionGuardImpl());
    lifecycle = PinLifecycle(store, hasher, prefs, window, appLock);
  });

  tearDown(() => appLock.close());

  Future<PinRecord?> record() async => _value(await store.readRecord());

  test('enable: record and attempts, shield, then the flag LAST', () async {
    expect(await lifecycle.enable('1234'), isTrue);

    final stored = await record();
    expect(stored, isNotNull);
    expect(await hasher.verify('1234', stored!), isTrue);
    expect(_value(await store.readAttempts()), LockAttempts.none);
    expect(events, ['secure=true record=true', 'flag=true record=true']);
    verify(() => prefs.setBool(StorageKeys.pinConfigured, true)).called(1);
    expect(appLock.state.pinEnabled, isTrue);
    expect(appLock.state.locked, isFalse);
  });

  test('enable: a failed flag write rolls everything back', () async {
    when(() => prefs.setBool(any(), any())).thenAnswer((_) async => false);

    expect(await lifecycle.enable('1234'), isFalse);

    expect(await record(), isNull);
    verifyInOrder([
      () => window.setSecure(enabled: true),
      () => window.setSecure(enabled: false),
    ]);
    expect(appLock.state.pinEnabled, isFalse);
  });

  test('enable: a throwing flag write rolls everything back', () async {
    when(() => prefs.setBool(any(), any())).thenThrow(Exception('io'));

    expect(await lifecycle.enable('1234'), isFalse);

    expect(await record(), isNull);
    verify(() => window.setSecure(enabled: false)).called(1);
    expect(appLock.state.pinEnabled, isFalse);
  });

  test('disable: the flag FIRST, then shield, store and biometric', () async {
    await lifecycle.enable('1234');
    events.clear();

    expect(await lifecycle.disable(), isTrue);

    expect(events, [
      'flag=false record=true',
      'secure=false record=true',
      'remove ${StorageKeys.biometricUnlockEnabled}',
    ]);
    expect(await record(), isNull);
    expect(appLock.state.pinEnabled, isFalse);
  });

  test('disable: a failed flag write changes nothing', () async {
    await lifecycle.enable('1234');
    clearInteractions(window);
    when(() => prefs.setBool(any(), any())).thenAnswer((_) async => false);

    expect(await lifecycle.disable(), isFalse);

    expect(await record(), isNotNull);
    verifyNever(() => window.setSecure(enabled: any(named: 'enabled')));
    verifyNever(() => prefs.remove(any()));
    expect(appLock.state.pinEnabled, isTrue);
  });

  test('change replaces the record', () async {
    await lifecycle.enable('1234');

    expect(await lifecycle.change('5678'), isTrue);

    final stored = (await record())!;
    expect(await hasher.verify('5678', stored), isTrue);
    expect(await hasher.verify('1234', stored), isFalse);
  });

  test('reset saves the new PIN and clears a cooldown (D-07)', () async {
    await lifecycle.enable('1234');
    final cooling = LockAttempts(
      failures: 5,
      lockouts: 1,
      cooldownUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
    );
    _value(await store.writeAttempts(cooling));
    final lockedBefore = appLock.state.locked;

    expect(await lifecycle.reset('2468'), isTrue);

    expect(await hasher.verify('2468', (await record())!), isTrue);
    expect(_value(await store.readAttempts()), LockAttempts.none);
    expect(appLock.state.locked, lockedBefore);
  });
}
