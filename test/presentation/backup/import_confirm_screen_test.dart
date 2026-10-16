import 'package:agenda/application/backup/backup_cubit.dart';
import 'package:agenda/application/backup/backup_state.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/domain/backup/backup_entity.dart';
import 'package:agenda/domain/backup/import_preview.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/backup/screens/import_confirm_screen.dart';
import 'package:agenda/presentation/backup/widgets/backup_error_text.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBackupCubit extends MockCubit<BackupState> implements BackupCubit {}

ImportPreview _preview({
  ImportSource source = ImportSource.json,
  Set<BackupEntity>? replaced,
  int softDeleted = 0,
  int dangling = 0,
  DateTime? exportedAt,
}) {
  return ImportPreview(
    source: source,
    counts: const {BackupEntity.tasks: 3, BackupEntity.transactions: 12},
    softDeletedCount: softDeleted,
    earliest: DateTime(2026, 1, 5),
    latest: DateTime(2026, 9, 30),
    exportedAt: exportedAt,
    danglingLinks: dangling,
    replaced: replaced ?? BackupEntity.values.toSet(),
  );
}

void main() {
  late MockBackupCubit cubit;

  setUp(() {
    cubit = MockBackupCubit();
    when(() => cubit.confirmImport()).thenAnswer((_) async {});
    when(() => cubit.cancelImport()).thenReturn(null);
  });

  /// Pushes the confirm screen over a base route so pops are observable.
  Future<void> pumpScreen(
    WidgetTester tester,
    ImportPreview preview, {
    BackupState state = const BackupIdle(),
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
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder:
                              (_) => BlocProvider<BackupCubit>.value(
                                value: cubit,
                                child: ImportConfirmScreen(preview: preview),
                              ),
                        ),
                      ),
                  child: const Text('open'),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // Not pumpAndSettle: the Working state shows an endless progress bar.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ImportConfirmScreen)));

  group('ImportConfirmScreen', () {
    testWidgets('renders counts, date range, export date and deleted rows', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        _preview(softDeleted: 4, exportedAt: DateTime(2026, 10, 2)),
      );
      final l10n = l10nOf(tester);

      expect(find.text(l10n.backupConfirmTitle), findsOneWidget);
      expect(find.text(l10n.backupConfirmWarning), findsOneWidget);
      expect(
        find.text(l10n.backupCountLine(l10n.backupEntityTasks, 3)),
        findsOneWidget,
      );
      expect(
        find.text(l10n.backupCountLine(l10n.backupEntityTransactions, 12)),
        findsOneWidget,
      );
      expect(find.text('Registros de 05/01/2026 a 30/09/2026'), findsOneWidget);
      expect(find.text('Exportado em 02/10/2026'), findsOneWidget);
      expect(find.text(l10n.backupConfirmDeletedIncluded(4)), findsOneWidget);
      expect(find.text(l10n.backupConfirmWarningsTitle), findsNothing);
    });

    testWidgets('the partial note appears only for a CSV preview', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        _preview(
          source: ImportSource.csv,
          replaced: {BackupEntity.tasks, BackupEntity.transactions},
        ),
      );
      final l10n = l10nOf(tester);
      expect(find.text(l10n.backupConfirmPartial), findsOneWidget);
      // Entities the CSV did not supply are not listed.
      expect(
        find.text(l10n.backupCountLine(l10n.backupEntityGoals, 0)),
        findsNothing,
      );
    });

    testWidgets('a JSON preview has no partial note', (tester) async {
      await pumpScreen(tester, _preview());
      expect(find.text(l10nOf(tester).backupConfirmPartial), findsNothing);
    });

    testWidgets('the warning block appears only with dangling links', (
      tester,
    ) async {
      await pumpScreen(tester, _preview(dangling: 2));
      final l10n = l10nOf(tester);
      expect(find.text(l10n.backupConfirmWarningsTitle), findsOneWidget);
      expect(find.text(l10n.backupWarnDanglingLinks(2)), findsOneWidget);
    });

    testWidgets('confirm calls confirmImport', (tester) async {
      await pumpScreen(tester, _preview());
      await tester.tap(find.text(l10nOf(tester).backupConfirmButton));
      await tester.pump();
      verify(() => cubit.confirmImport()).called(1);
      verifyNever(() => cubit.cancelImport());
    });

    testWidgets('cancel discards the import once and pops', (tester) async {
      await pumpScreen(
        tester,
        _preview(),
        state: BackupImportPreviewReady(_preview()),
      );
      await tester.tap(find.text(l10nOf(tester).cancelButton));
      await tester.pumpAndSettle();
      verify(() => cubit.cancelImport()).called(1);
      expect(find.byType(ImportConfirmScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('Working disables both buttons and shows progress', (
      tester,
    ) async {
      await pumpScreen(tester, _preview(), state: const BackupWorking());
      final l10n = l10nOf(tester);
      expect(find.text(l10n.backupWorking), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final cancel = tester.widget<TextButton>(
        find.widgetWithText(TextButton, l10n.cancelButton),
      );
      final confirm = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, l10n.backupConfirmButton),
      );
      expect(cancel.onPressed, isNull);
      expect(confirm.onPressed, isNull);
    });

    testWidgets('pops on ImportDone and the following Idle pops nothing more', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        _preview(),
        stream: Stream.fromIterable([
          const BackupImportDone(
            ImportResult(counts: {}, safetyBackupPath: '/s.json'),
          ),
          const BackupIdle(),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ImportConfirmScreen), findsNothing);
      // The base route is still on screen: Idle did not pop it as well.
      expect(find.text('open'), findsOneWidget);
    });
  });

  group('backupErrorMessage', () {
    testWidgets('every code maps to a distinct non-empty message', (
      tester,
    ) async {
      await pumpScreen(tester, _preview());
      final l10n = l10nOf(tester);
      String msg(String code, {String? path}) => backupErrorMessage(
        l10n,
        BackupFailure('$code: secret detail'),
        safetyBackupPath: path,
      );

      final distinct = <String>{
        msg(ImportErrorCode.unsupported),
        msg(ImportErrorCode.tooLarge),
        msg(ImportErrorCode.newerVersion),
        msg(ImportErrorCode.mixed),
        msg(ImportErrorCode.duplicate),
        msg(ImportErrorCode.importFailed, path: '/p/safety.json'),
        backupErrorMessage(l10n, const BackupFailure('whatever')),
      };
      expect(distinct, hasLength(7));
      expect(distinct.every((m) => m.isNotEmpty), isTrue);
      expect(distinct.any((m) => m.contains('secret')), isFalse);
      expect(msg(ImportErrorCode.invalid), msg(ImportErrorCode.unsupported));
      expect(msg(ImportErrorCode.empty), msg(ImportErrorCode.unsupported));
    });

    testWidgets('importFailed shows the safety path, or generic without it', (
      tester,
    ) async {
      await pumpScreen(tester, _preview());
      final l10n = l10nOf(tester);
      const failure = BackupFailure('importFailed: x');

      expect(
        backupErrorMessage(l10n, failure, safetyBackupPath: '/p/safety.json'),
        contains('/p/safety.json'),
      );
      expect(backupErrorMessage(l10n, failure), l10n.backupErrorGeneric);
    });
  });
}
