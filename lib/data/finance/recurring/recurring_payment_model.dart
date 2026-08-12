import 'package:isar_community/isar.dart';

part 'recurring_payment_model.g.dart';

/// Isar-layer enum for recurring payment cycle.
///
/// Persisted as string via @Enumerated(EnumType.name) — safe to reorder.
/// Maps to domain RecurringCycle via RecurringPaymentMapper.
enum RecurringCycle { daily, weekly, biweekly, monthly, quarterly, yearly }

/// Isar @Collection for recurring payments (subscriptions, bills, etc.).
///
/// nextDueDate is tracked and advanced by the Phase 4 notification system.
/// Phase 3 only stores and retrieves; no auto-advance logic here.
@Collection()
class RecurringPaymentModel {
  Id id = Isar.autoIncrement;

  late String title;
  late int amountCents;

  /// FK to TransactionCategoryModel.id.
  late int categoryId;

  @Enumerated(EnumType.name)
  late RecurringCycle cycle;

  /// Date of the next expected payment (Phase 4 advances this).
  @Index()
  late DateTime nextDueDate;

  bool isActive = true;

  /// Soft delete — non-null means this record is deleted.
  @Index()
  DateTime? deletedAt;

  late DateTime createdAt;
  late DateTime updatedAt;
}
