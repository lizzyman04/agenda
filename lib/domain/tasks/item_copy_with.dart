import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/domain/tasks/size_category.dart';

/// `Item.copyWith` moved out of the entity class body — see
/// `core/utils/copy_with_sentinel.dart` for the `clearField` sentinel this
/// extension relies on to distinguish "not provided" from "explicitly
/// cleared" for nullable fields.
///
/// `_Absent` (the sentinel's private marker type) is not visible outside its
/// declaring file, so the per-field checks below compare against the
/// `clearField` instance directly via `identical` rather than `is _Absent` —
/// behaviorally identical, since default parameter values are canonicalized
/// consts and resolve to the exact same object as the top-level `clearField`.
extension ItemCopyWith on Item {
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
      description: identical(description, clearField)
          ? this.description
          : description as String?,
      parentId: identical(parentId, clearField)
          ? this.parentId
          : parentId as int?,
      priority: priority ?? this.priority,
      isUrgent: isUrgent ?? this.isUrgent,
      isImportant: isImportant ?? this.isImportant,
      sizeCategory: sizeCategory ?? this.sizeCategory,
      isNextAction: isNextAction ?? this.isNextAction,
      gtdContext: identical(gtdContext, clearField)
          ? this.gtdContext
          : gtdContext as String?,
      waitingFor: identical(waitingFor, clearField)
          ? this.waitingFor
          : waitingFor as String?,
      dueDate: identical(dueDate, clearField)
          ? this.dueDate
          : dueDate as DateTime?,
      dueTimeMinutes: identical(dueTimeMinutes, clearField)
          ? this.dueTimeMinutes
          : dueTimeMinutes as int?,
      recurrenceRule: identical(recurrenceRule, clearField)
          ? this.recurrenceRule
          : recurrenceRule as String?,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: identical(completedAt, clearField)
          ? this.completedAt
          : completedAt as DateTime?,
      deletedAt: identical(deletedAt, clearField)
          ? this.deletedAt
          : deletedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      amount: identical(amount, clearField)
          ? this.amount
          : amount as double?,
      currencyCode: identical(currencyCode, clearField)
          ? this.currencyCode
          : currencyCode as String?,
      linkedGoalId: identical(linkedGoalId, clearField)
          ? this.linkedGoalId
          : linkedGoalId as int?,
      linkedDebtId: identical(linkedDebtId, clearField)
          ? this.linkedDebtId
          : linkedDebtId as int?,
    );
  }
}
