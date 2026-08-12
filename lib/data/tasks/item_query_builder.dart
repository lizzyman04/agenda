import 'package:agenda/data/tasks/item_model.dart';
import 'package:isar_community/isar.dart';

/// Builds the composable Isar filter query for `ItemDao.filterItems`.
///
/// Extracted from `ItemDao` as a top-level function because it is pure
/// `QueryBuilder` composition — no private DAO state is required, only the
/// public [IsarCollection] type. See Pattern 3 in 06-RESEARCH.md.
QueryBuilder<ItemModel, ItemModel, QAfterFilterCondition> buildItemFilterQuery(
  IsarCollection<ItemModel> collection, {
  ItemType? type,
  bool? isUrgent,
  bool? isImportant,
  String? gtdContext,
  DateTime? dueDateFrom,
  DateTime? dueDateTo,
  int? parentId,
  bool showCompleted = false,
}) {
  // Always start with active (non-deleted) items.
  // Use .optional() to conditionally chain each filter — preserves the
  // Isar QueryBuilder phantom-type invariant without dynamic reassignment.
  // Promote nullable params to non-nullable locals so Dart flow analysis
  // can prove non-null inside the lambda closures.
  final resolvedType = type;
  final resolvedIsUrgent = isUrgent;
  final resolvedIsImportant = isImportant;
  final resolvedGtdContext = gtdContext;
  final resolvedDateFrom = dueDateFrom;
  final resolvedDateTo = dueDateTo;
  final resolvedParentId = parentId;
  return collection
      .filter()
      .deletedAtIsNull()
      .optional(
        resolvedType != null,
        (q) => q.and().typeEqualTo(resolvedType!),
      )
      .optional(
        resolvedIsUrgent != null,
        (q) => q.and().isUrgentEqualTo(resolvedIsUrgent!),
      )
      .optional(
        resolvedIsImportant != null,
        (q) => q.and().isImportantEqualTo(resolvedIsImportant!),
      )
      .optional(
        resolvedGtdContext != null,
        (q) => q.and().gtdContextEqualTo(resolvedGtdContext),
      )
      .optional(
        resolvedDateFrom != null && resolvedDateTo != null,
        (q) => q.and().dueDateBetween(resolvedDateFrom, resolvedDateTo),
      )
      .optional(
        resolvedDateFrom != null && resolvedDateTo == null,
        (q) => q.and().dueDateGreaterThan(resolvedDateFrom, include: true),
      )
      .optional(
        resolvedDateTo != null && resolvedDateFrom == null,
        (q) => q.and().dueDateLessThan(resolvedDateTo, include: true),
      )
      .optional(
        resolvedParentId != null,
        (q) => q.and().parentIdEqualTo(resolvedParentId),
      )
      .optional(
        !showCompleted,
        (q) => q.and().isCompletedEqualTo(false),
      );
}
