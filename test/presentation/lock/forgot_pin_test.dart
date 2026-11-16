// Forgot PIN (D-06, user decision 1, T-05-36): device credential -> reset
// mode on the lock Navigator -> unlock with pinChangedSnack; cancel stays on
// the keypad; no screen lock shows the unavailable dialog and stays locked.

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/lock_device_auth.dart';
import 'package:agenda/application/lock/lock_screen_cubit.dart';
import 'package:agenda/application/lock/pin_verifier.dart';
import 'package:agenda/application/lock/setup/pin_setup_cubit.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/lock/device_auth_gateway.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/infrastructure/lock/excursion_guard_impl.dart';
import 'package:agenda/presentation/lock/keypad/keypad_key.dart';
import 'package:agenda/presentation/lock/screens/lock_screen.dart';
import 'package:agenda/presentation/lock/screens/pin_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_clock.dart';
import '../../support/lock_fakes.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('pt', 'BR'));
  late MockPinVerifier verifier;
  late MockLockDeviceAuth deviceAuth;
  late MockPinLifecycle lifecycle;
  late AppLockCubit appLock;
  late FakeClock clock;

  setUpAll(registerLockFallbacks);

  setUp(() async {
    SharedPreferences.setMockInitialValues({'pin_configured': true});
    appLock = AppLockCubit(
      await SharedPreferences.getInstance(),
      ExcursionGuardImpl(),
    );
    clock = FakeClock();
    verifier = MockPinVerifier();
    when(
      () => verifier.loadAttempts(),
    ).thenAnswer((_) async => const Success(LockAttempts.none));
    deviceAuth = pinOnlyDeviceAuth();
    lifecycle = MockPinLifecycle();
    when(() => lifecycle.reset(any())).thenAnswer((_) async => true);
    getIt
      ..registerFactory<LockScreenCubit>(
        () => LockScreenCubit(verifier, appLock, deviceAuth, clock: clock.call),
      )
      ..registerFactory<PinSetupCubit>(
        () => PinSetupCubit(lifecycle, verifier, clock: clock.call),
      );
  });

  tearDown(() async {
    await appLock.close();
    await getIt.reset();
  });

  void confirmAnswers(DeviceAuthResult result) => when(
    () => deviceAuth.confirmForgotPin(any()),
  ).thenAnswer((_) async => result);

  Future<void> pumpLock(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1200, 2700)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(lockTestApp(appLock: appLock));
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }
    expect(find.byType(LockScreen), findsOneWidget);
  }

  Finder forgot() => find.widgetWithText(TextButton, l10n.lockForgotPin);

  Future<void> tapForgot(WidgetTester tester) async {
    await tester.ensureVisible(forgot());
    await tester.tap(forgot());
    await tester.pumpAndSettle();
  }

  Future<void> tapPin(WidgetTester tester, String pin) async {
    for (final d in pin.split('')) {
      await tester.tap(find.text(d).last);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('success: reset mode, new PIN unlocks with pinChangedSnack', (
    tester,
  ) async {
    confirmAnswers(DeviceAuthResult.success);
    await pumpLock(tester);

    await tapForgot(tester);

    verify(() => deviceAuth.confirmForgotPin(any())).called(1);
    final setup = tester.widget<PinSetupScreen>(find.byType(PinSetupScreen));
    expect(setup.mode.name, 'reset');
    expect(find.byType(AppBar), findsNothing);
    expect(find.text(l10n.lockForgotPin), findsNothing);
    expect(appLock.state.locked, isTrue);

    await tapPin(tester, '2468');
    await tapPin(tester, '2468');

    verify(() => lifecycle.reset('2468')).called(1);
    expect(appLock.state.locked, isFalse);
    expect(find.byType(LockScreen), findsNothing);
    expect(find.text(l10n.pinChangedSnack), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('cancelled: back on the keypad, no dialog', (tester) async {
    confirmAnswers(DeviceAuthResult.cancelled);
    await pumpLock(tester);

    await tapForgot(tester);

    expect(find.byType(PinSetupScreen), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(l10n.lockEnterPinTitle), findsOneWidget);
    expect(appLock.state.locked, isTrue);
  });

  testWidgets('no screen lock: unavailable dialog, the app stays locked', (
    tester,
  ) async {
    confirmAnswers(DeviceAuthResult.noDeviceCredential);
    await pumpLock(tester);

    await tapForgot(tester);

    expect(find.text(l10n.lockForgotUnavailableTitle), findsOneWidget);
    expect(find.text(l10n.lockForgotUnavailableBody), findsOneWidget);
    final buttons = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(buttons, findsOneWidget);
    expect(find.widgetWithText(TextButton, l10n.lockGotIt), findsOneWidget);

    await tester.tap(find.text(l10n.lockGotIt));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.byType(PinSetupScreen), findsNothing);
    expect(appLock.state.locked, isTrue);
  });

  testWidgets('the forgot button works during a cooldown', (tester) async {
    when(() => verifier.loadAttempts()).thenAnswer(
      (_) async => Success(
        LockAttempts(
          failures: 5,
          lockouts: 1,
          cooldownUntil: clock().add(const Duration(seconds: 30)),
        ),
      ),
    );
    confirmAnswers(DeviceAuthResult.cancelled);
    await pumpLock(tester);
    final digit = tester.widget<DigitKey>(find.byType(DigitKey).first);
    expect(digit.enabled, isFalse);

    await tester.ensureVisible(forgot());
    expect(tester.widget<TextButton>(forgot()).onPressed, isNotNull);
    await tester.tap(forgot());
    await tester.pump();

    verify(() => deviceAuth.confirmForgotPin(any())).called(1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('record missing: check failure, forgot shown, still locked', (
    tester,
  ) async {
    when(
      () => verifier.verify(any(), any()),
    ).thenAnswer((_) async => const PinCheckFailed());
    confirmAnswers(DeviceAuthResult.cancelled);
    await pumpLock(tester);

    await tapPin(tester, '1234');

    expect(find.text(l10n.lockErrorGeneric), findsOneWidget);
    expect(forgot(), findsOneWidget);
    expect(appLock.state.locked, isTrue);
  });

  group('LockDeviceAuth.confirmForgotPin', () {
    late MockDeviceAuthGateway gateway;
    late LockDeviceAuth auth;

    setUp(() async {
      gateway = MockDeviceAuthGateway();
      auth = LockDeviceAuth(gateway, await SharedPreferences.getInstance());
    });

    test('no screen lock: noDeviceCredential, no prompt', () async {
      when(gateway.hasDeviceCredential).thenAnswer((_) async => false);

      expect(
        await auth.confirmForgotPin(fakeAuthPrompt),
        DeviceAuthResult.noDeviceCredential,
      );
      verifyNever(
        () => gateway.authenticate(
          any(),
          biometricOnly: any(named: 'biometricOnly'),
        ),
      );
    });

    test('screen lock: the device credential prompt decides', () async {
      when(gateway.hasDeviceCredential).thenAnswer((_) async => true);
      when(
        () => gateway.authenticate(any(), biometricOnly: false),
      ).thenAnswer((_) async => DeviceAuthResult.success);

      expect(
        await auth.confirmForgotPin(fakeAuthPrompt),
        DeviceAuthResult.success,
      );
      verify(
        () => gateway.authenticate(fakeAuthPrompt, biometricOnly: false),
      ).called(1);
    });

    test('errors fail closed', () async {
      when(gateway.hasDeviceCredential).thenThrow(Exception('x'));
      expect(
        await auth.confirmForgotPin(fakeAuthPrompt),
        DeviceAuthResult.noDeviceCredential,
      );

      when(gateway.hasDeviceCredential).thenAnswer((_) async => true);
      when(
        () => gateway.authenticate(any(), biometricOnly: false),
      ).thenThrow(Exception('x'));
      expect(
        await auth.confirmForgotPin(fakeAuthPrompt),
        DeviceAuthResult.cancelled,
      );
    });
  });
}
