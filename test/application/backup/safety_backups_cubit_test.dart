// SafetyBackupsCubit (plan 04-20, WR-04): count, save the latest copy through
// the system save dialog, delete all.

import 'dart:typed_data';

import 'package:agenda/application/backup/safety_backups_cubit.dart';
import 'package:agenda/application/backup/safety_backups_state.dart';
import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/backup/backup_file.dart';
import 'package:agenda/domain/backup/backup_file_gateway.dart';
import 'package:agenda/domain/backup/backup_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockBackupRepository extends Mock implements BackupRepository {}

class MockBackupFileGateway extends Mock implements BackupFileGateway {}

BackupFile _file() => BackupFile(
  name: 'safety-backup-20261016-090000.json',
  bytes: Uint8List.fromList([1, 2, 3]),
);

void main() {
  late MockBackupRepository repository;
  late MockBackupFileGateway gateway;

  setUpAll(() {
    registerFallbackValue(_file());
  });

  setUp(() {
    repository = MockBackupRepository();
    gateway = MockBackupFileGateway();
  });

  SafetyBackupsCubit build() => SafetyBackupsCubit(repository, gateway);

  void stubCount(int count) => when(
    () => repository.safetyBackupCount(),
  ).thenAnswer((_) async => Success(count));

  group('load', () {
    blocTest<SafetyBackupsCubit, SafetyBackupsState>(
      'emits the repository count',
      build: () {
        stubCount(2);
        return build();
      },
      act: (c) => c.load(),
      expect: () => [const SafetyBackupsState(count: 2)],
    );

    blocTest<SafetyBackupsCubit, SafetyBackupsState>(
      'a repository error keeps the previous count and sets no outcome',
      build: () {
        when(() => repository.safetyBackupCount()).thenAnswer(
          (_) async => const Err(BackupFailure('safetyBackupCount failed')),
        );
        return build();
      },
      seed: () => const SafetyBackupsState(count: 3),
      act: (c) => c.load(),
      expect: () => <SafetyBackupsState>[],
    );
  });

  group('saveLatestCopy', () {
    blocTest<SafetyBackupsCubit, SafetyBackupsState>(
      'saves the newest copy through the save dialog',
      build: () {
        when(
          () => repository.latestSafetyBackup(),
        ).thenAnswer((_) async => Success(_file()));
        when(
          () => gateway.saveFile(
            dialogTitle: any(named: 'dialogTitle'),
            file: any(named: 'file'),
          ),
        ).thenAnswer((_) async => const Success(true));
        return build();
      },
      seed: () => const SafetyBackupsState(count: 1),
      act: (c) => c.saveLatestCopy(dialogTitle: 'Save'),
      expect:
          () => [
            const SafetyBackupsState(count: 1, busy: true),
            const SafetyBackupsState(
              count: 1,
              outcome: SafetyBackupsOutcome.saved,
            ),
          ],
      verify:
          (_) => verify(
            () =>
                gateway.saveFile(dialogTitle: 'Save', file: any(named: 'file')),
          ).called(1),
    );

    blocTest<SafetyBackupsCubit, SafetyBackupsState>(
      'no safety backup: outcome none and the gateway is never called',
      build: () {
        when(
          () => repository.latestSafetyBackup(),
        ).thenAnswer((_) async => const Success(null));
        return build();
      },
      act: (c) => c.saveLatestCopy(dialogTitle: 'Save'),
      expect:
          () => [
            const SafetyBackupsState(busy: true),
            const SafetyBackupsState(outcome: SafetyBackupsOutcome.none),
          ],
      verify:
          (_) => verifyNever(
            () => gateway.saveFile(
              dialogTitle: any(named: 'dialogTitle'),
              file: any(named: 'file'),
            ),
          ),
    );

    blocTest<SafetyBackupsCubit, SafetyBackupsState>(
      'a cancelled dialog is outcome cancelled',
      build: () {
        when(
          () => repository.latestSafetyBackup(),
        ).thenAnswer((_) async => Success(_file()));
        when(
          () => gateway.saveFile(
            dialogTitle: any(named: 'dialogTitle'),
            file: any(named: 'file'),
          ),
        ).thenAnswer((_) async => const Success(false));
        return build();
      },
      act: (c) => c.saveLatestCopy(dialogTitle: 'Save'),
      expect:
          () => [
            const SafetyBackupsState(busy: true),
            const SafetyBackupsState(outcome: SafetyBackupsOutcome.cancelled),
          ],
    );

    blocTest<SafetyBackupsCubit, SafetyBackupsState>(
      'a repository error is outcome failed',
      build: () {
        when(() => repository.latestSafetyBackup()).thenAnswer(
          (_) async => const Err(BackupFailure('latestSafetyBackup failed')),
        );
        return build();
      },
      act: (c) => c.saveLatestCopy(dialogTitle: 'Save'),
      expect:
          () => [
            const SafetyBackupsState(busy: true),
            const SafetyBackupsState(outcome: SafetyBackupsOutcome.failed),
          ],
    );

    blocTest<SafetyBackupsCubit, SafetyBackupsState>(
      'a gateway error is outcome failed',
      build: () {
        when(
          () => repository.latestSafetyBackup(),
        ).thenAnswer((_) async => Success(_file()));
        when(
          () => gateway.saveFile(
            dialogTitle: any(named: 'dialogTitle'),
            file: any(named: 'file'),
          ),
        ).thenAnswer((_) async => const Err(BackupFailure('saveFile failed')));
        return build();
      },
      act: (c) => c.saveLatestCopy(dialogTitle: 'Save'),
      expect:
          () => [
            const SafetyBackupsState(busy: true),
            const SafetyBackupsState(outcome: SafetyBackupsOutcome.failed),
          ],
    );

    blocTest<SafetyBackupsCubit, SafetyBackupsState>(
      'a call while busy is ignored',
      build: build,
      seed: () => const SafetyBackupsState(count: 1, busy: true),
      act: (c) => c.saveLatestCopy(dialogTitle: 'Save'),
      expect: () => <SafetyBackupsState>[],
      verify: (_) => verifyNever(() => repository.latestSafetyBackup()),
    );
  });

  group('deleteAll', () {
    blocTest<SafetyBackupsCubit, SafetyBackupsState>(
      'success resets the count and reports deleted',
      build: () {
        when(
          () => repository.deleteSafetyBackups(),
        ).thenAnswer((_) async => const Success(3));
        return build();
      },
      seed: () => const SafetyBackupsState(count: 3),
      act: (c) => c.deleteAll(),
      expect:
          () => [
            const SafetyBackupsState(count: 3, busy: true),
            const SafetyBackupsState(outcome: SafetyBackupsOutcome.deleted),
          ],
    );

    blocTest<SafetyBackupsCubit, SafetyBackupsState>(
      'an error reports failed and re-reads the count',
      build: () {
        when(() => repository.deleteSafetyBackups()).thenAnswer(
          (_) async => const Err(BackupFailure('deleteSafetyBackups failed')),
        );
        stubCount(2);
        return build();
      },
      seed: () => const SafetyBackupsState(count: 3),
      act: (c) => c.deleteAll(),
      expect:
          () => [
            const SafetyBackupsState(count: 3, busy: true),
            const SafetyBackupsState(
              count: 2,
              outcome: SafetyBackupsOutcome.failed,
            ),
          ],
    );

    blocTest<SafetyBackupsCubit, SafetyBackupsState>(
      'a call while busy is ignored',
      build: build,
      seed: () => const SafetyBackupsState(count: 1, busy: true),
      act: (c) => c.deleteAll(),
      expect: () => <SafetyBackupsState>[],
      verify: (_) => verifyNever(() => repository.deleteSafetyBackups()),
    );
  });

  blocTest<SafetyBackupsCubit, SafetyBackupsState>(
    'acknowledge clears the outcome and nothing else',
    build: build,
    seed:
        () => const SafetyBackupsState(
          count: 2,
          outcome: SafetyBackupsOutcome.saved,
        ),
    act: (c) => c.acknowledge(),
    expect: () => [const SafetyBackupsState(count: 2)],
  );
}
