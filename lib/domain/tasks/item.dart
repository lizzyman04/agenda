import 'package:agenda/domain/tasks/eisenhower_quadrant.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/domain/tasks/size_category.dart';

/// Sentinel value used by [Item.copyWith] to distinguish "not provided"
/// from "explicitly set to null" for nullable fields.
///
/// Pass [clearField] as the named argument to explicitly null out a field:
/// ```dart
/// item.copyWith(dueDate: clearField); // sets dueDate to null
/// item.copyWith(dueDate: someDate);   // sets dueDate to someDate
/// item.copyWith();                    // keeps existing dueDate
/// ```
const Object clearField = _Absent();

final class _Absent {
  const _Absent();
}

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
  /// Nullable fields use the [clearField] sentinel to distinguish
  /// "not provided" (keep existing value) from "explicitly set to null".
  ///
  /// ```dart
  /// // Keep existing dueDate:
  /// item.copyWith(title: 'New title');
  ///
  /// // Clear dueDate (set to null):
  /// item.copyWith(dueDate: clearField);
  /// ```
  Item copyWith({
    int? id,
    ItemType? type,
    String? title,
    Object? description = clearField,
    Object? parentId = clearField,
    Priority? priority,
    bool? isUrgent,
    bool? isImportant,
    SizeCategory? sizeCategory,
    bool? isNextAction,
    Object? gtdContext = clearField,
    Object? waitingFor = clearField,
    Object? dueDate = clearField,
    Object? dueTimeMinutes = clearField,
    Object? recurrenceRule = clearField,
    bool? isCompleted,
    Object? completedAt = clearField,
    Object? deletedAt = clearField,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? amount = clearField,
    Object? currencyCode = clearField,
    Object? linkedGoalId = clearField,
    Object? linkedDebtId = clearField,
  }) {
    return Item(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description is _Absent
          ? this.description
          : description as String?,
      parentId: parentId is _Absent
          ? this.parentId
          : parentId as int?,
      priority: priority ?? this.priority,
      isUrgent: isUrgent ?? this.isUrgent,
      isImportant: isImportant ?? this.isImportant,
      sizeCategory: sizeCategory ?? this.sizeCategory,
      isNextAction: isNextAction ?? this.isNextAction,
      gtdContext: gtdContext is _Absent
          ? this.gtdContext
          : gtdContext as String?,
      waitingFor: waitingFor is _Absent
          ? this.waitingFor
          : waitingFor as String?,
      dueDate: dueDate is _Absent ? this.dueDate : dueDate as DateTime?,
      dueTimeMinutes: dueTimeMinutes is _Absent
          ? this.dueTimeMinutes
          : dueTimeMinutes as int?,
      recurrenceRule: recurrenceRule is _Absent
          ? this.recurrenceRule
          : recurrenceRule as String?,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt is _Absent
          ? this.completedAt
          : completedAt as DateTime?,
      deletedAt: deletedAt is _Absent ? this.deletedAt : deletedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      amount: amount is _Absent ? this.amount : amount as double?,
      currencyCode: currencyCode is _Absent
          ? this.currencyCode
          : currencyCode as String?,
      linkedGoalId: linkedGoalId is _Absent
          ? this.linkedGoalId
          : linkedGoalId as int?,
      linkedDebtId: linkedDebtId is _Absent
          ? this.linkedDebtId
          : linkedDebtId as int?,
    );
  }
}
