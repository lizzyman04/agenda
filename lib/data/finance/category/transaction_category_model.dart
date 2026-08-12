import 'package:agenda/data/finance/transaction/transaction_model.dart';
import 'package:isar_community/isar.dart';

part 'transaction_category_model.g.dart';

/// Isar @Collection for transaction categories.
///
/// Categories are either system-default (isDefault = true) or user-defined.
/// Default categories are seeded by MigrationRunner case 3.
///
/// NO deletedAt — categories are either hard-deleted (custom) or
/// undeletable (default). No soft delete for this collection.
@Collection()
class TransactionCategoryModel {
  Id id = Isar.autoIncrement;

  /// Display name in Portuguese (PT-BR). Used for both default and custom.
  late String namePtBr;

  /// Optional English display name. Populated for default categories only.
  String? nameEn;

  /// Discriminates income vs expense categories (D-02).
  @Enumerated(EnumType.name)
  late TransactionType type;

  /// True for seeded default categories — cannot be deleted or renamed (D-03).
  bool isDefault = false;

  late DateTime createdAt;
}
