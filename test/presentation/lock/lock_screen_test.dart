// Keypad states and accessibility on the lock screen (UI-SPEC "PinKeypad").

import 'dart:io';

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/lock_screen_cubit.dart';
import 'package:agenda/application/lock/lock_screen_state.dart';
import 'package:agenda/application/lock/pin_verifier.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/lock/lock_attempts.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/infrastructure/lock/excursion_guard_impl.dart';
import 'package:agenda/presentation/lock/keypad/keypad_key.dart';
import 'package:agenda/presentation/lock/keypad/lock_status_line.dart';
import 'package:agenda/presentation/lock/screens/lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    appLock = AppLockCubit(
      await SharedPreferences.getInstance(),
      ExcursionGuardImpl(),
    );
    verifier = MockPinVerifier();
    when(
      () => verifier.loadAttempts(),
    ).thenAnswer((_) async => const Success(LockAttempts.none));
    getIt.registerFactory<LockScreenCubit>(
      () => LockScreenCubit(verifier, appLock, pinOnlyDeviceAuth()),
    );
  });

  tearDown(() async {
    await appLock.close();
    await getIt.reset();
  });

  Future<void> pumpLock(
    WidgetTester tester, {
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(
      lockTestApp(appLock: appLock, disableAnimations: disableAnimations),
    );
    await tester.pump();
    expect(find.byType(LockScreen), findsOneWidget);
  }

  Finder filled() => find.byKey(const ValueKey('pin-dot-filled'));
  Finder empty() => find.byKey(const ValueKey('pin-dot-empty'));
  Finder errorDots() => find.byKey(const ValueKey('pin-dot-error'));
  KeypadIconKey backspace(WidgetTester tester) =>
      tester.widget<KeypadIconKey>(find.byType(KeypadIconKey));
  double shakeX(WidgetTester tester) =>
      tester
          .widget<Transform>(find.byKey(const ValueKey('pin-dots-shake')))
          .transform
          .getTranslation()
          .x;

  Future<void> enterWrongPin(WidgetTester tester) async {
    when(
      () => verifier.verify(any(), any()),
    ).thenAnswer((_) async => const PinRejected(4));
    for (final d in ['9', '8', '7', '6']) {
      await tester.tap(find.text(d));
    }
    // Let the verify future resolve and the rejection rebuild the screen.
    await tester.pump();
  }

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

  testWidgets('wrong PIN: remaining attempts in cs.error and a dot shake', (
    tester,
  ) async {
    await pumpLock(tester);
    await enterWrongPin(tester);

    expect(find.text(l10n.lockWrongPin(4)), findsOneWidget);
    expect(find.textContaining('Restam 4 tentativas'), findsOneWidget);
    final text = tester.widget<Text>(
      find.byKey(const ValueKey('lock-status-text')),
    );
    final theme = Theme.of(tester.element(find.byType(LockStatusLine)));
    expect(text.style?.color, theme.colorScheme.error);

    await tester.pump(const Duration(milliseconds: 100));
    expect(shakeX(tester), isNot(0));
    expect(errorDots(), findsNWidgets(4));

    await tester.pump(const Duration(milliseconds: 300));
    expect(shakeX(tester), 0);
    expect(errorDots(), findsNothing);
    expect(empty(), findsNWidgets(4));
    // The message stays until the next digit.
    expect(find.text(l10n.lockWrongPin(4)), findsOneWidget);
    await tester.tap(find.text('1'));
    await tester.pump();
    expect(find.text(l10n.lockWrongPin(4)), findsNothing);
  });

  testWidgets('reduced motion: no shake, error dots for 300 ms', (
    tester,
  ) async {
    await pumpLock(tester, disableAnimations: true);
    await enterWrongPin(tester);

    for (final ms in [0, 100, 100, 50]) {
      await tester.pump(Duration(milliseconds: ms));
      expect(shakeX(tester), 0);
      expect(errorDots(), findsNWidgets(4));
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(shakeX(tester), 0);
    expect(errorDots(), findsNothing);
  });

  testWidgets('cooldown: keys disabled, countdown in onSurfaceVariant', (
    tester,
  ) async {
    await pumpLock(tester);
    when(() => verifier.verify(any(), any())).thenAnswer(
      (_) async => PinCoolingDown(
        LockAttempts(
          failures: 5,
          lockouts: 1,
          cooldownUntil: DateTime.now().add(const Duration(seconds: 30)),
        ),
      ),
    );
    for (final d in ['9', '8', '7', '6']) {
      await tester.tap(find.text(d));
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final status = find.byKey(const ValueKey('lock-status-text'));
    final text = tester.widget<Text>(status);
    expect(text.data, startsWith('Muitas tentativas. Tente de novo em 0:'));
    final theme = Theme.of(tester.element(status));
    expect(text.style?.color, theme.colorScheme.onSurfaceVariant);

    expect(
      tester.widgetList<DigitKey>(find.byType(DigitKey)).map((k) => k.enabled),
      everyElement(isFalse),
    );
    await tester.tap(find.text('1'));
    await tester.pump();
    expect(filled(), findsNothing);
    expect(backspace(tester).onTap, isNull);
    verify(() => verifier.verify(any(), any())).called(1);

    // Dispose the screen so its cubit cancels the countdown ticker.
    await tester.pumpWidget(const SizedBox());
  });

  test('formatCooldown renders m:ss with seconds rounded up', () {
    expect(formatCooldown(const Duration(milliseconds: 29200)), '0:30');
    expect(formatCooldown(const Duration(seconds: 61)), '1:01');
    expect(formatCooldown(const Duration(seconds: 30)), '0:30');
    expect(formatCooldown(const Duration(minutes: 15)), '15:00');
    expect(formatCooldown(const Duration(microseconds: 1)), '0:01');
    expect(formatCooldown(Duration.zero), '0:00');
  });

  // Keep last: it loads Roboto for the rest of this file.
  testWidgets('longest PT-BR status fits 2 lines at 264 dp', (tester) async {
    // Real Android metrics: the FlutterTest font is a 1 em square per glyph.
    await tester.runAsync(() async {
      final bytes =
          File(
            'test/support/fonts/Roboto-Regular.ttf',
          ).readAsBytesSync();
      final loader = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
    });
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('pt', 'BR'),
        supportedLocales: [Locale('pt', 'BR'), Locale('en')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 264,
              child: LockStatusLine(message: WrongPinMessage(4)),
            ),
          ),
        ),
      ),
    );
    expect(find.text('PIN incorreto. Restam 4 tentativas.'), findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(const ValueKey('lock-status-text')),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.getSize(find.byType(LockStatusLine)).height, 40);
  });
}
