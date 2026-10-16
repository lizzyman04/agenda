import 'package:agenda/application/notifications/notification_settings_cubit.dart';
import 'package:agenda/application/notifications/notification_settings_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/notifications/notification_permission_service.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/notifications/screens/notification_settings_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsCubit extends MockCubit<NotificationSettingsState>
    implements NotificationSettingsCubit {}

NotificationSettingsLoaded loadedState({
  NotificationPrefs? prefs,
  NotificationPermission permission = NotificationPermission.granted,
  bool canScheduleExact = true,
  int waitingCount = 0,
}) => NotificationSettingsLoaded(
  prefs: prefs ?? NotificationPrefs.defaults(),
  permission: permission,
  canScheduleExact: canScheduleExact,
  waitingCount: waitingCount,
);

void main() {
  late MockSettingsCubit cubit;

  Future<void> pumpScreen(
    WidgetTester tester,
    NotificationSettingsState state, {
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    // Tall viewport: the page is a lazy ListView and tests need every row.
    tester.view
      ..physicalSize = const Size(800, 4000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => cubit.state).thenReturn(state);
    whenListen(
      cubit,
      const Stream<NotificationSettingsState>.empty(),
      initialState: state,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: platform),
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const NotificationSettingsScreen(),
      ),
    );
    await tester.pump();
  }

  setUpAll(() => registerFallbackValue(NotificationKind.taskReminder));

  setUp(() {
    cubit = MockSettingsCubit();
    when(() => cubit.start()).thenAnswer((_) async {});
    when(() => cubit.refreshPermissions()).thenAnswer((_) async {});
    getIt.registerFactory<NotificationSettingsCubit>(() => cubit);
  });

  tearDown(() async => getIt.reset());

  group('NotificationSettingsScreen', () {
    testWidgets('shows a spinner before the state is loaded', (tester) async {
      await pumpScreen(tester, const NotificationSettingsInitial());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      verify(() => cubit.start()).called(1);
    });

    testWidgets('renders eight switches with the PT-BR channel names', (
      tester,
    ) async {
      await pumpScreen(tester, loadedState());

      expect(find.byType(SwitchListTile), findsNWidgets(8));
      for (final name in const [
        'Lembretes de tarefas',
        'Lembretes de tarefas recorrentes',
        'Resumo da manhã',
        'Alertas de orçamento',
        'Lembretes de dívidas',
        'Alertas de metas',
        'Contas e assinaturas',
        'Frases motivacionais',
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
    });

    testWidgets('quotes are off by default, the rest are on', (tester) async {
      await pumpScreen(tester, loadedState());

      final tiles =
          tester
              .widgetList<SwitchListTile>(find.byType(SwitchListTile))
              .toList();
      expect(tiles.map((t) => t.value), [
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        false,
      ]);
    });

    testWidgets('toggling a switch calls setEnabled with kind and value', (
      tester,
    ) async {
      when(
        () => cubit.setEnabled(any(), enabled: any(named: 'enabled')),
      ).thenAnswer((_) async {});
      await pumpScreen(tester, loadedState());

      await tester.tap(find.byType(SwitchListTile).at(3));
      verify(
        () => cubit.setEnabled(NotificationKind.budgetAlert, enabled: false),
      ).called(1);

      await tester.tap(find.byType(SwitchListTile).at(7));
      verify(
        () => cubit.setEnabled(
          NotificationKind.motivationalQuote,
          enabled: true,
        ),
      ).called(1);
    });
  });
}
