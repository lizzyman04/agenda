import 'package:agenda/data/backup/dao/backup_dao.dart';
import 'package:agenda/data/database/isar_service.dart';
import 'package:injectable/injectable.dart';

/// DI registrations for the Backup domain.
///
/// [BackupDao] is a plain class (no annotation on it), registered here.
/// `BackupRepositoryImpl` self-registers via `@LazySingleton(as: ...)`.
@module
abstract class BackupModule {
  @lazySingleton
  BackupDao backupDao(IsarService isarService) => BackupDao(isarService);
}
