import 'package:agenda/domain/finance/debt_direction.dart';

/// Sentinel value used by [Debt.copyWith] to distinguish
/// "not provided" from "explicitly set to null" for nullable fields.
const Object clearField = _Absent();

final class _Absent {
  const _Absent();
}

/// Domain entity representing a debt (to pay or to receive).
///
/// D-07: Used in net worth calculation — only toPay + !isPaid debts
/// are subtracted from net worth. toReceive debts are displayed
/// on the debt screen but excluded from the net worth formula.
///
/// Pure Dart — zero Flutter and zero Isar imports.
class Debt {
  const Debt({
    required this.id,
    required this.title,
    required this.amountCents,
    required this.direction,
    required this.counterparty,
    required this.dueDate,
    required this.isPaid,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
    this.deletedAt,
  });

  /// Isar auto-increment id (0 for unsaved debts).
  final int id;

  /// Display label for the debt (e.g. "Aluguel Janeiro").
  final String title;

  /// Debt amount in smallest currency unit (cents). Never double.
  final int amountCents;

  /// Whether the user owes (toPay) or is owed (toReceive).
  final DebtDirection direction;

  /// Name of the other party (creditor or debtor).
  final String counterparty;

  /// Due date for payment or receipt.
  final DateTime dueDate;

  /// True when this debt has been settled.
  final bool isPaid;

  /// Timestamp when isPaid was set to true. Null if not yet paid.
  final DateTime? paidAt;

  /// Non-null = soft-deleted. Excluded from active debt queries.
  final DateTime? deletedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns a copy with the specified fields replaced.
  Debt copyWith({
    int? id,
    String? title,
    int? amountCents,
    DebtDirection? direction,
    String? counterparty,
    DateTime? dueDate,
    bool? isPaid,
    Object? paidAt = clearField,
    Object? deletedAt = clearField,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Debt(
      id: id ?? this.id,
      title: title ?? this.title,
      amountCents: amountCents ?? this.amountCents,
      direction: direction ?? this.direction,
      counterparty: counterparty ?? this.counterparty,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt is _Absent ? this.paidAt : paidAt as DateTime?,
      deletedAt: deletedAt is _Absent ? this.deletedAt : deletedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
