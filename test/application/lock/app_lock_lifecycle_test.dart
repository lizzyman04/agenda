// Resume-lock policy of AppLockCubit (D-01, D-02, D-04, RESEARCH Pattern 3):
// only a trip through `hidden` can lock, the timeout is read at each resume,
// and resume emits exactly one state.

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/app_lock_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_clock.dart';
import '../../support/lock_fakes.dart';

const _open = AppLockState(pinEnabled: true, locked: false);
const _covered = AppLockState(pinEnabled: true, locked: false, obscured: true);
const _locked = AppLockState(pinEnabled: true, locked: true);

void main() {
  late FakeClock clock;
  late SharedPreferences prefs;
  late MockExcursionGuard guard;

  setUpAll(registerLockFallbacks);

  Future<void> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    prefs = await SharedPreferences.getInstance();
  }

  setUp(() {
    clock = FakeClock();
    guard = MockExcursionGuard();
    when(() => guard.isActive(any())).thenReturn(false);
  });

  AppLockCubit build() => AppLockCubit(prefs, guard, clock: clock.call);

  /// A real background trip of [away]: inactive, hidden, paused, then back.
  void trip(AppLockCubit cubit, Duration away) {
    cubit
      ..onInactive()
      ..onHidden();
    clock.advance(away);
    cubit
      ..onInactive()
      ..onResumed();
  }

  group('resume after the background', () {
    blocTest<AppLockCubit, AppLockState>(
      'inactive -> resumed without hidden never locks, even with timeout 0',
      setUp:
          () => prefsWith({'pin_configured': true, 'lock_timeout_seconds': 0}),
      build: build,
      seed: () => _open,
      act: (cubit) {
        cubit.onInactive();
        clock.advance(const Duration(hours: 1));
        cubit.onResumed();
      },
      expect: () => [_covered, _open],
    );

    blocTest<AppLockCubit, AppLockState>(
      'hidden 59 s with timeout 60 -> stays unlocked',
      setUp:
          () => prefsWith({'pin_configured': true, 'lock_timeout_seconds': 60}),
      build: build,
      seed: () => _open,
      act: (cubit) => trip(cubit, const Duration(seconds: 59)),
      expect: () => [_covered, _open],
    );

    blocTest<AppLockCubit, AppLockState>(
      'hidden 60 s with timeout 60 -> locked in ONE emission on resume',
      setUp:
          () => prefsWith({'pin_configured': true, 'lock_timeout_seconds': 60}),
      build: build,
      seed: () => _open,
      act: (cubit) => trip(cubit, const Duration(seconds: 60)),
      expect: () => [_covered, _locked],
    );

    blocTest<AppLockCubit, AppLockState>(
      'no stored timeout defaults to 60 s',
      setUp: () => prefsWith({'pin_configured': true}),
      build: build,
      seed: () => _open,
      act: (cubit) {
        trip(cubit, const Duration(seconds: 59));
        trip(cubit, const Duration(seconds: 60));
      },
      expect: () => [_covered, _open, _covered, _locked],
    );

    blocTest<AppLockCubit, AppLockState>(
      'an unlisted stored timeout (45) behaves as 60',
      setUp:
          () => prefsWith({'pin_configured': true, 'lock_timeout_seconds': 45}),
      build: build,
      seed: () => _open,
      act: (cubit) {
        trip(cubit, const Duration(seconds: 50));
        trip(cubit, const Duration(seconds: 60));
      },
      expect: () => [_covered, _open, _covered, _locked],
    );

    blocTest<AppLockCubit, AppLockState>(
      'a non-int stored timeout (getInt throws) counts as unset',
      setUp:
          () =>
              prefsWith({'pin_configured': true, 'lock_timeout_seconds': 'x'}),
      build: build,
      seed: () => _open,
      act: (cubit) {
        trip(cubit, const Duration(seconds: 59));
        trip(cubit, const Duration(seconds: 60));
      },
      expect: () => [_covered, _open, _covered, _locked],
    );

    blocTest<AppLockCubit, AppLockState>(
      'clock moved back while hidden -> locked (fail closed)',
      setUp:
          () =>
              prefsWith({'pin_configured': true, 'lock_timeout_seconds': 900}),
      build: build,
      seed: () => _open,
      act: (cubit) => trip(cubit, const Duration(minutes: -5)),
      expect: () => [_covered, _locked],
    );

    blocTest<AppLockCubit, AppLockState>(
      'hidden -> paused -> hidden keeps the first hidden time',
      setUp:
          () => prefsWith({'pin_configured': true, 'lock_timeout_seconds': 60}),
      build: build,
      seed: () => _open,
      act: (cubit) {
        cubit
          ..onInactive()
          ..onHidden();
        clock.advance(const Duration(seconds: 40));
        cubit.onHidden();
        clock.advance(const Duration(seconds: 25));
        cubit
          ..onInactive()
          ..onResumed();
      },
      expect: () => [_covered, _locked],
    );

    blocTest<AppLockCubit, AppLockState>(
      'a timeout changed in Settings applies to the next trip',
      setUp:
          () =>
              prefsWith({'pin_configured': true, 'lock_timeout_seconds': 900}),
      build: build,
      seed: () => _open,
      act: (cubit) async {
        trip(cubit, const Duration(seconds: 61));
        await prefs.setInt('lock_timeout_seconds', 30);
        trip(cubit, const Duration(seconds: 31));
      },
      expect: () => [_covered, _open, _covered, _locked],
    );

    blocTest<AppLockCubit, AppLockState>(
      'already locked: resume only removes the overlay',
      setUp: () => prefsWith({'pin_configured': true}),
      build: build,
      act: (cubit) => trip(cubit, const Duration(seconds: 1)),
      expect:
          () => [
            _locked.copyWith(obscured: true),
            _locked,
          ],
    );
  });

  group('PIN disabled', () {
    blocTest<AppLockCubit, AppLockState>(
      'onInactive emits nothing and no trip ever locks',
      setUp: () => prefsWith({'lock_timeout_seconds': 0}),
      build: build,
      act: (cubit) => trip(cubit, const Duration(hours: 1)),
      expect: () => <AppLockState>[],
    );
  });
  group('app-initiated excursions (D-03)', () {
    void excursion({required bool active}) =>
        when(() => guard.isActive(any())).thenReturn(active);

    blocTest<AppLockCubit, AppLockState>(
      'hidden during an excursion, back after 4 min with timeout 0 -> open',
      setUp: () async {
        await prefsWith({'pin_configured': true, 'lock_timeout_seconds': 0});
        excursion(active: true);
      },
      build: build,
      seed: () => _open,
      act: (cubit) => trip(cubit, const Duration(minutes: 4)),
      expect: () => [_covered, _open],
    );

    blocTest<AppLockCubit, AppLockState>(
      'hidden during an excursion, back after 5 min -> locked (cap)',
      setUp: () async {
        await prefsWith({'pin_configured': true, 'lock_timeout_seconds': 0});
        excursion(active: true);
      },
      build: build,
      seed: () => _open,
      act: (cubit) => trip(cubit, const Duration(minutes: 5)),
      expect: () => [_covered, _locked],
    );

    blocTest<AppLockCubit, AppLockState>(
      'hidden while the guard is inactive with timeout 0 -> locked',
      setUp: () async {
        await prefsWith({'pin_configured': true, 'lock_timeout_seconds': 0});
        excursion(active: false);
      },
      build: build,
      seed: () => _open,
      act: (cubit) => trip(cubit, const Duration(seconds: 1)),
      expect: () => [_covered, _locked],
    );

    blocTest<AppLockCubit, AppLockState>(
      'the excursion flag does not leak into the next trip',
      setUp: () async {
        await prefsWith({'pin_configured': true, 'lock_timeout_seconds': 0});
        excursion(active: true);
      },
      build: build,
      seed: () => _open,
      act: (cubit) {
        trip(cubit, const Duration(minutes: 1));
        excursion(active: false);
        trip(cubit, const Duration(seconds: 1));
      },
      expect: () => [_covered, _open, _covered, _locked],
    );

    blocTest<AppLockCubit, AppLockState>(
      'the guard is sampled at hidden time with the injected clock',
      setUp: () => prefsWith({'pin_configured': true}),
      build: build,
      seed: () => _open,
      act: (cubit) => trip(cubit, const Duration(seconds: 1)),
      verify:
          (_) => verify(
            () => guard.isActive(DateTime.utc(2026, 1, 1, 12)),
          ).called(1),
    );
  });
}
