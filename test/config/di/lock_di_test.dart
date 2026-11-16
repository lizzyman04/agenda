// DI graph for the app-lock services (phase 05). Later DI plans in this
// phase append their checks here.

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/lock_screen_cubit.dart';
import 'package:agenda/application/lock/pin_verifier.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/domain/lock/excursion_guard.dart';
import 'package:agenda/domain/lock/pin_hasher.dart';
import 'package:agenda/domain/lock/pin_store.dart';
import 'package:agenda/domain/lock/secure_window_gateway.dart';
import 'package:agenda/infrastructure/lock/excursion_guard_impl.dart';
import 'package:agenda/infrastructure/lock/pbkdf2_pin_hasher.dart';
import 'package:agenda/infrastructure/lock/secure_pin_store.dart';
import 'package:agenda/infrastructure/lock/secure_window_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    if (getIt.isRegistered<IsarService>()) {
      await getIt.reset();
    }
    await configureDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  void expectSingleton<T extends Object>(Matcher type) {
    final a = getIt<T>();
    expect(a, type);
    expect(identical(a, getIt<T>()), isTrue);
  }

  group('lock DI graph', () {
    test('PinHasher resolves as a single Pbkdf2PinHasher', () {
      expectSingleton<PinHasher>(isA<Pbkdf2PinHasher>());
    });

    test('PinStore resolves as a single SecurePinStore', () {
      expectSingleton<PinStore>(isA<SecurePinStore>());
    });

    test('PinVerifier resolves as a singleton', () {
      expectSingleton<PinVerifier>(isA<PinVerifier>());
    });

    test('FlutterSecureStorage resolves as a singleton', () {
      expectSingleton<FlutterSecureStorage>(isA<FlutterSecureStorage>());
    });

    test('ExcursionGuard resolves as a single ExcursionGuardImpl', () {
      expectSingleton<ExcursionGuard>(isA<ExcursionGuardImpl>());
    });

    test('SecureWindowGateway resolves as a single SecureWindowChannel', () {
      expectSingleton<SecureWindowGateway>(isA<SecureWindowChannel>());
    });

    test('AppLockCubit resolves to one app-wide instance', () {
      expectSingleton<AppLockCubit>(isA<AppLockCubit>());
    });

    test('LockScreenCubit resolves to a new instance each time', () async {
      final a = getIt<LockScreenCubit>();
      final b = getIt<LockScreenCubit>();
      expect(identical(a, b), isFalse);
      await a.close();
      await b.close();
    });
  });
}
