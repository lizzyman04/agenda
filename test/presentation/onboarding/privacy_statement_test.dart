import 'package:agenda/application/shared/locale/locale_cubit.dart';
import 'package:agenda/application/shared/locale/locale_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/onboarding/screens/privacy_statement_screen.dart';
import 'package:agenda/presentation/onboarding/widgets/onboarding_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

/// Localized app frame whose locale follows [cubit], like `AgendaApp`.
Widget _localizedApp(LocaleCubit cubit, Widget home) {
  return BlocProvider<LocaleCubit>.value(
    value: cubit,
    child: BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, state) => MaterialApp(
        locale: state.locale,
        supportedLocales: LocaleCubit.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    ),
  );
}

void main() {
  final ptBr = lookupAppLocalizations(const Locale('pt', 'BR'));
  late SharedPreferences prefs;
  late LocaleCubit localeCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(prefs);
    localeCubit = LocaleCubit(prefs);
  });

  tearDown(() async {
    await localeCubit.close();
    await getIt.reset();
  });

  Future<void> pumpGate(WidgetTester tester) => tester.pumpWidget(
    _localizedApp(localeCubit, const OnboardingGate(child: Text('HOME'))),
  );

  group('OnboardingGate first launch', () {
    testWidgets('renders headline, intro and the four bullets in order', (
      tester,
    ) async {
      await pumpGate(tester);

      final texts = [
        ptBr.privacyStatement,
        ptBr.privacyIntro,
        ptBr.privacyBulletOffline,
        ptBr.privacyBulletNoTracking,
        ptBr.privacyBulletBackup,
        ptBr.privacyBulletPin,
      ];
      var previousTop = double.negativeInfinity;
      for (final text in texts) {
        final finder = find.text(text);
        expect(finder, findsOneWidget, reason: text);
        final top = tester.getTopLeft(finder).dy;
        expect(top, greaterThan(previousTop), reason: text);
        previousTop = top;
      }
      expect(find.text('HOME'), findsNothing);
    });

    testWidgets('Começar persists the flag, then shows the child', (
      tester,
    ) async {
      await pumpGate(tester);

      await tester.tap(find.text(ptBr.privacyGetStarted));
      await tester.pumpAndSettle();

      expect(find.text('HOME'), findsOneWidget);
      expect(find.text(ptBr.privacyStatement), findsNothing);
      expect(prefs.getBool('privacy_statement_shown'), isTrue);
    });

    testWidgets('a stored flag shows the child on the first frame', (
      tester,
    ) async {
      await prefs.setBool('privacy_statement_shown', true);
      await pumpGate(tester);

      expect(find.text('HOME'), findsOneWidget);
      expect(find.text(ptBr.privacyStatement), findsNothing);
    });
  });

  testWidgets('English re-renders the statement and sets the locale', (
    tester,
  ) async {
    await pumpGate(tester);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Your data never leaves this device'), findsOneWidget);
    expect(find.text(ptBr.privacyStatement), findsNothing);
    expect(localeCubit.state.locale, const Locale('en'));
  });

  testWidgets('read-only mode: AppBar with back, no switch, no button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(
        localeCubit,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PrivacyStatementScreen(readOnly: true),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(ptBr.settingsPrivacyLabel),
      ),
      findsOneWidget,
    );
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text(ptBr.privacyStatement), findsOneWidget);
    expect(find.byType(SegmentedButton<Locale>), findsNothing);
    expect(find.text(ptBr.privacyGetStarted), findsNothing);
  });

  group('a failed flag write keeps the statement (backstop)', () {
    late MockSharedPreferences mockPrefs;

    setUp(() async {
      mockPrefs = MockSharedPreferences();
      when(() => mockPrefs.getBool(any())).thenReturn(null);
      await getIt.unregister<SharedPreferences>();
      getIt.registerSingleton<SharedPreferences>(mockPrefs);
    });

    Future<void> tapAndExpectStatement(WidgetTester tester) async {
      await pumpGate(tester);
      await tester.tap(find.text(ptBr.privacyGetStarted));
      await tester.pumpAndSettle();

      expect(find.text(ptBr.privacyStatement), findsOneWidget);
      expect(find.text('HOME'), findsNothing);
      verify(() => mockPrefs.setBool('privacy_statement_shown', true))
          .called(1);
    }

    testWidgets('setBool returns false', (tester) async {
      when(
        () => mockPrefs.setBool(any(), any()),
      ).thenAnswer((_) async => false);
      await tapAndExpectStatement(tester);
    });

    testWidgets('setBool throws', (tester) async {
      when(
        () => mockPrefs.setBool(any(), any()),
      ).thenThrow(Exception('disk full'));
      await tapAndExpectStatement(tester);
    });
  });

  testWidgets('320x568 at 200% text scrolls and keeps Começar (backstop)', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpGate(tester);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(ptBr.privacyGetStarted).hitTestable(), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
