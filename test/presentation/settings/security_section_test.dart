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

  Future<void> pump(WidgetTester tester, {Locale? locale}) async {
    await cubit.start();
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
}
