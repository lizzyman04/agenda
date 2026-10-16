import 'dart:typed_data';

import 'package:agenda/application/backup/backup_cubit.dart';
import 'package:agenda/application/backup/backup_state.dart';
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

BackupFile _file(String name) =>
    BackupFile(name: name, bytes: Uint8List.fromList([1, 2, 3]));

void main() {
  late MockBackupRepository repository;
  late MockBackupFileGateway gateway;

  setUpAll(() {
    registerFallbackValue(_file('fallback'));
  });

  setUp(() {
    repository = MockBackupRepository();
    gateway = MockBackupFileGateway();
  });

  BackupCubit build() => BackupCubit(repository, gateway);

  group('BackupCubit.exportJson', () {
    blocTest<BackupCubit, BackupState>(
      'saves the JSON file and emits Working then Done(1, false)',
      build: () {
        when(
          () => repository.exportJson(),
        ).thenAnswer((_) async => Success(_file('b.json')));
        when(
          () => gateway.saveFile(
            dialogTitle: any(named: 'dialogTitle'),
            file: any(named: 'file'),
          ),
        ).thenAnswer((_) async => const Success(true));
        return build();
      },
      act: (cubit) => cubit.exportJson(dialogTitle: 'Save'),
      expect:
          () => [
            const BackupWorking(),
            const BackupExportDone(fileCount: 1, csv: false),
          ],
    );

    blocTest<BackupCubit, BackupState>(
      'a cancelled dialog emits Working then Cancelled(0)',
      build: () {
        when(
          () => repository.exportJson(),
        ).thenAnswer((_) async => Success(_file('b.json')));
        when(
          () => gateway.saveFile(
            dialogTitle: any(named: 'dialogTitle'),
            file: any(named: 'file'),
          ),
        ).thenAnswer((_) async => const Success(false));
        return build();
      },
      act: (cubit) => cubit.exportJson(dialogTitle: 'Save'),
      expect: () => [const BackupWorking(), const BackupExportCancelled(0)],
    );

    blocTest<BackupCubit, BackupState>(
      'a repository Err emits Working then Failed and never opens a dialog',
      build: () {
        when(
          () => repository.exportJson(),
        ).thenAnswer((_) async => const Err(BackupFailure('boom')));
        return build();
      },
      act: (cubit) => cubit.exportJson(dialogTitle: 'Save'),
      expect: () => [const BackupWorking(), isA<BackupFailed>()],
      verify: (_) {
        verifyNever(
          () => gateway.saveFile(
            dialogTitle: any(named: 'dialogTitle'),
            file: any(named: 'file'),
          ),
        );
      },
    );

    blocTest<BackupCubit, BackupState>(
      'a gateway Err emits Working then Failed',
      build: () {
        when(
          () => repository.exportJson(),
        ).thenAnswer((_) async => Success(_file('b.json')));
        when(
          () => gateway.saveFile(
            dialogTitle: any(named: 'dialogTitle'),
            file: any(named: 'file'),
          ),
        ).thenAnswer((_) async => const Err(BackupFailure('saveFailed')));
        return build();
      },
      act: (cubit) => cubit.exportJson(dialogTitle: 'Save'),
      expect: () => [const BackupWorking(), isA<BackupFailed>()],
    );

    blocTest<BackupCubit, BackupState>(
      'acknowledge returns to Idle',
      build: build,
      seed: () => const BackupExportCancelled(0),
      act: (cubit) => cubit.acknowledge(),
      expect: () => [const BackupIdle()],
    );
  });
}
