import 'package:isar_community/isar.dart';

part 'item_model.g.dart';

// ---------------------------------------------------------------------------
// Embedded value objects
// ---------------------------------------------------------------------------

/// Money shell for Phase 2 — amount + currency only.
/// Finance linkage (goals, debts) is Phase 3.
@embedded
class MoneyInfo {
  MoneyInfo({this.amount, this.currencyCode});
  double? amount;
  String? currencyCode; // ISO 4217 e.g. "MZN", "USD"
}

/// Time metadata — dueTimeMinutes and recurrenceRule only.
/// dueDate is promoted to top-level on ItemModel for Isar index support.
@embedded
class TimeInfo {
  TimeInfo({this.dueTimeMinutes, this.recurrenceRule});
  int? dueTimeMinutes; // minutes since midnight; null = no time set
  String? recurrenceRule; // iCal RRULE subset; null = non-recurring
}

// ---------------------------------------------------------------------------
// Enums (annotated at field level — Phase 1 convention)
// ---------------------------------------------------------------------------

/// Matches domain ItemType — persisted as string via
/// @Enumerated(EnumType.name).
enum ItemType { project, task, subtask }

/// Matches domain Priority — persisted as string.
enum Priority { low, medium, high, critical, urgent }

/// Matches domain SizeCategory — persisted as string.
enum SizeCategory { big, medium, small, none }

// ---------------------------------------------------------------------------
// Collection
// ---------------------------------------------------------------------------

/// Unified Isar collection for all item types (project, task, subtask).
///
/// One collection — ItemType discriminates. Parent/child via parentId.
/// EisenhowerQuadrant is NOT stored — computed by the domain mapper.
@Collection()
class ItemModel {
  Id id = Isar.autoIncrement;

  // --- Identity & Type ---
  // Composite index on (type, deletedAt) for active-items-by-type queries.
  @Index(composite: [CompositeIndex('deletedAt')])
  @Enumerated(EnumType.name)
  late ItemType type;

  @Index()
  int? parentId;

  // --- Content ---
  late String title;
  String? description;

  // --- Classification ---
  @Enumerated(EnumType.name)
  Priority priority = Priority.medium;

  bool isUrgent = false;
  bool isImportant = false;

  @Enumerated(EnumType.name)
  SizeCategory sizeCategory = SizeCategory.none;

  // --- GTD ---
  bool isNextAction = false;
  String? gtdContext;
  String? waitingFor;

  // --- Status ---
  bool isCompleted = false;
  DateTime? completedAt;

  // --- Soft Delete ---
  @Index()
  DateTime? deletedAt;

  // --- Time (dueDate top-level for @Index; timeInfo holds remaining fields) ---
  @Index()
  DateTime? dueDate;

  TimeInfo? timeInfo;

  // --- Money ---
  MoneyInfo? moneyInfo;

  // --- Phase 3 Extensibility (always null in Phase 2) ---
  int? linkedGoalId;
  int? linkedDebtId;

  // --- Timestamps ---
  late DateTime createdAt;
  late DateTime updatedAt;
}
