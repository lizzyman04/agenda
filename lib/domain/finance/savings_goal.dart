import 'package:agenda/domain/finance/savings_goal_contribution.dart';

/// Sentinel value used by [SavingsGoal.copyWith] to distinguish
/// "not provided" from "explicitly set to null" for nullable fields.
const Object clearField = _Absent();

final class _Absent {
  const _Absent();
}

/// Domain entity for a savings goal.
///
/// Progress is tracked via two paths (D-11):
/// 1. [contributions] — manual contribution entries on this goal.
/// 2. taggedTransactionsCents — sum passed from the caller (TransactionRepository
///    returns tagged transactions; caller aggregates and passes the sum).
///
/// Computed getters take [taggedTransactionsCents] as a parameter so the
/// domain stays pure — no repository calls inside this class.
///
/// Pure Dart — zero Flutter and zero Isar imports.
class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmountCents,
    required this.contributions,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.deadline,
    this.deletedAt,
  });

  /// Isar auto-increment id (0 for unsaved goals).
  final int id;

  /// Display title for the goal.
  final String title;

  /// Target amount in smallest currency unit (cents). Never double.
  final int targetAmountCents;

  /// List of manual contributions to this goal.
  final List<SavingsGoalContribution> contributions;

  /// True when the user has marked this goal as fully funded.
  final bool isCompleted;

  /// Optional target deadline.
  final DateTime? deadline;

  /// Non-null = soft-deleted. Excluded from active goal queries.
  final DateTime? deletedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Total amount saved = sum of manual contributions + tagged transactions.
  ///
  /// [taggedTransactionsCents] is the sum of amountCents of all active
  /// transactions where linkedGoalId == this.id (computed by the caller).
  int amountSavedCents(int taggedTransactionsCents) {
    final contributionsTotal = contributions.fold(
      0,
      (sum, c) => sum + c.amountCents,
    );
    return contributionsTotal + taggedTransactionsCents;
  }

  /// Progress ratio = amountSavedCents / targetAmountCents.
  ///
  /// Returns 0.0 when [targetAmountCents] is 0 (avoids division by zero).
  /// Can exceed 1.0 — no cap at domain layer; UI layer is responsible
  /// for clamping the display value.
  double progressPercent(int taggedTransactionsCents) {
    if (targetAmountCents == 0) return 0.0;
    return amountSavedCents(taggedTransactionsCents) / targetAmountCents;
  }

  /// Returns a copy with the specified fields replaced.
  SavingsGoal copyWith({
    int? id,
    String? title,
    int? targetAmountCents,
    List<SavingsGoalContribution>? contributions,
    bool? isCompleted,
    Object? deadline = clearField,
    Object? deletedAt = clearField,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmountCents: targetAmountCents ?? this.targetAmountCents,
      contributions: contributions ?? this.contributions,
      isCompleted: isCompleted ?? this.isCompleted,
      deadline: deadline is _Absent ? this.deadline : deadline as DateTime?,
      deletedAt: deletedAt is _Absent ? this.deletedAt : deletedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
