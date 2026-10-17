import 'dart:async';

import 'package:agenda/application/backup/backup_cubit.dart';
import 'package:agenda/application/backup/backup_state.dart';
import 'package:agenda/application/backup/safety_backups_cubit.dart';
import 'package:agenda/application/backup/safety_backups_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/domain/backup/backup_entity.dart';
import 'package:agenda/domain/backup/import_preview.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/backup/widgets/safety_backups_section.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSafetyBackupsCubit extends MockCubit<SafetyBackupsState>
    implements SafetyBackupsCubit {}

class MockBackupCubit extends MockCubit<BackupState> implements BackupCubit {}

void main() {
  late MockSafetyBackupsCubit safety;
  late MockBackupCubit backup;
  late StreamController<SafetyBackupsState> safetyStream;
  late StreamController<BackupState> backupStream;

  Future<AppLocalizations> pumpSection(
    WidgetTester tester,
    SafetyBackupsState state,
  ) async {
    when(() => safety.state).thenReturn(state);
    whenListen(safety, safetyStream.stream, initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<BackupCubit>.value(
            value: backup,
            child: const SafetyBackupsSection(),
          ),
        ),
      ),
    );
    await tester.pump();
    return AppLocalizations.of(
      tester.element(find.byType(SafetyBackupsSection)),
    );
  }

  setUp(() {
    safety = MockSafetyBackupsCubit();
    backup = MockBackupCubit();
    safetyStream = StreamController<SafetyBackupsState>.broadcast();
    backupStream = StreamController<BackupState>.broadcast();
    when(() => safety.load()).thenAnswer((_) async {});
    when(() => safety.acknowledge()).thenReturn(null);
    when(() => safety.deleteAll()).thenAnswer((_) async {});
    when(
      () => safety.saveLatestCopy(dialogTitle: any(named: 'dialogTitle')),
    ).thenAnswer((_) async {});
    when(() => backup.state).thenReturn(const BackupIdle());
    whenListen(backup, backupStream.stream, initialState: const BackupIdle());
    getIt.registerFactory<SafetyBackupsCubit>(() => safety);
  });

  tearDown(() async {
    await safetyStream.close();
    await backupStream.close();
    await getIt.reset();
  });

  OutlinedButton saveButton(WidgetTester tester) =>
      tester.widget<OutlinedButton>(find.byKey(const Key('safetySave')));
  TextButton deleteButton(WidgetTester tester) =>
      tester.widget<TextButton>(find.byKey(const Key('safetyDelete')));

  testWidgets('shows the header, the count and loads once', (tester) async {
    final l10n = await pumpSection(
      tester,
      const SafetyBackupsState(count: 2),
    );

    expect(find.text(l10n.backupSafetyHeader), findsOneWidget);
    expect(find.text(l10n.backupSafetyDesc), findsOneWidget);
    expect(find.text(l10n.backupSafetyCount(2)), findsOneWidget);
    verify(() => safety.load()).called(1);
  });

  testWidgets('both buttons are disabled for count 0', (tester) async {
    await pumpSection(tester, const SafetyBackupsState());

    expect(saveButton(tester).onPressed, isNull);
    expect(deleteButton(tester).onPressed, isNull);
  });

  testWidgets('both buttons are disabled while busy', (tester) async {
    await pumpSection(tester, const SafetyBackupsState(count: 2, busy: true));

    expect(saveButton(tester).onPressed, isNull);
    expect(deleteButton(tester).onPressed, isNull);
  });

  testWidgets('save calls saveLatestCopy with the save dialog title', (
    tester,
  ) async {
    final l10n = await pumpSection(
      tester,
      const SafetyBackupsState(count: 1),
    );

    await tester.tap(find.byKey(const Key('safetySave')));
    await tester.pump();

    verify(
      () => safety.saveLatestCopy(dialogTitle: l10n.backupExportSaveTitle),
    ).called(1);
  });

  testWidgets('delete asks first, then deletes on confirm', (tester) async {
    final l10n = await pumpSection(
      tester,
      const SafetyBackupsState(count: 1),
    );

    await tester.tap(find.byKey(const Key('safetyDelete')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.backupSafetyDeleteTitle), findsOneWidget);
    expect(find.text(l10n.backupSafetyDeleteBody), findsOneWidget);
    verifyNever(() => safety.deleteAll());

    await tester.tap(
      find.widgetWithText(FilledButton, l10n.backupSafetyDeleteButton),
    );
    await tester.pumpAndSettle();

    verify(() => safety.deleteAll()).called(1);
  });

  testWidgets('cancelling the dialog deletes nothing', (tester) async {
    final l10n = await pumpSection(
      tester,
      const SafetyBackupsState(count: 1),
    );

    await tester.tap(find.byKey(const Key('safetyDelete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.cancelButton));
    await tester.pumpAndSettle();

    verifyNever(() => safety.deleteAll());
    expect(find.text(l10n.backupSafetyDeleteTitle), findsNothing);
  });

  group('outcomes', () {
    String? text(AppLocalizations l10n, SafetyBackupsOutcome o) => switch (o) {
      SafetyBackupsOutcome.saved => l10n.backupSafetySaved,
      SafetyBackupsOutcome.none => l10n.backupSafetyNone,
      SafetyBackupsOutcome.deleted => l10n.backupSafetyDeleted,
      SafetyBackupsOutcome.failed => l10n.backupSafetyFailed,
      SafetyBackupsOutcome.cancelled => null,
    };

    for (final outcome in SafetyBackupsOutcome.values) {
      testWidgets('$outcome is announced and acknowledged', (tester) async {
        final l10n = await pumpSection(
          tester,
          const SafetyBackupsState(count: 1),
        );

        safetyStream.add(SafetyBackupsState(count: 1, outcome: outcome));
        await tester.pump();
        await tester.pump();

        final message = text(l10n, outcome);
        if (message == null) {
          expect(find.byType(SnackBar), findsNothing);
        } else {
          expect(find.text(message), findsOneWidget);
        }
        verify(() => safety.acknowledge()).called(1);
      });
    }
  });

  testWidgets('an import result refreshes the count', (tester) async {
    await pumpSection(tester, const SafetyBackupsState(count: 1));

    backupStream.add(
      const BackupImportDone(
        ImportResult(counts: {BackupEntity.tasks: 1}, safetyBackupPath: '/s'),
      ),
    );
    await tester.pump();

    verify(() => safety.load()).called(2);
  });
}
