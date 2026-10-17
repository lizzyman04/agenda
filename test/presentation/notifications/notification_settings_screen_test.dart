import 'package:agenda/application/notifications/notification_settings_cubit.dart';
import 'package:agenda/application/notifications/notification_settings_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/notification_prefs.dart';
import 'package:agenda/domain/notifications/model/quote_frequency.dart';
import 'package:agenda/domain/notifications/notification_permission_service.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/notifications/screens/notification_settings_screen.dart';
import 'package:agenda/presentation/notifications/widgets/notification_type_tile.dart';
import 'package:agenda/presentation/notifications/widgets/permission_banner.dart';
import 'package:agenda/presentation/notifications/widgets/time_setting_tile.dart';
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
  bool permissionRequested = false,
}) => NotificationSettingsLoaded(
  prefs: prefs ?? NotificationPrefs.defaults(),
  permission: permission,
  canScheduleExact: canScheduleExact,
  waitingCount: waitingCount,
  permissionRequested: permissionRequested,
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

  setUpAll(() {
    registerFallbackValue(NotificationKind.taskReminder);
    registerFallbackValue(QuoteFrequency.daily);
  });

  setUp(() {
    cubit = MockSettingsCubit();
    when(() => cubit.start()).thenAnswer((_) async {});
    when(() => cubit.refreshPermissions()).thenAnswer((_) async {});
    when(() => cubit.requestPermission()).thenAnswer((_) async {});
    when(() => cubit.requestExactAlarms()).thenAnswer((_) async {});
    when(() => cubit.setQuoteFrequency(any())).thenAnswer((_) async {});
    when(() => cubit.setBriefingMinutes(any())).thenAnswer((_) async {});
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

      expect(find.byType(NotificationTypeTile), findsNWidgets(8));
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
        // The quotes name is also the quotes section heading.
        expect(find.text(name), findsAtLeastNWidgets(1), reason: name);
      }
    });

    testWidgets('quotes are off by default, the rest are on', (tester) async {
      await pumpScreen(tester, loadedState());

      final tiles =
          tester
              .widgetList<NotificationTypeTile>(
                find.byType(NotificationTypeTile),
              )
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

    group('permission banners', () {
      testWidgets('denied permission shows the banner and Allow asks', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          loadedState(permission: NotificationPermission.denied),
        );

        expect(find.byType(PermissionBanner), findsOneWidget);
        await tester.tap(find.text('Permitir notificações'));
        verify(() => cubit.requestPermission()).called(1);
      });

      testWidgets('after a refused request the banner offers Open settings', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          loadedState(
            permission: NotificationPermission.denied,
            permissionRequested: true,
          ),
        );

        expect(find.text('Permitir notificações'), findsNothing);
        await tester.tap(find.text('Abrir configurações'));
        verify(() => cubit.requestPermission()).called(1);
      });

      testWidgets('granted permission hides the banner', (tester) async {
        await pumpScreen(tester, loadedState());
        expect(find.byType(PermissionBanner), findsNothing);
      });

      testWidgets('exact-alarm banner shows on Android when missing', (
        tester,
      ) async {
        await pumpScreen(tester, loadedState(canScheduleExact: false));

        expect(find.byType(PermissionBanner), findsOneWidget);
        await tester.tap(find.text('Permitir alarmes exatos'));
        verify(() => cubit.requestExactAlarms()).called(1);
      });

      testWidgets('exact-alarm banner is hidden on iOS', (tester) async {
        await pumpScreen(
          tester,
          loadedState(canScheduleExact: false),
          platform: TargetPlatform.iOS,
        );
        expect(find.byType(PermissionBanner), findsNothing);
      });

      testWidgets('exact-alarm banner is hidden when exact is allowed', (
        tester,
      ) async {
        await pumpScreen(tester, loadedState());
        expect(find.text('Permitir alarmes exatos'), findsNothing);
      });
    });

    group('quotes', () {
      final quotesOn = NotificationPrefs.defaults().withEnabled(
        NotificationKind.motivationalQuote,
        value: true,
      );

      testWidgets('off shows only the hint', (tester) async {
        await pumpScreen(tester, loadedState());

        expect(find.byType(SegmentedButton<QuoteFrequency>), findsNothing);
        expect(find.text('Horário da frase'), findsNothing);
        expect(
          find.text(
            AppLocalizations.of(
              tester.element(find.byType(Scaffold)),
            ).notifSettingsQuotesOffHint,
          ),
          findsOneWidget,
        );
      });

      testWidgets('on shows frequency and time controls', (tester) async {
        await pumpScreen(tester, loadedState(prefs: quotesOn));

        expect(find.byType(SegmentedButton<QuoteFrequency>), findsOneWidget);
        expect(find.text('Horário da frase'), findsOneWidget);
      });

      testWidgets('changing the frequency calls setQuoteFrequency', (
        tester,
      ) async {
        await pumpScreen(tester, loadedState(prefs: quotesOn));

        await tester.tap(find.text('Semanal (segundas-feiras)'));
        verify(() => cubit.setQuoteFrequency(QuoteFrequency.weekly)).called(1);
      });
    });

    group('waiting count and quiet hours', () {
      testWidgets('shows the waiting text for a count of 3', (tester) async {
        await pumpScreen(tester, loadedState(waitingCount: 3));
        expect(
          find.text('3 lembretes aguardam um espaço livre'),
          findsOneWidget,
        );
      });

      testWidgets('hides the waiting text for a count of 0', (tester) async {
        await pumpScreen(tester, loadedState());
        expect(find.textContaining('aguardam'), findsNothing);
      });

      testWidgets('quiet start is disabled while quiet hours are off', (
        tester,
      ) async {
        final off = NotificationPrefs.defaults().copyWith(
          quietHoursEnabled: false,
        );
        await pumpScreen(tester, loadedState(prefs: off));

        final start = find.widgetWithText(TimeSettingTile, 'Das');
        expect(tester.widget<TimeSettingTile>(start).enabled, isFalse);
        expect(find.text('22:00'), findsOneWidget);
        expect(find.text('07:00'), findsOneWidget);
      });

      testWidgets('quiet start is enabled while quiet hours are on', (
        tester,
      ) async {
        await pumpScreen(tester, loadedState());
        final start = find.widgetWithText(TimeSettingTile, 'Das');
        expect(tester.widget<TimeSettingTile>(start).enabled, isTrue);
      });

      testWidgets('briefing time is disabled while the briefing is off', (
        tester,
      ) async {
        final off = NotificationPrefs.defaults().withEnabled(
          NotificationKind.morningBriefing,
          value: false,
        );
        await pumpScreen(tester, loadedState(prefs: off));

        final tile = find.widgetWithText(TimeSettingTile, 'Horário do resumo');
        expect(tester.widget<TimeSettingTile>(tile).enabled, isFalse);
      });

      testWidgets('picking a briefing time reports minutes since midnight', (
        tester,
      ) async {
        await pumpScreen(tester, loadedState());

        await tester.tap(find.text('Horário do resumo'));
        await tester.pumpAndSettle();
        expect(find.byType(TimePickerDialog), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        verify(() => cubit.setBriefingMinutes(480)).called(1);
      });

      testWidgets('cancelling the picker reports nothing', (tester) async {
        await pumpScreen(tester, loadedState());

        await tester.tap(find.text('Horário do resumo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        verifyNever(() => cubit.setBriefingMinutes(any()));
      });

      testWidgets('the privacy note is always shown', (tester) async {
        await pumpScreen(tester, loadedState());
        expect(
          find.text(
            AppLocalizations.of(
              tester.element(find.byType(Scaffold)),
            ).notifSettingsPrivacyNote,
          ),
          findsOneWidget,
        );
      });
    });
  });
}
