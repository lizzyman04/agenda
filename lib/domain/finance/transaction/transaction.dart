import 'package:agenda/domain/finance/transaction_type.dart';

/// Sentinel value used by [Transaction.copyWith] to distinguish
/// "not provided" from "explicitly set to null" for nullable fields.
///
/// Pass [clearField] as the named argument to explicitly null out a field:
/// ```dart
/// tx.copyWith(note: clearField); // sets note to null
/// tx.copyWith(note: 'text');     // sets note to 'text'
/// tx.copyWith();                 // keeps existing note
/// ```
const Object clearField = _Absent();

final class _Absent {
  const _Absent();
}

/// Domain entity representing a financial transaction (income or expense).
///
/// Money is stored as [amountCents] (int), never as double — prevents
/// floating-point precision loss in financial arithmetic.
///
/// Pure Dart — zero Flutter and zero Isar imports.
/// The Isar model (TransactionModel) and mapper live in the data layer.
class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.categoryId,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.linkedGoalId,
    this.deletedAt,
  });

  /// Isar auto-increment id (0 for unsaved transactions).
  final int id;

  /// Discriminates income vs expense (D-01, D-02).
  final TransactionType type;

  /// Amount in the smallest currency unit (cents). Never a double.
  /// Example: MT 123.45 → amountCents = 12345.
  final int amountCents;

  /// FK to TransactionCategory.id.
  final int categoryId;

  /// The date this transaction occurred.
  final DateTime date;

  /// Optional descriptive note.
  final String? note;

  /// Optional FK to SavingsGoal.id — enables D-11 goal contribution tracking.
  final int? linkedGoalId;

  /// Non-null = soft-deleted. Excluded from all active queries.
  final DateTime? deletedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns a copy with the specified fields replaced.
  ///
  /// Nullable fields use the [clearField] sentinel to distinguish
  /// "not provided" (keep existing value) from "explicitly set to null".
  Transaction copyWith({
    int? id,
    TransactionType? type,
    int? amountCents,
    int? categoryId,
    DateTime? date,
    Object? note = clearField,
    Object? linkedGoalId = clearField,
    Object? deletedAt = clearField,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amountCents: amountCents ?? this.amountCents,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note is _Absent ? this.note : note as String?,
      linkedGoalId:
          linkedGoalId is _Absent ? this.linkedGoalId : linkedGoalId as int?,
      deletedAt: deletedAt is _Absent ? this.deletedAt : deletedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
