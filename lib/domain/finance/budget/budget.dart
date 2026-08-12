/// Domain entity for a monthly budget limit on a transaction category.
///
/// Each budget applies to one category for one calendar month.
/// Budget limits are set per category per month — not annual rolling.
///
/// Pure Dart — zero Flutter and zero Isar imports.
class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.limitCents,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Isar auto-increment id (0 for unsaved budgets).
  final int id;

  /// FK to TransactionCategory.id.
  final int categoryId;

  /// Calendar month (1-12).
  final int month;

  /// Calendar year (e.g. 2026).
  final int year;

  /// Monthly spend limit in smallest currency unit (cents). Never double.
  final int limitCents;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns a copy with the specified fields replaced.
  Budget copyWith({
    int? id,
    int? categoryId,
    int? month,
    int? year,
    int? limitCents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      month: month ?? this.month,
      year: year ?? this.year,
      limitCents: limitCents ?? this.limitCents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
