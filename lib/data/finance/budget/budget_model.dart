import 'package:isar_community/isar.dart';

part 'budget_model.g.dart';

/// Isar @Collection for monthly category budgets.
///
/// One record per (categoryId, month, year) — enforced by composite unique
/// index. BudgetRepositoryImpl uses upsert semantics via setLimit().
@Collection()
class BudgetModel {
  Id id = Isar.autoIncrement;

  /// FK to TransactionCategoryModel.id.
  @Index()
  late int categoryId;

  /// Composite unique index: one budget per (month, year, categoryId).
  @Index(
    composite: [CompositeIndex('year'), CompositeIndex('categoryId')],
    unique: true,
  )
  late int month; // 1-12

  late int year; // e.g. 2026

  /// Monthly spend limit in smallest currency unit (cents).
  late int limitCents;

  late DateTime createdAt;
  late DateTime updatedAt;
}
