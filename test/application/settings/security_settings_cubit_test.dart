// SecuritySettingsCubit (05-13): seeding from prefs and AppLockCubit,
// mirroring pinEnabled, persist-then-emit, and the prefs-failure backstop.

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/app_lock_state.dart';
import 'package:agenda/application/settings/security_settings_cubit.dart';
import 'package:agenda/application/settings/security_settings_state.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/domain/lock/device_auth_gateway.dart';
import 'package:agenda/infrastructure/lock/excursion_guard_impl.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/lock_fakes.dart';

class _ThrowingPrefs extends Mock implements SharedPreferences {}

void main() {
  late MockDeviceAuthGateway gateway;

  setUp(() {
    gateway = MockDeviceAuthGateway();
    when(
      gateway.biometricAvailability,
    ).thenAnswer((_) async => BiometricAvailability.enrolled);
    when(gateway.hasDeviceCredential).thenAnswer((_) async => true);
  });

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test(
    'defaults: PIN off, 1 min, biometrics on, availability unknown',
    () async {
      final prefs = await prefsWith({});
      final appLock = AppLockCubit(prefs, ExcursionGuardImpl());
      final cubit = SecuritySettingsCubit(prefs, appLock, gateway);

      expect(cubit.state, const SecuritySettingsState());
      expect(cubit.state.availability, isNull);
      await cubit.close();
      await appLock.close();
    },
  );

  test('seeds pinEnabled, timeout and biometrics from storage', () async {
    final prefs = await prefsWith({
      StorageKeys.pinConfigured: true,
      StorageKeys.lockTimeoutSeconds: 300,
      StorageKeys.biometricUnlockEnabled: false,
    });
    final appLock = AppLockCubit(prefs, ExcursionGuardImpl());
    final cubit = SecuritySettingsCubit(prefs, appLock, gateway);

    expect(
      cubit.state,
      const SecuritySettingsState(
        pinEnabled: true,
        biometricEnabled: false,
        timeoutSeconds: 300,
      ),
    );
    await cubit.close();
    await appLock.close();
  });

  test('an unknown stored timeout resolves to 60 s', () async {
    final prefs = await prefsWith({StorageKeys.lockTimeoutSeconds: 42});
    final appLock = AppLockCubit(prefs, ExcursionGuardImpl());
    final cubit = SecuritySettingsCubit(prefs, appLock, gateway);

    expect(cubit.state.timeoutSeconds, 60);
    await cubit.close();
    await appLock.close();
  });

  test('prefs that throw fall back to the defaults (backstop)', () async {
    final prefs = _ThrowingPrefs();
    when(() => prefs.getInt(any())).thenThrow(StateError('bad'));
    when(() => prefs.getBool(any())).thenThrow(StateError('bad'));
    final appLock = MockAppLockCubit();
    whenListen(
      appLock,
      const Stream<AppLockState>.empty(),
      initialState: const AppLockState(pinEnabled: false, locked: false),
    );
    final cubit = SecuritySettingsCubit(prefs, appLock, gateway);

    expect(cubit.state, const SecuritySettingsState());
    await cubit.close();
  });

  test(
    'start loads availability and mirrors a later pinEnabledChanged',
    () async {
      final prefs = await prefsWith({});
      final appLock = AppLockCubit(prefs, ExcursionGuardImpl());
      final cubit = SecuritySettingsCubit(prefs, appLock, gateway);

      await cubit.start();
      expect(cubit.state.availability, BiometricAvailability.enrolled);
      expect(cubit.state.pinEnabled, isFalse);

      appLock.pinEnabledChanged(enabled: true);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.pinEnabled, isTrue);

      appLock.pinEnabledChanged(enabled: false);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.pinEnabled, isFalse);

      await cubit.close();
      await appLock.close();
    },
  );

  test('a failing availability check counts as no hardware', () async {
    when(gateway.biometricAvailability).thenThrow(StateError('boom'));
    final prefs = await prefsWith({});
    final appLock = AppLockCubit(prefs, ExcursionGuardImpl());
    final cubit = SecuritySettingsCubit(prefs, appLock, gateway);

    await cubit.refreshAvailability();
    expect(cubit.state.availability, BiometricAvailability.noHardware);
    await cubit.close();
    await appLock.close();
  });

  test('the timeout is persisted before it is emitted', () async {
    final prefs = await prefsWith({});
    final appLock = AppLockCubit(prefs, ExcursionGuardImpl());
    final cubit = SecuritySettingsCubit(prefs, appLock, gateway);
    int? storedAtEmit;
    final sub = cubit.stream.listen(
      (_) => storedAtEmit = prefs.getInt(StorageKeys.lockTimeoutSeconds),
    );

    await cubit.setTimeoutSeconds(300);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.timeoutSeconds, 300);
    expect(storedAtEmit, 300);
    await sub.cancel();
    await cubit.close();
    await appLock.close();
  });

  test('an out-of-range timeout is ignored', () async {
    final prefs = await prefsWith({});
    final appLock = AppLockCubit(prefs, ExcursionGuardImpl());
    final cubit = SecuritySettingsCubit(prefs, appLock, gateway);

    await cubit.setTimeoutSeconds(45);

    expect(cubit.state.timeoutSeconds, 60);
    expect(prefs.getInt(StorageKeys.lockTimeoutSeconds), isNull);
    await cubit.close();
    await appLock.close();
  });

  test('the biometric preference is persisted, then emitted', () async {
    final prefs = await prefsWith({});
    final appLock = AppLockCubit(prefs, ExcursionGuardImpl());
    final cubit = SecuritySettingsCubit(prefs, appLock, gateway);

    await cubit.setBiometricEnabled(enabled: false);

    expect(prefs.getBool(StorageKeys.biometricUnlockEnabled), isFalse);
    expect(cubit.state.biometricEnabled, isFalse);
    await cubit.close();
    await appLock.close();
  });

  test('hasDeviceCredential delegates; a failure counts as none', () async {
    final prefs = await prefsWith({});
    final appLock = AppLockCubit(prefs, ExcursionGuardImpl());
    final cubit = SecuritySettingsCubit(prefs, appLock, gateway);

    expect(await cubit.hasDeviceCredential(), isTrue);
    when(gateway.hasDeviceCredential).thenThrow(StateError('boom'));
    expect(await cubit.hasDeviceCredential(), isFalse);
    await cubit.close();
    await appLock.close();
  });
}
