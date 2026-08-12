import 'package:agenda/domain/finance/recurring/recurring_cycle.dart';

/// Sentinel value used by [RecurringPayment.copyWith] to distinguish
/// "not provided" from "explicitly set to null" for nullable fields.
const Object clearField = _Absent();

final class _Absent {
  const _Absent();
}

/// Domain entity for a recurring payment (subscription, bill, etc.).
///
/// The [nextDueDate] tracks when the next payment is due and is advanced
/// by the application layer after each payment is logged.
///
/// Pure Dart — zero Flutter and zero Isar imports.
class RecurringPayment {
  const RecurringPayment({
    required this.id,
    required this.title,
    required this.amountCents,
    required this.categoryId,
    required this.cycle,
    required this.nextDueDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Isar auto-increment id (0 for unsaved payments).
  final int id;

  /// Display label for the recurring payment (e.g. "Netflix").
  final String title;

  /// Payment amount in smallest currency unit (cents). Never double.
  final int amountCents;

  /// FK to TransactionCategory.id.
  final int categoryId;

  /// Recurrence cycle (daily, weekly, monthly, etc.).
  final RecurringCycle cycle;

  /// Date of the next expected payment.
  final DateTime nextDueDate;

  /// False when the user has paused or cancelled this recurring payment.
  final bool isActive;

  /// Non-null = soft-deleted. Excluded from active payment queries.
  final DateTime? deletedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns a copy with the specified fields replaced.
  RecurringPayment copyWith({
    int? id,
    String? title,
    int? amountCents,
    int? categoryId,
    RecurringCycle? cycle,
    DateTime? nextDueDate,
    bool? isActive,
    Object? deletedAt = clearField,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringPayment(
      id: id ?? this.id,
      title: title ?? this.title,
      amountCents: amountCents ?? this.amountCents,
      categoryId: categoryId ?? this.categoryId,
      cycle: cycle ?? this.cycle,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
      deletedAt: deletedAt is _Absent ? this.deletedAt : deletedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
