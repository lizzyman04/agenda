import 'package:isar_community/isar.dart';

part 'recurring_payment_model.g.dart';

/// Isar-layer enum for recurring payment cycle.
///
/// Persisted as string via @Enumerated(EnumType.name) — safe to reorder.
/// Maps to domain RecurringCycle via RecurringPaymentMapper.
enum RecurringCycle { daily, weekly, biweekly, monthly, quarterly, yearly }

/// Isar @Collection for recurring payments (subscriptions, bills, etc.).
///
/// nextDueDate is stored and retrieved only. The Phase 4 reminder planner
/// computes the effective due date in memory and never writes it back (D-15).
@Collection()
class RecurringPaymentModel {
  Id id = Isar.autoIncrement;

  late String title;
  late int amountCents;

  /// FK to TransactionCategoryModel.id.
  late int categoryId;

  @Enumerated(EnumType.name)
  late RecurringCycle cycle;

  /// Date of the next expected payment (never advanced by notification code).
  @Index()
  late DateTime nextDueDate;

  bool isActive = true;

  /// Soft delete — non-null means this record is deleted.
  @Index()
  DateTime? deletedAt;

  late DateTime createdAt;
  late DateTime updatedAt;
}
