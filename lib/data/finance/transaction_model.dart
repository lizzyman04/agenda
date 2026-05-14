import 'package:isar_community/isar.dart';

part 'transaction_model.g.dart';

/// Isar-layer enum for transaction type.
///
/// Persisted as string via @Enumerated(EnumType.name) — safe to reorder.
/// Maps to domain TransactionType via TransactionMapper.
enum TransactionType { income, expense }

/// Isar @Collection for financial transactions (income and expense).
///
/// amountCents is an int — never a double — to prevent floating-point
/// precision loss in monetary arithmetic.
@Collection()
class TransactionModel {
  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.name)
  late TransactionType type;

  /// Amount in smallest currency unit (cents). MT 12.34 → 1234.
  late int amountCents;

  /// FK to TransactionCategoryModel.id.
  @Index()
  late int categoryId;

  /// Date of the transaction. Indexed for monthly range queries.
  @Index()
  late DateTime date;

  /// Optional descriptive note.
  String? note;

  /// Optional FK to SavingsGoalModel.id (D-11).
  int? linkedGoalId;

  /// Soft delete — non-null means this record is deleted.
  @Index()
  DateTime? deletedAt;

  late DateTime createdAt;
  late DateTime updatedAt;
}
