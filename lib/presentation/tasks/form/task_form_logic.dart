import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/debt/debt.dart' hide clearField;
import 'package:agenda/domain/finance/debt/debt_repository.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart' hide clearField;
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_models.dart';
import 'package:agenda/presentation/tasks/form/task_form_fields_model.dart';

/// Loads active goals/debts and resolves titles for any already-linked ids.
Future<FinanceLinksSnapshot> loadFinanceLinks(
  GoalRepository goalRepo, DebtRepository debtRepo,
  {int? linkedGoalId, int? linkedDebtId}) async {
  final goalsResult = await goalRepo.getActiveGoals();
  final goals = goalsResult is Success<List<SavingsGoal>>
      ? goalsResult.value : <SavingsGoal>[];
  String? goalTitle;
  if (linkedGoalId != null) {
    try {
      goalTitle = goals.firstWhere((g) => g.id == linkedGoalId).title;
    } catch (_) {}
  }

  final debtsResult = await debtRepo.getDebts();
  final debts = debtsResult is Success<List<Debt>>
      ? debtsResult.value : <Debt>[];
  String? debtTitle;
  if (linkedDebtId != null) {
    try {
      debtTitle = debts.firstWhere((d) => d.id == linkedDebtId).title;
    } catch (_) {}
  }

  return FinanceLinksSnapshot(
    activeGoals: goals, activeDebts: debts,
    linkedGoalTitle: goalTitle, linkedDebtTitle: debtTitle,
  );
}

/// Builds the [Item] to persist (nullable text fields already trimmed).
/// Non-text values come from [fields]; `dueTimeMinutes` is derived from its
/// `dueTime`.
Item buildFormItem({
  required bool isEditing, required Item? original, required String title,
  required TaskFormFieldsModel fields, required DateTime now,
  String? description, String? gtdContext, String? waitingFor,
}) {
  final dueTimeMinutes = fields.dueTime != null
      ? fields.dueTime!.hour * 60 + fields.dueTime!.minute
      : null;
  if (isEditing) {
    final item = original!;
    return item.copyWith(
      title: title,
      description: description,
      type: item.type == ItemType.subtask ? item.type : fields.itemType,
      // Invariant: only subtasks may carry a parentId. A non-subtask item
      // must have parentId == null, otherwise updateItem's guard rejects the
      // save. Clearing it here lets the form recover any legacy item whose
      // type is not subtask but still holds a stale parentId.
      parentId: item.type == ItemType.subtask ? item.parentId : null,
      priority: fields.priority, sizeCategory: fields.sizeCategory,
      isUrgent: fields.isUrgent, isImportant: fields.isImportant,
      isNextAction: fields.isNextAction,
      gtdContext: gtdContext, waitingFor: waitingFor,
      dueDate: fields.dueDate, dueTimeMinutes: dueTimeMinutes,
      recurrenceRule: fields.recurrenceRule,
      linkedGoalId: fields.linkedGoalId ?? clearField,
      linkedDebtId: fields.linkedDebtId ?? clearField,
      updatedAt: now,
    );
  }
  return Item(
    id: 0, type: fields.itemType, title: title, description: description,
    priority: fields.priority, sizeCategory: fields.sizeCategory,
    isUrgent: fields.isUrgent, isImportant: fields.isImportant,
    isNextAction: fields.isNextAction,
    gtdContext: gtdContext, waitingFor: waitingFor,
    dueDate: fields.dueDate, dueTimeMinutes: dueTimeMinutes,
    recurrenceRule: fields.recurrenceRule,
    linkedGoalId: fields.linkedGoalId, linkedDebtId: fields.linkedDebtId,
    createdAt: now, updatedAt: now,
  );
}

/// Computes the form field values for a completed [GtdResult].
GtdFormValues applyGtdResult(
    GtdResult result, {required String currentDescription}) {
  return (
    title: result.title,
    description: result.description != null && currentDescription.isEmpty
        ? result.description
        : null,
    priority: result.priority, isUrgent: result.isUrgent,
    isImportant: result.isImportant, dueDate: result.dueDate,
    waitingFor: result.waitingFor, gtdContext: result.gtdContext,
  );
}
