// PinSetupScreen (UI-SPEC "PIN setup screen"): create flow through the
// keypad with the real lifecycle, cancel, and the next cold start locked.

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/pin_verifier.dart';
import 'package:agenda/application/lock/setup/pin_lifecycle.dart';
import 'package:agenda/application/lock/setup/pin_setup_cubit.dart';
import 'package:agenda/application/lock/setup/pin_setup_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/constants/secure_storage_keys.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/infrastructure/lock/excursion_guard_impl.dart';
import 'package:agenda/infrastructure/lock/pbkdf2_pin_hasher.dart';
import 'package:agenda/infrastructure/lock/secure_pin_store.dart';
import 'package:agenda/presentation/lock/screens/pin_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/lock_fakes.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('pt', 'BR'));
  const storage = FlutterSecureStorage();
  late SharedPreferences prefs;
  late AppLockCubit appLock;
  late MockSecureWindowGateway window;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    appLock = AppLockCubit(prefs, ExcursionGuardImpl());
    window = MockSecureWindowGateway();
    when(
      () => window.setSecure(enabled: any(named: 'enabled')),
    ).thenAnswer((_) async => true);
    final store = SecurePinStore(storage);
    final hasher = Pbkdf2PinHasher();
    final lifecycle = PinLifecycle(store, hasher, prefs, window, appLock);
    getIt.registerFactory<PinSetupCubit>(
      () => PinSetupCubit(lifecycle, PinVerifier(store, hasher)),
    );
  });

  tearDown(() async {
    await appLock.close();
    await getIt.reset();
  });

  /// Opens the screen in [mode] from a launcher; [results] collects what
  /// it pops.
  Future<List<bool?>> open(WidgetTester tester, PinSetupMode mode) async {
    final results = <bool?>[];
    await tester.pumpWidget(
      lockTestApp(
        appLock: appLock,
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    final popped = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => PinSetupScreen(mode: mode),
                      ),
                    );
                    results.add(popped);
                  },
                  child: const Text('OPEN'),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    expect(find.byType(PinSetupScreen), findsOneWidget);
    return results;
  }

  Future<void> tapPin(WidgetTester tester, String pin) async {
    for (final d in pin.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('create: PIN + confirmation pops true; next cold start locks', (
    tester,
  ) async {
    final results = await open(tester, PinSetupMode.create);
    expect(find.text(l10n.pinSetupTitle), findsOneWidget);
    expect(find.text(l10n.pinCreatePrompt), findsOneWidget);
    expect(find.text(l10n.lockForgotPin), findsNothing);
    expect(find.byIcon(Icons.fingerprint), findsNothing);

    await tapPin(tester, '1357');
    expect(find.text(l10n.pinConfirmPrompt), findsOneWidget);
    await tapPin(tester, '1357');
    await settleRealAsync(tester, () => results.isNotEmpty);
    await tester.pumpAndSettle();

    expect(results, [true]);
    expect(find.byType(PinSetupScreen), findsNothing);
    expect(prefs.getBool('pin_configured'), isTrue);
    expect(appLock.state.locked, isFalse);
    final coldStart = AppLockCubit(prefs, ExcursionGuardImpl());
    expect(coldStart.state.locked, isTrue);
    await coldStart.close();
  });

  testWidgets('a confirm mismatch shows pinMismatch and asks again', (
    tester,
  ) async {
    await open(tester, PinSetupMode.create);
    await tapPin(tester, '1357');
    await tapPin(tester, '1358');

    expect(find.text(l10n.pinMismatch), findsOneWidget);
    expect(find.text(l10n.pinCreatePrompt), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('close pops false and stores nothing', (tester) async {
    final results = await open(tester, PinSetupMode.create);
    await tapPin(tester, '1357');

    await tester.tap(find.byTooltip(l10n.cancelButton));
    await tester.pumpAndSettle();

    expect(results, [false]);
    expect(prefs.getBool('pin_configured'), isNull);
    final record = await tester.runAsync(
      () => storage.read(key: SecureStorageKeys.pinRecord),
    );
    expect(record, isNull);
  });

  testWidgets('system back pops false', (tester) async {
    final results = await open(tester, PinSetupMode.create);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(results, [false]);
    expect(prefs.getBool('pin_configured'), isNull);
  });

  testWidgets('verify mode: AppBar lockPinToggle, current PIN only', (
    tester,
  ) async {
    await open(tester, PinSetupMode.verify);

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(l10n.lockPinToggle),
      ),
      findsOneWidget,
    );
    expect(find.text(l10n.pinCurrentPrompt), findsOneWidget);
    expect(find.byTooltip(l10n.cancelButton), findsOneWidget);
  });

  testWidgets('change mode: AppBar lockChangePin', (tester) async {
    await open(tester, PinSetupMode.change);

    expect(find.text(l10n.lockChangePin), findsOneWidget);
    expect(find.text(l10n.pinCurrentPrompt), findsOneWidget);
  });

  group('reset mode', () {
    late AppLockCubit locked;

    setUp(() async {
      await prefs.setBool('pin_configured', true);
      locked = AppLockCubit(prefs, ExcursionGuardImpl());
    });

    tearDown(() => locked.close());

    /// A plain app (no LockGate) whose home pushes the reset screen, with
    /// a [locked] AppLockCubit above it.
    Future<void> openReset(WidgetTester tester) async {
      await tester.pumpWidget(
        BlocProvider<AppLockCubit>.value(
          value: locked,
          child: MaterialApp(
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Builder(
              builder:
                  (context) => Scaffold(
                    body: TextButton(
                      onPressed:
                          () => Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder:
                                  (_) => const PinSetupScreen(
                                    mode: PinSetupMode.reset,
                                  ),
                            ),
                          ),
                      child: const Text('OPEN'),
                    ),
                  ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
    }

    testWidgets('no AppBar, and back does not leave it', (tester) async {
      await openReset(tester);
      expect(locked.state.locked, isTrue);
      expect(find.byType(AppBar), findsNothing);
      expect(find.text(l10n.pinCreatePrompt), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(PinSetupScreen), findsOneWidget);
    });

    testWidgets('done unlocks and shows pinChangedSnack', (tester) async {
      await openReset(tester);

      await tapPin(tester, '8642');
      await tapPin(tester, '8642');
      await settleRealAsync(tester, () => !locked.state.locked);
      await tester.pump();

      expect(locked.state.locked, isFalse);
      expect(find.text(l10n.pinChangedSnack), findsOneWidget);
      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.behavior, SnackBarBehavior.floating);
      final record = await tester.runAsync(
        () => storage.read(key: SecureStorageKeys.pinRecord),
      );
      expect(record, isNotNull);
    });
  });
}
