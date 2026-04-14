import 'package:agenda/domain/tasks/eisenhower_quadrant.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/domain/tasks/size_category.dart';

/// Domain entity representing a project, task, or subtask
/// (TASK-01, TASK-02, TASK-03).
///
/// This is a pure Dart class — zero Flutter and zero Isar imports.
/// The Isar model (ItemModel) and mapper live in the data layer.
class Item {
  const Item({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.parentId,
    this.priority = Priority.medium,
    this.isUrgent = false,
    this.isImportant = false,
    this.sizeCategory = SizeCategory.none,
    this.isNextAction = false,
    this.gtdContext,
    this.waitingFor,
    this.dueDate,
    this.dueTimeMinutes,
    this.recurrenceRule,
    this.isCompleted = false,
    this.completedAt,
    this.deletedAt,
    this.amount,
    this.currencyCode,
    this.linkedGoalId,
    this.linkedDebtId,
  });

  /// Isar auto-increment id (0 for unsaved items).
  final int id;

  /// Discriminates project / task / subtask (TASK-01, TASK-02, TASK-03).
  final ItemType type;

  /// Required title — must be non-empty.
  final String title;

  final String? description;

  /// Non-null only for subtasks (links to parent project id).
  final int? parentId;

  /// Five-level priority — independent of Eisenhower quadrant.
  final Priority priority;

  /// Eisenhower urgency axis (TASK-07).
  final bool isUrgent;

  /// Eisenhower importance axis (TASK-07).
  final bool isImportant;

  /// 1-3-5 Rule day-planner slot size (TASK-08).
  final SizeCategory sizeCategory;

  /// GTD: marks this as the next physical action (TASK-09).
  final bool isNextAction;

  /// GTD: freeform context tag e.g. "@home", "@phone" (TASK-09).
  final String? gtdContext;

  /// GTD: who or what this is waiting on (TASK-09).
  final String? waitingFor;

  /// Due date for reminders and overdue detection (TASK-03).
  /// Stored top-level on ItemModel for Isar index support.
  final DateTime? dueDate;

  /// Time-of-day as minutes since midnight (e.g. 9*60+30 = 09:30).
  /// Null means no specific time was set.
  final int? dueTimeMinutes;

  /// iCal RRULE subset string for recurring tasks (TASK-10).
  /// Null = non-recurring.
  final String? recurrenceRule;

  /// True when the user has marked this item done (TASK-06).
  final bool isCompleted;

  final DateTime? completedAt;

  /// Non-null = soft-deleted (TASK-05). Excluded from all active queries.
  final DateTime? deletedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Money shell — amount in [currencyCode] units (Phase 2 only).
  /// Finance logic and linkage are Phase 3.
  final double? amount;

  /// ISO 4217 currency code e.g. "MZN", "USD".
  final String? currencyCode;

  /// Reserved for Phase 3 goal linkage — always null in Phase 2.
  final int? linkedGoalId;

  /// Reserved for Phase 3 debt linkage — always null in Phase 2.
  final int? linkedDebtId;

  /// Computed Eisenhower quadrant — NEVER stored in Isar (TASK-07).
  EisenhowerQuadrant get eisenhowerQuadrant =>
      switch ((isUrgent, isImportant)) {
        (true, true) => EisenhowerQuadrant.doNow,
        (false, true) => EisenhowerQuadrant.schedule,
        (true, false) => EisenhowerQuadrant.delegate,
        (false, false) => EisenhowerQuadrant.eliminate,
      };

  /// Returns a copy with the specified fields replaced.
  ///
  /// Note: nullable fields (description, parentId, dueDate, deletedAt, etc.)
  /// cannot be explicitly set to null via copyWith — passing null is ignored.
  /// For operations like restoreItem (set deletedAt = null), use the
  /// ItemRepository directly (Isar write), which handles nulling correctly.
  Item copyWith({
    int? id,
    ItemType? type,
    String? title,
    String? description,
    int? parentId,
    Priority? priority,
    bool? isUrgent,
    bool? isImportant,
    SizeCategory? sizeCategory,
    bool? isNextAction,
    String? gtdContext,
    String? waitingFor,
    DateTime? dueDate,
    int? dueTimeMinutes,
    String? recurrenceRule,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? amount,
    String? currencyCode,
    int? linkedGoalId,
    int? linkedDebtId,
  }) {
    return Item(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      priority: priority ?? this.priority,
      isUrgent: isUrgent ?? this.isUrgent,
      isImportant: isImportant ?? this.isImportant,
      sizeCategory: sizeCategory ?? this.sizeCategory,
      isNextAction: isNextAction ?? this.isNextAction,
      gtdContext: gtdContext ?? this.gtdContext,
      waitingFor: waitingFor ?? this.waitingFor,
      dueDate: dueDate ?? this.dueDate,
      dueTimeMinutes: dueTimeMinutes ?? this.dueTimeMinutes,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      linkedGoalId: linkedGoalId ?? this.linkedGoalId,
      linkedDebtId: linkedDebtId ?? this.linkedDebtId,
    );
  }
}
