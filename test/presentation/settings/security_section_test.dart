// SecuritySection (05-13, SC-3): the PIN switch turns the lock on through
// PIN setup (create) and off through the confirm dialog + verify, and only
// ever shows what AppLockCubit says.

import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/lock/setup/pin_setup_cubit.dart';
import 'package:agenda/application/lock/setup/pin_setup_state.dart';
import 'package:agenda/application/settings/security_settings_cubit.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/domain/lock/device_auth_gateway.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/infrastructure/lock/excursion_guard_impl.dart';
import 'package:agenda/presentation/lock/screens/pin_setup_screen.dart';
import 'package:agenda/presentation/settings/security/security_section.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/lock_fakes.dart';

class _MockPinSetupCubit extends MockCubit<PinSetupState>
    implements PinSetupCubit {}

void main() {
  final pt = lookupAppLocalizations(const Locale('pt', 'BR'));
  late SharedPreferences prefs;
  late AppLockCubit appLock;
  late MockDeviceAuthGateway gateway;
  late SecuritySettingsCubit cubit;
  late List<PinSetupMode> started;

  Future<void> setUpWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    prefs = await SharedPreferences.getInstance();
    appLock = AppLockCubit(prefs, ExcursionGuardImpl());
    cubit = SecuritySettingsCubit(prefs, appLock, gateway);
  }

  setUp(() {
    gateway = MockDeviceAuthGateway();
    when(
      gateway.biometricAvailability,
    ).thenAnswer((_) async => BiometricAvailability.enrolled);
    when(gateway.hasDeviceCredential).thenAnswer((_) async => true);
    started = [];
    getIt.registerFactory<PinSetupCubit>(() {
      final setup = _MockPinSetupCubit();
      whenListen(
        setup,
        const Stream<PinSetupState>.empty(),
        initialState: PinSetupState.initial(PinSetupMode.create),
      );
      when(() => setup.start(any())).thenAnswer((inv) {
        started.add(inv.positionalArguments.first as PinSetupMode);
      });
      return setup;
    });
  });

  setUpAll(() => registerFallbackValue(PinSetupMode.create));

  tearDown(() async {
    await cubit.close();
    await appLock.close();
    await getIt.reset();
  });

  Future<void> pump(
    WidgetTester tester, {
    Locale? locale,
    bool start = true,
    double textScale = 1,
  }) async {
    if (start) await cubit.start();
    await tester.pumpWidget(
      MaterialApp(
        locale: locale ?? const Locale('pt', 'BR'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
        home: Scaffold(
          body: BlocProvider<SecuritySettingsCubit>.value(
            value: cubit,
            child: ListView(children: const [SecuritySection()]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Rows in the section: every SwitchListTile builds exactly one ListTile.
  Finder rows() => find.descendant(
    of: find.byType(SecuritySection),
    matching: find.byType(ListTile),
  );

  bool switchValue(WidgetTester tester) =>
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, pt.lockPinToggle),
          )
          .value;

  /// Pops the PIN setup route with [result], as the real screen does.
  Future<void> finishSetup(WidgetTester tester, {required bool result}) async {
    tester.state<NavigatorState>(find.byType(Navigator)).pop(result);
    await tester.pumpAndSettle();
  }

  group('turning the lock on (create)', () {
    testWidgets('a cancelled setup keeps the switch OFF, no SnackBar', (
      tester,
    ) async {
      await setUpWith({});
      await pump(tester);
      expect(switchValue(tester), isFalse);

      await tester.tap(find.text(pt.lockPinToggle));
      await tester.pumpAndSettle();
      expect(find.byType(PinSetupScreen), findsOneWidget);
      expect(started, [PinSetupMode.create]);

      await finishSetup(tester, result: false);

      expect(find.byType(PinSetupScreen), findsNothing);
      expect(switchValue(tester), isFalse);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a completed setup shows ON and pinEnabledSnack', (
      tester,
    ) async {
      await setUpWith({});
      await pump(tester);

      await tester.tap(find.text(pt.lockPinToggle));
      await tester.pumpAndSettle();
      // While setup is open the switch has not flipped.
      expect(cubit.state.pinEnabled, isFalse);

      appLock.pinEnabledChanged(enabled: true); // what PinLifecycle does
      await finishSetup(tester, result: true);

      expect(switchValue(tester), isTrue);
      expect(find.text(pt.pinEnabledSnack), findsOneWidget);
      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.behavior, SnackBarBehavior.floating);
    });
  });

  group('turning the lock off (confirm + verify)', () {
    testWidgets('Cancel in the dialog keeps ON and pushes nothing', (
      tester,
    ) async {
      await setUpWith({StorageKeys.pinConfigured: true});
      await pump(tester);
      expect(switchValue(tester), isTrue);

      await tester.tap(find.text(pt.lockPinToggle));
      await tester.pumpAndSettle();
      expect(find.text(pt.pinDisableTitle), findsOneWidget);
      expect(find.text(pt.pinDisableBody), findsOneWidget);

      await tester.tap(find.text(pt.cancelButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(PinSetupScreen), findsNothing);
      expect(started, isEmpty);
      expect(switchValue(tester), isTrue);
    });

    testWidgets('the confirm button is error-coloured', (tester) async {
      await setUpWith({StorageKeys.pinConfigured: true});
      await pump(tester);
      await tester.tap(find.text(pt.lockPinToggle));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, pt.pinDisableConfirm),
      );
      final context = tester.element(find.byType(AlertDialog));
      expect(
        button.style?.backgroundColor?.resolve({}),
        Theme.of(context).colorScheme.error,
      );
    });

    testWidgets('Confirm opens verify; backing out keeps ON', (tester) async {
      await setUpWith({StorageKeys.pinConfigured: true});
      await pump(tester);

      await tester.tap(find.text(pt.lockPinToggle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(pt.pinDisableConfirm));
      await tester.pumpAndSettle();

      expect(find.byType(PinSetupScreen), findsOneWidget);
      expect(started, [PinSetupMode.verify]);

      await finishSetup(tester, result: false);

      expect(switchValue(tester), isTrue);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('the correct PIN turns it OFF with pinDisabledSnack', (
      tester,
    ) async {
      await setUpWith({StorageKeys.pinConfigured: true});
      await pump(tester);

      await tester.tap(find.text(pt.lockPinToggle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(pt.pinDisableConfirm));
      await tester.pumpAndSettle();

      appLock.pinEnabledChanged(enabled: false); // PinLifecycle.disable
      await finishSetup(tester, result: true);

      expect(switchValue(tester), isFalse);
      expect(find.text(pt.pinDisabledSnack), findsOneWidget);
    });
  });

  group('rows by state (UI Considerations)', () {
    testWidgets('PIN off: only the PIN switch', (tester) async {
      await setUpWith({});
      await pump(tester);

      expect(rows(), findsOneWidget);
      expect(find.text(pt.lockChangePin), findsNothing);
      expect(find.text(pt.lockBiometricToggle), findsNothing);
      expect(find.text(pt.lockTimeoutLabel), findsNothing);
    });

    testWidgets('PIN on + enrolled: four rows', (tester) async {
      await setUpWith({StorageKeys.pinConfigured: true});
      await pump(tester);

      expect(rows(), findsNWidgets(4));
      expect(find.text(pt.lockChangePin), findsOneWidget);
      expect(find.text(pt.lockBiometricToggle), findsOneWidget);
      expect(find.text(pt.lockTimeoutLabel), findsOneWidget);
      expect(find.text(pt.lockTimeout1m), findsOneWidget);
      final bio = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, pt.lockBiometricToggle),
      );
      expect(bio.value, isTrue); // D-08 default when nothing is stored
      expect(bio.onChanged, isNotNull);
    });

    testWidgets('PIN on + not enrolled: biometrics disabled with hint', (
      tester,
    ) async {
      when(
        gateway.biometricAvailability,
      ).thenAnswer((_) async => BiometricAvailability.notEnrolled);
      await setUpWith({StorageKeys.pinConfigured: true});
      await pump(tester);

      expect(rows(), findsNWidgets(4));
      final bio = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, pt.lockBiometricToggle),
      );
      expect(bio.onChanged, isNull);
      expect(find.text(pt.lockBiometricNotEnrolled), findsOneWidget);
    });

    testWidgets('PIN on + no hardware: three rows', (tester) async {
      when(
        gateway.biometricAvailability,
      ).thenAnswer((_) async => BiometricAvailability.noHardware);
      await setUpWith({StorageKeys.pinConfigured: true});
      await pump(tester);

      expect(rows(), findsNWidgets(3));
      expect(find.text(pt.lockBiometricToggle), findsNothing);
    });

    testWidgets('availability unresolved: biometrics absent', (tester) async {
      await setUpWith({StorageKeys.pinConfigured: true});
      await pump(tester, start: false);

      expect(cubit.state.availability, isNull);
      expect(rows(), findsNWidgets(3));
      expect(find.text(pt.lockBiometricToggle), findsNothing);
    });

    testWidgets('toggling biometrics persists false', (tester) async {
      await setUpWith({StorageKeys.pinConfigured: true});
      await pump(tester);

      await tester.tap(find.text(pt.lockBiometricToggle));
      await tester.pumpAndSettle();

      expect(prefs.getBool(StorageKeys.biometricUnlockEnabled), isFalse);
      final bio = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, pt.lockBiometricToggle),
      );
      expect(bio.value, isFalse);
    });

    testWidgets('Alterar PIN opens change mode and confirms', (tester) async {
      await setUpWith({StorageKeys.pinConfigured: true});
      await pump(tester);

      await tester.tap(find.text(pt.lockChangePin));
      await tester.pumpAndSettle();
      expect(started, [PinSetupMode.change]);

      await finishSetup(tester, result: true);
      expect(find.text(pt.pinChangedSnack), findsOneWidget);
      expect(switchValue(tester), isTrue);
    });
  });

  group('lock timeout (D-02)', () {
    testWidgets('five options in order; 5 minutos persists 300', (
      tester,
    ) async {
      await setUpWith({StorageKeys.pinConfigured: true});
      await pump(tester);

      await tester.tap(find.text(pt.lockTimeoutLabel));
      await tester.pumpAndSettle();

      expect(find.text(pt.lockTimeoutDialogTitle), findsOneWidget);
      final radios =
          tester
              .widgetList<RadioListTile<int>>(find.byType(RadioListTile<int>))
              .map((r) => r.value)
              .toList();
      expect(radios, [0, 30, 60, 300, 900]);
      final labels = [
        pt.lockTimeoutImmediate,
        pt.lockTimeout30s,
        pt.lockTimeout1m,
        pt.lockTimeout5m,
        pt.lockTimeout15m,
      ];
      final dialog = find.byType(AlertDialog);
      for (var i = 1; i < labels.length; i++) {
        final above = find.descendant(
          of: dialog,
          matching: find.text(labels[i - 1]),
        );
        final below = find.descendant(
          of: dialog,
          matching: find.text(labels[i]),
        );
        expect(
          tester.getTopLeft(above).dy,
          lessThan(tester.getTopLeft(below).dy),
        );
      }

      await tester.tap(find.text(pt.lockTimeout5m));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(prefs.getInt(StorageKeys.lockTimeoutSeconds), 300);
      expect(find.text(pt.lockTimeout5m), findsOneWidget); // row subtitle
    });

    testWidgets('Cancel closes without changing the timeout', (tester) async {
      await setUpWith({StorageKeys.pinConfigured: true});
      await pump(tester);

      await tester.tap(find.text(pt.lockTimeoutLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(pt.cancelButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(prefs.getInt(StorageKeys.lockTimeoutSeconds), isNull);
      expect(cubit.state.timeoutSeconds, 60);
    });

    testWidgets('at 200% text the dialog scrolls to the last option', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await setUpWith({StorageKeys.pinConfigured: true});
      await pump(tester, textScale: 2);

      await tester.ensureVisible(find.text(pt.lockTimeoutLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(pt.lockTimeoutLabel));
      await tester.pumpAndSettle();
      final last = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(pt.lockTimeout15m),
      );
      await tester.scrollUntilVisible(
        last,
        50,
        scrollable: find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(last);
      await tester.pumpAndSettle();

      expect(prefs.getInt(StorageKeys.lockTimeoutSeconds), 900);
      expect(tester.takeException(), isNull);
    });
  });

  group('no device screen lock', () {
    setUp(() {
      when(gateway.hasDeviceCredential).thenAnswer((_) async => false);
    });

    testWidgets('Cancel on the warning pushes nothing; switch stays OFF', (
      tester,
    ) async {
      await setUpWith({});
      await pump(tester);

      await tester.tap(find.text(pt.lockPinToggle));
      await tester.pumpAndSettle();
      expect(find.text(pt.pinNoDeviceLockTitle), findsOneWidget);
      expect(find.text(pt.pinNoDeviceLockBody), findsOneWidget);

      await tester.tap(find.text(pt.cancelButton));
      await tester.pumpAndSettle();

      expect(find.byType(PinSetupScreen), findsNothing);
      expect(started, isEmpty);
      expect(switchValue(tester), isFalse);
    });

    testWidgets('"Criar PIN mesmo assim" opens create', (tester) async {
      await setUpWith({});
      await pump(tester);

      await tester.tap(find.text(pt.lockPinToggle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(pt.pinNoDeviceLockContinue));
      await tester.pumpAndSettle();

      expect(find.byType(PinSetupScreen), findsOneWidget);
      expect(started, [PinSetupMode.create]);
    });
  });

  group('long text', () {
    for (final locale in const [Locale('pt', 'BR'), Locale('en')]) {
      testWidgets('pinDisableBody wraps, no ellipsis ($locale)', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final l10n = lookupAppLocalizations(locale);
        await setUpWith({StorageKeys.pinConfigured: true});
        await pump(tester, locale: locale);

        await tester.tap(find.text(l10n.lockPinToggle));
        await tester.pumpAndSettle();

        final body = find.text(l10n.pinDisableBody);
        final text = tester.widget<Text>(body);
        expect(text.maxLines, isNull);
        expect(text.overflow, isNot(TextOverflow.ellipsis));
        final paragraph = tester.renderObject<RenderParagraph>(body);
        expect(paragraph.didExceedMaxLines, isFalse);
        final fontSize = paragraph.text.style?.fontSize ?? 14;
        expect(paragraph.size.height, greaterThan(fontSize * 2)); // wrapped
      });
    }
  });
}
