import 'dart:typed_data';

import 'package:agenda/application/backup/backup_cubit.dart';
import 'package:agenda/application/backup/backup_state.dart';
import 'package:agenda/application/notifications/budget_alert_evaluator.dart';
import 'package:agenda/application/notifications/goal_alert_evaluator.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/backup/backup_entity.dart';
import 'package:agenda/domain/backup/backup_file.dart';
import 'package:agenda/domain/backup/backup_file_gateway.dart';
import 'package:agenda/domain/backup/backup_repository.dart';
import 'package:agenda/domain/backup/import_preview.dart';
import 'package:agenda/domain/notifications/notification_reconciler.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockBackupRepository extends Mock implements BackupRepository {}

class MockBackupFileGateway extends Mock implements BackupFileGateway {}

class MockBudgetAlertEvaluator extends Mock implements BudgetAlertEvaluator {}

class MockGoalAlertEvaluator extends Mock implements GoalAlertEvaluator {}

class MockNotificationReconciler extends Mock
    implements NotificationReconciler {}

BackupFile _file(String name) =>
    BackupFile(name: name, bytes: Uint8List.fromList([1, 2, 3]));

const _preview = ImportPreview(
  source: ImportSource.json,
  counts: {BackupEntity.tasks: 2},
  softDeletedCount: 0,
  earliest: null,
  latest: null,
  exportedAt: null,
  danglingLinks: 0,
  replaced: {BackupEntity.tasks},
);

const _result = ImportResult(
  counts: {BackupEntity.tasks: 2},
  safetyBackupPath: '/safety/backup.json',
);

void main() {
  late MockBackupRepository repository;
  late MockBackupFileGateway gateway;
  late MockBudgetAlertEvaluator budget;
  late MockGoalAlertEvaluator goals;
  late MockNotificationReconciler reconciler;

  setUpAll(() {
    registerFallbackValue(ReconcileReason.afterImport);
    registerFallbackValue(<BackupFile>[]);
  });

  setUp(() {
    repository = MockBackupRepository();
    gateway = MockBackupFileGateway();
    budget = MockBudgetAlertEvaluator();
    goals = MockGoalAlertEvaluator();
    reconciler = MockNotificationReconciler();
    when(() => budget.reseedAfterImport()).thenAnswer((_) async {});
    when(() => goals.reseedAfterImport()).thenAnswer((_) async {});
    when(() => reconciler.reconcileNow(any())).thenAnswer((_) async {});
    when(() => repository.discardImport()).thenReturn(null);
    when(
      () => repository.lastSafetyBackupPath,
    ).thenReturn('/safety/backup.json');
  });

  BackupCubit build() =>
      BackupCubit(repository, gateway, budget, goals, reconciler);

  void picked(Result<List<BackupFile>?> result) {
    when(
      () => gateway.pickFiles(dialogTitle: any(named: 'dialogTitle')),
    ).thenAnswer((_) async => result);
  }

  group('BackupCubit.pickAndPrepareImport', () {
    blocTest<BackupCubit, BackupState>(
      'a cancelled picker emits Working then Idle',
      build: () {
        picked(const Success(null));
        return build();
      },
      act: (cubit) => cubit.pickAndPrepareImport(dialogTitle: 'Pick'),
      expect: () => [const BackupWorking(), const BackupIdle()],
      verify: (_) => verifyNever(() => repository.prepareImport(any())),
    );

    blocTest<BackupCubit, BackupState>(
      'a valid file emits Working then PreviewReady',
      build: () {
        picked(Success([_file('b.json')]));
        when(
          () => repository.prepareImport(any()),
        ).thenAnswer((_) async => const Success(_preview));
        return build();
      },
      act: (cubit) => cubit.pickAndPrepareImport(dialogTitle: 'Pick'),
      expect:
          () => [
            const BackupWorking(),
            const BackupImportPreviewReady(_preview),
          ],
    );

    blocTest<BackupCubit, BackupState>(
      'a prepare Err emits Working then Failed',
      build: () {
        picked(Success([_file('b.json')]));
        when(() => repository.prepareImport(any())).thenAnswer(
          (_) async => const Err(BackupFailure('unsupported: x')),
        );
        return build();
      },
      act: (cubit) => cubit.pickAndPrepareImport(dialogTitle: 'Pick'),
      expect: () => [const BackupWorking(), isA<BackupFailed>()],
    );

    blocTest<BackupCubit, BackupState>(
      'a picker Err emits Working then Failed and prepares nothing',
      build: () {
        picked(const Err(BackupFailure('tooLarge: x')));
        return build();
      },
      act: (cubit) => cubit.pickAndPrepareImport(dialogTitle: 'Pick'),
      expect: () => [const BackupWorking(), isA<BackupFailed>()],
      verify: (_) => verifyNever(() => repository.prepareImport(any())),
    );
  });

  group('BackupCubit.confirmImport', () {
    blocTest<BackupCubit, BackupState>(
      'commits, runs the hooks in order and emits Done',
      build: () {
        when(
          () => repository.commitImport(),
        ).thenAnswer((_) async => const Success(_result));
        return build();
      },
      seed: () => const BackupImportPreviewReady(_preview),
      act: (cubit) => cubit.confirmImport(),
      expect: () => [const BackupWorking(), const BackupImportDone(_result)],
      verify: (_) {
        verifyInOrder([
          () => repository.commitImport(),
          () => budget.reseedAfterImport(),
          () => goals.reseedAfterImport(),
          () => reconciler.reconcileNow(ReconcileReason.afterImport),
        ]);
      },
    );

    blocTest<BackupCubit, BackupState>(
      'a commit Err emits ImportFailed with the safety path and skips hooks',
      build: () {
        when(() => repository.commitImport()).thenAnswer(
          (_) async => const Err(BackupFailure('importFailed: x')),
        );
        return build();
      },
      seed: () => const BackupImportPreviewReady(_preview),
      act: (cubit) => cubit.confirmImport(),
      expect:
          () => [
            const BackupWorking(),
            const BackupImportFailed(
              BackupFailure('importFailed: x'),
              '/safety/backup.json',
            ),
          ],
      verify: (_) {
        verifyNever(() => budget.reseedAfterImport());
        verifyNever(() => goals.reseedAfterImport());
        verifyNever(() => reconciler.reconcileNow(any()));
      },
    );

    blocTest<BackupCubit, BackupState>(
      'a throwing hook still yields Done and later hooks still run',
      build: () {
        when(
          () => repository.commitImport(),
        ).thenAnswer((_) async => const Success(_result));
        when(() => budget.reseedAfterImport()).thenThrow(StateError('boom'));
        when(() => goals.reseedAfterImport()).thenAnswer((_) async {
          throw StateError('async boom');
        });
        return build();
      },
      seed: () => const BackupImportPreviewReady(_preview),
      act: (cubit) => cubit.confirmImport(),
      expect: () => [const BackupWorking(), const BackupImportDone(_result)],
      verify:
          (_) => verify(
            () => reconciler.reconcileNow(ReconcileReason.afterImport),
          ).called(1),
    );

    blocTest<BackupCubit, BackupState>(
      'from Idle it does nothing',
      build: build,
      act: (cubit) => cubit.confirmImport(),
      expect: () => <BackupState>[],
      verify: (_) => verifyNever(() => repository.commitImport()),
    );
  });

  group('BackupCubit.cancelImport', () {
    blocTest<BackupCubit, BackupState>(
      'discards the prepared import and emits Idle',
      build: build,
      seed: () => const BackupImportPreviewReady(_preview),
      act: (cubit) => cubit.cancelImport(),
      expect: () => [const BackupIdle()],
      verify: (_) => verify(() => repository.discardImport()).called(1),
    );
  });
}
