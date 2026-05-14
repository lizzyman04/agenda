import 'package:agenda/core/config/app_config.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/data/finance/transaction_category_model.dart';
import 'package:agenda/data/finance/transaction_model.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sequential schema migration runner.
///
/// Design (D-16):
/// - [AppConfig.schemaVersion] is the target — bump it when a new migration
///   block is added here.
/// - The current version is stored in [SharedPreferences] under
///   [StorageKeys.schemaVersion] — readable BEFORE Isar opens.
/// - [run] is called inside IsarService.open on every cold start.
/// - Migrations execute once in ascending order; each successful run writes
///   the new version to prefs before executing the next block.
class MigrationRunner {
  MigrationRunner._();

  /// Runs all pending migrations from current+1 up to
  /// [AppConfig.schemaVersion].
  ///
  /// No-op when the stored version is already current.
  static Future<void> run(Isar isar, SharedPreferences prefs) async {
    final current = prefs.getInt(StorageKeys.schemaVersion) ?? 0;
    const target = AppConfig.schemaVersion;

    if (current >= target) return;

    for (var v = current + 1; v <= target; v++) {
      await _runMigration(isar, v);
      await prefs.setInt(StorageKeys.schemaVersion, v);
    }
  }

  static Future<void> _runMigration(Isar isar, int toVersion) async {
    switch (toVersion) {
      case 1:
        // Initial schema — no data migration needed.
        return;
      case 2:
        // Add ItemModel collection (tasks, projects, subtasks).
        // No data migration needed — new empty collection.
        return;
      case 3:
        // Finance collections added. Seed default TransactionCategories (D-04, D-05).
        await _seedDefaultCategories(isar);
        return;
    }
  }

  /// Seeds the 13 default transaction categories (D-04, D-05, D-06).
  ///
  /// Idempotency guard: if any categories already exist, skip seeding.
  /// This prevents double-seeding on repeated launches or test scenarios.
  static Future<void> _seedDefaultCategories(Isar isar) async {
    final count =
        await isar.collection<TransactionCategoryModel>().count();
    if (count > 0) return;

    final now = DateTime.now();

    // D-04: 9 default expense categories
    final expenseData = [
      ('Alimentação', 'Food'),
      ('Transporte', 'Transport'),
      ('Moradia', 'Housing'),
      ('Saúde', 'Health'),
      ('Educação', 'Education'),
      ('Lazer', 'Leisure'),
      ('Roupas', 'Clothing'),
      ('Tecnologia', 'Technology'),
      ('Outros', 'Other'),
    ];

    // D-05: 4 default income categories
    final incomeData = [
      ('Salário', 'Salary'),
      ('Freelance', 'Freelance'),
      ('Investimentos', 'Investments'),
      ('Outros', 'Other'),
    ];

    final models = [
      ...expenseData.map(
        (pair) => TransactionCategoryModel()
          ..namePtBr = pair.$1
          ..nameEn = pair.$2
          ..type = TransactionType.expense
          ..isDefault = true
          ..createdAt = now,
      ),
      ...incomeData.map(
        (pair) => TransactionCategoryModel()
          ..namePtBr = pair.$1
          ..nameEn = pair.$2
          ..type = TransactionType.income
          ..isDefault = true
          ..createdAt = now,
      ),
    ];

    await isar.writeTxn(
      () => isar.collection<TransactionCategoryModel>().putAll(models),
    );
  }
}
