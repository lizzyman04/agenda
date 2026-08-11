import 'package:agenda/domain/tasks/item.dart';

/// Builds the next occurrence of a recurring [completed] item, due at
/// [nextDate] (TASK-10).
///
/// Pure function — no cubit/repository access. `id` is left at 0 so Isar
/// assigns a new auto-increment id when the caller persists the result.
Item buildNextOccurrence(Item completed, DateTime nextDate) {
  final now = DateTime.now();
  return Item(
    id: 0, // Isar auto-increment assigns a new id
    type: completed.type,
    title: completed.title,
    description: completed.description,
    parentId: completed.parentId,
    priority: completed.priority,
    isUrgent: completed.isUrgent,
    isImportant: completed.isImportant,
    sizeCategory: completed.sizeCategory,
    isNextAction: completed.isNextAction,
    gtdContext: completed.gtdContext,
    waitingFor: completed.waitingFor,
    dueDate: nextDate,
    dueTimeMinutes: completed.dueTimeMinutes,
    recurrenceRule: completed.recurrenceRule,
    amount: completed.amount,
    currencyCode: completed.currencyCode,
    createdAt: now,
    updatedAt: now,
  );
}
