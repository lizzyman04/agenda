import 'package:agenda/application/shared/locale/locale_cubit.dart';
import 'package:agenda/application/shared/locale/locale_state.dart';
import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/settings/screens/settings_screen.dart';
import 'package:agenda/presentation/tasks/screens/task_list_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockTaskListCubit extends MockCubit<TaskListState>
    implements TaskListCubit {}

/// The cubit sits above MaterialApp, so a locale change rebuilds the app.
Widget _app(
  LocaleCubit localeCubit,
  Widget home, {
  List<NavigatorObserver> observers = const [],
}) {
  return BlocProvider<LocaleCubit>.value(
    value: localeCubit,
    child: BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, state) => MaterialApp(
        locale: state.locale,
        navigatorObservers: observers,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
}

void main() {
  late LocaleCubit localeCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    localeCubit = LocaleCubit(await SharedPreferences.getInstance());
  });

  tearDown(() async => localeCubit.close());

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
}
