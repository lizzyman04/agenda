import 'package:agenda/data/database/isar_service.dart';
import 'package:agenda/data/tasks/item_model.dart';
import 'package:isar_community/isar.dart';

/// Raw, whole-collection Isar reads used to build a backup.
///
/// Every read here is DELIBERATELY uncapped and unfiltered: a backup must
/// contain every row, including soft-deleted ones, so foreign keys such as
/// `parentId`, `linkedGoalId` and `categoryId` stay valid after a restore.
/// Adding `.limit(...)` or a `deletedAt` filter would silently truncate a
/// user's backup. That is the CR-04 / BL-01 defect class this project has
/// already been burned by twice. Never add either.
class BackupDao {
  const BackupDao(this.isarService);

  /// Public so the import engine can open its own write transaction against
  /// the same database without changing the DI graph.
  final IsarService isarService;

  /// Returns EVERY item, soft-deleted included.
  Future<List<ItemModel>> readItems() async =>
      isarService.db.collection<ItemModel>().where().findAll();
}
