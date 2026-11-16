import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/app_lock_state.dart';
import 'package:agenda/infrastructure/lock/excursion_guard_impl.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  group('AppLockCubit initial state (frame-1 seed)', () {
    test('pin_configured true -> PIN enabled and locked', () async {
      final cubit = AppLockCubit(
        await prefsWith({'pin_configured': true}),
        ExcursionGuardImpl(),
      );
      expect(
        cubit.state,
        const AppLockState(pinEnabled: true, locked: true),
      );
      await cubit.close();
    });

    test('pin_configured false -> not locked', () async {
      final cubit = AppLockCubit(
        await prefsWith({'pin_configured': false}),
        ExcursionGuardImpl(),
      );
      expect(
        cubit.state,
        const AppLockState(pinEnabled: false, locked: false),
      );
      await cubit.close();
    });

    test('pin_configured absent -> not locked', () async {
      final cubit = AppLockCubit(await prefsWith({}), ExcursionGuardImpl());
      expect(
        cubit.state,
        const AppLockState(pinEnabled: false, locked: false),
      );
      await cubit.close();
    });

    test('a non-bool stored value fails closed (locked)', () async {
      final cubit = AppLockCubit(
        await prefsWith({'pin_configured': 'yes'}),
        ExcursionGuardImpl(),
      );
      expect(cubit.state.locked, isTrue);
      await cubit.close();
    });
  });

  group('AppLockCubit transitions', () {
    late SharedPreferences locked;
    late SharedPreferences open;

    setUp(() async {
      locked = await prefsWith({'pin_configured': true});
    });

    blocTest<AppLockCubit, AppLockState>(
      'unlock clears locked and keeps the PIN enabled',
      build: () => AppLockCubit(locked, ExcursionGuardImpl()),
      act: (cubit) => cubit.unlock(),
      expect: () => [const AppLockState(pinEnabled: true, locked: false)],
    );

    blocTest<AppLockCubit, AppLockState>(
      'unlock while unlocked emits nothing',
      setUp: () async => open = await prefsWith({}),
      build: () => AppLockCubit(open, ExcursionGuardImpl()),
      act: (cubit) => cubit.unlock(),
      expect: () => <AppLockState>[],
    );

    blocTest<AppLockCubit, AppLockState>(
      'pinEnabledChanged(true) enables the PIN without locking',
      setUp: () async => open = await prefsWith({}),
      build: () => AppLockCubit(open, ExcursionGuardImpl()),
      act: (cubit) => cubit.pinEnabledChanged(enabled: true),
      expect: () => [const AppLockState(pinEnabled: true, locked: false)],
    );

    blocTest<AppLockCubit, AppLockState>(
      'pinEnabledChanged(false) disables the PIN and leaves it unlocked',
      build: () => AppLockCubit(locked, ExcursionGuardImpl()),
      act: (cubit) => cubit.pinEnabledChanged(enabled: false),
      expect: () => [const AppLockState(pinEnabled: false, locked: false)],
    );
  });
}
