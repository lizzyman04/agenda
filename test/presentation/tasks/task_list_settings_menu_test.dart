import 'package:agenda/application/backup/backup_cubit.dart';
import 'package:agenda/application/backup/backup_state.dart';
import 'package:agenda/application/notifications/notification_settings_cubit.dart';
import 'package:agenda/application/notifications/notification_settings_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/backup/screens/backup_screen.dart';
import 'package:agenda/presentation/notifications/screens/notification_settings_screen.dart';
import 'package:agenda/presentation/tasks/widgets/task_list_settings_menu.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsCubit extends MockCubit<NotificationSettingsState>
    implements NotificationSettingsCubit {}

class MockBackupCubit extends MockCubit<BackupState> implements BackupCubit {}

void main() {
  late MockSettingsCubit cubit;
  late MockBackupCubit backupCubit;

  setUp(() {
    cubit = MockSettingsCubit();
    when(() => cubit.start()).thenAnswer((_) async {});
    when(() => cubit.refreshPermissions()).thenAnswer((_) async {});
    when(() => cubit.state).thenReturn(const NotificationSettingsInitial());
    whenListen(
      cubit,
      const Stream<NotificationSettingsState>.empty(),
      initialState: const NotificationSettingsInitial(),
    );
    getIt.registerFactory<NotificationSettingsCubit>(() => cubit);

    backupCubit = MockBackupCubit();
    when(() => backupCubit.state).thenReturn(const BackupIdle());
    whenListen(
      backupCubit,
      const Stream<BackupState>.empty(),
      initialState: const BackupIdle(),
    );
    getIt.registerFactory<BackupCubit>(() => backupCubit);
  });

  tearDown(() async => getIt.reset());

  Widget host() => MaterialApp(
    locale: const Locale('pt', 'BR'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      appBar: AppBar(actions: const [TaskListSettingsMenu()]),
    ),
  );

  group('TaskListSettingsMenu', () {
    testWidgets('shows the settings icon with a tooltip', (tester) async {
      await tester.pumpWidget(host());

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byTooltip('Configurações'), findsOneWidget);
    });

    testWidgets('opens a menu with the Notifications and Backup entries', (
      tester,
    ) async {
      await tester.pumpWidget(host());

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Notificações'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      final l10n = AppLocalizations.of(
        tester.element(
          find.byType(PopupMenuButton<TaskListSettingsDestination>),
        ),
      );
      expect(find.text(l10n.backupMenuLabel), findsOneWidget);
      expect(find.byIcon(Icons.backup_outlined), findsOneWidget);
    });

    testWidgets('selecting Backup opens the backup page', (tester) async {
      await tester.pumpWidget(host());
      final l10n = AppLocalizations.of(
        tester.element(
          find.byType(PopupMenuButton<TaskListSettingsDestination>),
        ),
      );

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.backupMenuLabel));
      await tester.pumpAndSettle();

      expect(find.byType(BackupScreen), findsOneWidget);
      expect(find.text(l10n.backupScreenTitle), findsOneWidget);
    });

    testWidgets('selecting Notifications opens the settings page', (
      tester,
    ) async {
      await tester.pumpWidget(host());

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notificações'));
      // The page shows a spinner (state Initial), so pumpAndSettle would hang.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
      verify(() => cubit.start()).called(1);
    });
  });
}
