// DATA-06 / D-08 on the lock screen: the biometric key (platform icon,
// tooltip, empty slot when not offered, enabled during a cooldown) and the
// auto-prompt (once after the first frame, only while resumed).

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/lock_screen_cubit.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/lock/device_auth_gateway.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/infrastructure/lock/excursion_guard_impl.dart';
import 'package:agenda/presentation/lock/keypad/keypad_key.dart';
import 'package:agenda/presentation/lock/keypad/lock_status_line.dart';
import 'package:agenda/presentation/lock/screens/lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/lock_fakes.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('pt', 'BR'));
  late MockPinVerifier verifier;
  late MockLockDeviceAuth deviceAuth;
  late AppLockCubit appLock;

  setUpAll(registerLockFallbacks);

  setUp(() async {
    SharedPreferences.setMockInitialValues({'pin_configured': true});
    appLock = AppLockCubit(
      await SharedPreferences.getInstance(),
      ExcursionGuardImpl(),
    );
    verifier = MockPinVerifier();
    when(
      () => verifier.loadAttempts(),
    ).thenAnswer((_) async => const Success(LockAttempts.none));
    when(() => verifier.resetAttempts()).thenAnswer((_) async {});
    deviceAuth = MockLockDeviceAuth();
    when(deviceAuth.biometricOffered).thenAnswer((_) async => true);
    when(
      () => deviceAuth.unlockWithBiometrics(any()),
    ).thenAnswer((_) async => DeviceAuthResult.cancelled);
    getIt.registerFactory<LockScreenCubit>(
      () => LockScreenCubit(verifier, appLock, deviceAuth),
    );
  });

  tearDown(() async {
    await appLock.close();
    await getIt.reset();
  });

  /// Pumps the app locked and lets `start()` and the post-frame callback
  /// run. The test binding starts with no lifecycle state, so the app is
  /// marked resumed first unless [resumed] is false.
  Future<void> pumpLock(WidgetTester tester, {bool resumed = true}) async {
    if (resumed) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }
    await tester.pumpWidget(lockTestApp(appLock: appLock));
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }
    expect(find.byType(LockScreen), findsOneWidget);
  }

  Finder biometricKey() => find.ancestor(
    of: find.byIcon(Icons.fingerprint),
    matching: find.byType(KeypadIconKey),
  );

  void expectPrompts(int n) {
    if (n == 0) {
      verifyNever(() => deviceAuth.unlockWithBiometrics(any()));
    } else {
      verify(() => deviceAuth.unlockWithBiometrics(any())).called(n);
    }
  }

  testWidgets('offered: fingerprint key with tooltip re-opens the prompt', (
    tester,
  ) async {
    await pumpLock(tester);
    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    expect(find.byTooltip(l10n.lockBiometricToggle), findsOneWidget);
    final key = tester.widget<KeypadIconKey>(biometricKey());
    expect(key.size, 32);
    expectPrompts(1); // the auto-prompt
    await tester.tap(find.byIcon(Icons.fingerprint));
    await tester.pump();
    final prompt =
        verify(
              () => deviceAuth.unlockWithBiometrics(captureAny()),
            ).captured.single
            as DeviceAuthPrompt;
    expect(prompt.reason, l10n.lockBiometricReason);
    expect(prompt.title, l10n.lockBiometricSheetTitle);
    expect(prompt.hint, l10n.lockBiometricSheetHint);
    expect(prompt.cancelLabel, l10n.lockUsePin);
  });

  testWidgets('not offered: no biometric icon and 0 stays centred', (
    tester,
  ) async {
    when(deviceAuth.biometricOffered).thenAnswer((_) async => false);
    await pumpLock(tester);
    expect(find.byIcon(Icons.fingerprint), findsNothing);
    expect(find.byIcon(Icons.face), findsNothing);
    expect(find.byTooltip(l10n.lockBiometricToggle), findsNothing);
    expect(
      tester.getCenter(find.text('0')).dx,
      moreOrLessEquals(tester.getCenter(find.text('8')).dx),
    );
    expectPrompts(0);
  });

  testWidgets(
    'iOS shows Icons.face',
    (tester) async {
      await pumpLock(tester);
      expect(find.byIcon(Icons.face), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('auto-prompt fires once after the first frame when resumed', (
    tester,
  ) async {
    await pumpLock(tester);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expectPrompts(1);
  });

  testWidgets('starting inactive: no prompt until resumed is delivered', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await pumpLock(tester, resumed: false);
    expectPrompts(0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expectPrompts(1);
    // Later resumes in the same episode do not prompt again.
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expectPrompts(0);
  });

  testWidgets('a cancelled prompt leaves the keypad enabled, no message', (
    tester,
  ) async {
    await pumpLock(tester);
    expectPrompts(1);
    expect(appLock.state.locked, isTrue);
    expect(
      tester.widget<LockStatusLine>(find.byType(LockStatusLine)).message,
      isNull,
    );
    final one = tester.widget<DigitKey>(
      find.ancestor(of: find.text('1'), matching: find.byType(DigitKey)),
    );
    expect(one.enabled, isTrue);
  });

  testWidgets('during a cooldown the biometric key is tappable and unlocks', (
    tester,
  ) async {
    when(() => verifier.loadAttempts()).thenAnswer(
      (_) async => Success(
        LockAttempts(
          failures: 5,
          lockouts: 1,
          cooldownUntil: DateTime.now().add(const Duration(minutes: 5)),
        ),
      ),
    );
    when(deviceAuth.biometricOffered).thenAnswer((_) async => true);
    await pumpLock(tester);
    expectPrompts(1);
    final one = tester.widget<DigitKey>(
      find.ancestor(of: find.text('1'), matching: find.byType(DigitKey)),
    );
    expect(one.enabled, isFalse);
    expect(tester.widget<KeypadIconKey>(biometricKey()).onTap, isNotNull);

    when(
      () => deviceAuth.unlockWithBiometrics(any()),
    ).thenAnswer((_) async => DeviceAuthResult.success);
    await tester.tap(find.byIcon(Icons.fingerprint));
    await tester.pump();
    expectPrompts(1);
    verify(() => verifier.resetAttempts()).called(1);
    expect(appLock.state.locked, isFalse);
    // Remove the lock screen so its countdown timer is cancelled.
    await tester.pumpWidget(const SizedBox());
  });
}
