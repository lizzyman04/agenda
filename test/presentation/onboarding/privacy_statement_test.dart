import 'package:agenda/application/shared/locale/locale_cubit.dart';
import 'package:agenda/application/shared/locale/locale_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/onboarding/widgets/onboarding_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
