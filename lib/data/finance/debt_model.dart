import 'package:isar_community/isar.dart';

part 'debt_model.g.dart';

/// Isar-layer enum for debt direction.
///
/// Persisted as string via @Enumerated(EnumType.name) — safe to reorder.
/// Maps to domain DebtDirection via DebtMapper.
enum DebtDirection { toPay, toReceive }

/// Isar @Collection for debts (to pay or to receive).
///
/// Used in the net worth formula (D-08): only toPay + !isPaid debts
/// are subtracted from net worth.
@Collection()
class DebtModel {
  Id id = Isar.autoIncrement;

  late String title;
  late int amountCents;

  @Enumerated(EnumType.name)
  late DebtDirection direction;

  /// Name of the other party (creditor or debtor).
  late String counterparty;

  /// Due date for payment or receipt.
  @Index()
  late DateTime dueDate;

  bool isPaid = false;
  DateTime? paidAt;

  /// Soft delete — non-null means this record is deleted.
  @Index()
  DateTime? deletedAt;

  late DateTime createdAt;
  late DateTime updatedAt;
}
