import 'package:agenda/application/backup/backup_cubit.dart';
import 'package:agenda/application/backup/backup_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/backup/screens/backup_screen.dart';
import 'package:agenda/presentation/backup/widgets/backup_action_card.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBackupCubit extends MockCubit<BackupState> implements BackupCubit {}

void main() {
  late MockBackupCubit cubit;

  Future<void> pumpScreen(
    WidgetTester tester,
    BackupState state, {
    Stream<BackupState>? stream,
    Locale locale = const Locale('pt', 'BR'),
  }) async {
    tester.view
      ..physicalSize = const Size(800, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => cubit.state).thenReturn(state);
    whenListen(
      cubit,
      stream ?? const Stream<BackupState>.empty(),
      initialState: state,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BackupScreen(),
      ),
    );
    await tester.pump();
  }

  setUp(() {
    cubit = MockBackupCubit();
    when(
      () => cubit.exportJson(dialogTitle: any(named: 'dialogTitle')),
    ).thenAnswer((_) async {});
    when(
      () => cubit.exportCsv(
        languageCode: any(named: 'languageCode'),
        dialogTitle: any(named: 'dialogTitle'),
      ),
    ).thenAnswer((_) async {});
    when(() => cubit.acknowledge()).thenReturn(null);
    getIt.registerFactory<BackupCubit>(() => cubit);
  });

  tearDown(() async => getIt.reset());

  group('BackupScreen', () {
    testWidgets('renders both cards, the privacy and reinstall notes', (
      tester,
    ) async {
      await pumpScreen(tester, const BackupIdle());

      expect(find.byType(BackupActionCard), findsNWidgets(2));
      expect(find.text('Exportar backup completo (JSON)'), findsOneWidget);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(BackupScreen)),
      );
      expect(find.text(l10n.backupExportCsv), findsOneWidget);
      expect(find.text(l10n.backupPrivacyNote), findsOneWidget);
      expect(find.text(l10n.backupReinstallNote), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('tapping JSON calls exportJson with the dialog title', (
      tester,
    ) async {
      await pumpScreen(tester, const BackupIdle());
      final l10n = AppLocalizations.of(
        tester.element(find.byType(BackupScreen)),
      );

      await tester.tap(find.text(l10n.backupExportJson));
      await tester.pump();

      verify(
        () => cubit.exportJson(dialogTitle: l10n.backupExportSaveTitle),
      ).called(1);
    });

    testWidgets('tapping CSV calls exportCsv with the locale code', (
      tester,
    ) async {
      await pumpScreen(tester, const BackupIdle());
      final l10n = AppLocalizations.of(
        tester.element(find.byType(BackupScreen)),
      );

      await tester.tap(find.text(l10n.backupExportCsv));
      await tester.pump();

      verify(
        () => cubit.exportCsv(
          languageCode: 'pt',
          dialogTitle: l10n.backupExportSaveTitle,
        ),
      ).called(1);
    });

    testWidgets('the CSV code follows the English locale', (tester) async {
      await pumpScreen(tester, const BackupIdle(), locale: const Locale('en'));
      final l10n = AppLocalizations.of(
        tester.element(find.byType(BackupScreen)),
      );

      await tester.tap(find.text(l10n.backupExportCsv));
      await tester.pump();

      verify(
        () => cubit.exportCsv(
          languageCode: 'en',
          dialogTitle: l10n.backupExportSaveTitle,
        ),
      ).called(1);
    });

    testWidgets('Working disables both cards and shows the progress bar', (
      tester,
    ) async {
      await pumpScreen(tester, const BackupWorking());
      final l10n = AppLocalizations.of(
        tester.element(find.byType(BackupScreen)),
      );

      final cards = tester.widgetList<BackupActionCard>(
        find.byType(BackupActionCard),
      );
      expect(cards.every((c) => c.onPressed == null), isTrue);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text(l10n.backupWorking), findsOneWidget);

      await tester.tap(find.text(l10n.backupExportJson));
      await tester.pump();
      verifyNever(
        () => cubit.exportJson(dialogTitle: any(named: 'dialogTitle')),
      );
    });

    testWidgets('a Done state raises the snackbar and acknowledges', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const BackupIdle(),
        stream: Stream.value(const BackupExportDone(fileCount: 6, csv: true)),
      );
      await tester.pump();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(BackupScreen)),
      );

      expect(find.text(l10n.backupExportCsvDone(6)), findsOneWidget);
      verify(() => cubit.acknowledge()).called(1);
    });

    testWidgets('a Failed state shows the generic message only', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const BackupIdle(),
        stream: Stream.value(const BackupFailed(BackupFailure('secret'))),
      );
      await tester.pump();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(BackupScreen)),
      );

      expect(find.text(l10n.backupErrorGeneric), findsOneWidget);
      expect(find.text('secret'), findsNothing);
    });
  });
}
