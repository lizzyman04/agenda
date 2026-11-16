// Keypad states and accessibility on the lock screen (UI-SPEC "PinKeypad").

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/lock_screen_cubit.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/lock/keypad/keypad_key.dart';
import 'package:agenda/presentation/lock/screens/lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/lock_fakes.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('pt', 'BR'));
  late MockPinVerifier verifier;
  late AppLockCubit appLock;

  setUpAll(registerLockFallbacks);

  setUp(() async {
    SharedPreferences.setMockInitialValues({'pin_configured': true});
    appLock = AppLockCubit(await SharedPreferences.getInstance());
    verifier = MockPinVerifier();
    when(
      () => verifier.loadAttempts(),
    ).thenAnswer((_) async => const Success(LockAttempts.none));
    getIt.registerFactory<LockScreenCubit>(
      () => LockScreenCubit(verifier, appLock),
    );
  });

  tearDown(() async {
    await appLock.close();
    await getIt.reset();
  });

  Future<void> pumpLock(WidgetTester tester) async {
    await tester.pumpWidget(lockTestApp(appLock: appLock));
    await tester.pump();
    expect(find.byType(LockScreen), findsOneWidget);
  }

  Finder filled() => find.byKey(const ValueKey('pin-dot-filled'));
  Finder empty() => find.byKey(const ValueKey('pin-dot-empty'));
  KeypadIconKey backspace(WidgetTester tester) =>
      tester.widget<KeypadIconKey>(find.byType(KeypadIconKey));

  testWidgets('0 digits: four outlined dots, backspace disabled', (
    tester,
  ) async {
    await pumpLock(tester);
    expect(empty(), findsNWidgets(4));
    expect(filled(), findsNothing);
    expect(backspace(tester).onTap, isNull);
    expect(backspace(tester).onLongPress, isNull);
  });

  testWidgets('partial entry, backspace and long-press clear', (
    tester,
  ) async {
    await pumpLock(tester);

    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.pump();
    expect(filled(), findsNWidgets(2));
    expect(empty(), findsNWidgets(2));
    expect(backspace(tester).onTap, isNotNull);

    await tester.tap(find.byType(KeypadIconKey));
    await tester.pump();
    expect(filled(), findsOneWidget);

    await tester.tap(find.text('3'));
    await tester.pump();
    expect(filled(), findsNWidgets(2));

    await tester.longPress(find.byType(KeypadIconKey));
    await tester.pump();
    expect(filled(), findsNothing);
    expect(empty(), findsNWidgets(4));
    verifyNever(() => verifier.verify(any(), any()));
  });

  testWidgets('backspace tooltip renders on long-press (lock Overlay)', (
    tester,
  ) async {
    await pumpLock(tester);
    await tester.longPress(find.byType(KeypadIconKey));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.lockDeleteDigit), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('digit keys are labelled buttons; dots expose the count', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpLock(tester);

    expect(
      tester.getSemantics(find.bySemanticsLabel('5')),
      isSemantics(label: '5', isButton: true, hasTapAction: true),
    );
    expect(find.bySemanticsLabel(l10n.lockDigitsEntered(0)), findsOneWidget);

    await tester.tap(find.text('5'));
    await tester.pump();
    expect(find.bySemanticsLabel(l10n.lockDigitsEntered(1)), findsOneWidget);
    // Icon-only key: its name comes from the tooltip.
    expect(
      tester.getSemantics(
        find.descendant(
          of: find.byType(KeypadIconKey),
          matching: find.byType(InkWell),
        ),
      ),
      isSemantics(
        tooltip: l10n.lockDeleteDigit,
        isButton: true,
        isEnabled: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('320x568 at 200% text scale scrolls without overflow', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpLock(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(KeypadIconKey).hitTestable(), findsOneWidget);
  });
}
