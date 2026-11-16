import 'package:agenda/application/lock/app_lock_cubit.dart';
import 'package:agenda/application/settings/security_settings_cubit.dart';
import 'package:agenda/application/shared/locale/locale_cubit.dart';
import 'package:agenda/application/shared/locale/locale_state.dart';
import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/config/app_config.dart';
import 'package:agenda/domain/lock/device_auth_gateway.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/infrastructure/lock/excursion_guard_impl.dart';
import 'package:agenda/presentation/backup/screens/backup_screen.dart';
import 'package:agenda/presentation/notifications/screens/notification_settings_screen.dart';
import 'package:agenda/presentation/onboarding/screens/privacy_statement_screen.dart';
import 'package:agenda/presentation/settings/screens/settings_screen.dart';
import 'package:agenda/presentation/settings/widgets/settings_section_header.dart';
import 'package:agenda/presentation/tasks/screens/task_list_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/lock_fakes.dart';

class MockTaskListCubit extends MockCubit<TaskListState>
    implements TaskListCubit {}

/// Records every route pushed so a test can inspect where a row leads.
class _RecordingObserver extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
}

/// The cubit sits above MaterialApp, so a locale change rebuilds the app.
Widget _app(
  LocaleCubit localeCubit,
  Widget home, {
  List<NavigatorObserver> observers = const [],
  double textScale = 1,
}) {
  return BlocProvider<LocaleCubit>.value(
    value: localeCubit,
    child: BlocBuilder<LocaleCubit, LocaleState>(
      builder:
          (context, state) => MaterialApp(
            locale: state.locale,
            navigatorObservers: observers,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder:
                (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(textScale)),
                  child: child!,
                ),
            home: home,
          ),
    ),
  );
}

void main() {
  late LocaleCubit localeCubit;
  late AppLockCubit appLock;
  late MockDeviceAuthGateway gateway;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    localeCubit = LocaleCubit(prefs);
    appLock = AppLockCubit(prefs, ExcursionGuardImpl());
    gateway = MockDeviceAuthGateway();
    when(
      gateway.biometricAvailability,
    ).thenAnswer((_) async => BiometricAvailability.enrolled);
    getIt.registerFactory<SecuritySettingsCubit>(
      () => SecuritySettingsCubit(prefs, appLock, gateway),
    );
  });

  tearDown(() async {
    await localeCubit.close();
    await appLock.close();
    await getIt.reset();
  });

  group('Settings entry point (D-09)', () {
    testWidgets('the Tasks AppBar gear opens Settings', (tester) async {
      final taskCubit = MockTaskListCubit();
      when(taskCubit.start).thenAnswer((_) async {});
      whenListen(
        taskCubit,
        const Stream<TaskListState>.empty(),
        initialState: const TaskListLoaded(items: []),
      );

      await tester.pumpWidget(
        _app(
          localeCubit,
          BlocProvider<TaskListCubit>.value(
            value: taskCubit,
            child: const TaskListScreen(),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byTooltip('Configurações'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('Language (D-11, UX-01)', () {
    testWidgets('choosing English re-renders the app at once', (tester) async {
      await tester.pumpWidget(_app(localeCubit, const SettingsScreen()));

      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Português (Brasil)'), findsOneWidget);

      await tester.tap(find.text('Idioma'));
      await tester.pumpAndSettle();

      expect(find.byType(RadioListTile<Locale>), findsNWidgets(2));
      expect(find.text('Escolher idioma'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(localeCubit.state.locale, const Locale('en'));
    });

    testWidgets('Cancel closes the dialog without changing the language', (
      tester,
    ) async {
      await tester.pumpWidget(_app(localeCubit, const SettingsScreen()));

      await tester.tap(find.text('Idioma'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Configurações'), findsOneWidget);
      expect(localeCubit.state.locale, const Locale('pt', 'BR'));
    });
  });

  group('Sections (D-10)', () {
    testWidgets('headers run General, Notifications, Data, About', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(localeCubit, const SettingsScreen()));

      double top(String title) =>
          tester
              .getTopLeft(find.widgetWithText(SettingsSectionHeader, title))
              .dy;

      expect(top('Geral'), lessThan(top('Notificações')));
      expect(top('Notificações'), lessThan(top('Dados')));
      expect(top('Dados'), lessThan(top('Sobre')));
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('the version row shows AppConfig.version and has no action', (
      tester,
    ) async {
      await tester.pumpWidget(_app(localeCubit, const SettingsScreen()));
      await tester.scrollUntilVisible(find.text(AppConfig.version), 100);

      final tile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text(AppConfig.version),
          matching: find.byType(ListTile),
        ),
      );
      expect(tile.onTap, isNull);
      expect(tile.trailing, isNull);
    });

    // Tapping records the push; the route is never built (no pump), so the
    // feature pages need no DI. The test calls the builder instead.
    Future<Widget> pageFor(WidgetTester tester, String rowTitle) async {
      final observer = _RecordingObserver();
      await tester.pumpWidget(
        _app(localeCubit, const SettingsScreen(), observers: [observer]),
      );
      await tester.scrollUntilVisible(find.text(rowTitle), 100);
      final before = observer.pushed.length;
      await tester.tap(find.text(rowTitle));

      expect(observer.pushed.length, before + 1);
      final route = observer.pushed.last as MaterialPageRoute<void>;
      return route.builder(tester.element(find.byType(SettingsScreen)));
    }

    testWidgets('Notifications row pushes NotificationSettingsScreen', (
      tester,
    ) async {
      final page = await pageFor(
        tester,
        'Tipos, horários e horário de silêncio',
      );
      expect(page, isA<NotificationSettingsScreen>());
    });

    testWidgets('Data row pushes BackupScreen', (tester) async {
      final page = await pageFor(tester, 'Backup e restauração');
      expect(page, isA<BackupScreen>());
    });

    testWidgets('Privacy row pushes the read-only statement (D-14)', (
      tester,
    ) async {
      final page = await pageFor(tester, 'Privacidade');
      expect(page, isA<PrivacyStatementScreen>());
      expect((page as PrivacyStatementScreen).readOnly, isTrue);
    });

    testWidgets('scrolls at 200% text on 320x568 with no overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(localeCubit, const SettingsScreen(), textScale: 2),
      );

      await tester.scrollUntilVisible(find.text(AppConfig.version), 100);
      await tester.pumpAndSettle();

      expect(find.text(AppConfig.version), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
