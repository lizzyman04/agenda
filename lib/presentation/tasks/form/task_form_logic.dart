import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/debt.dart' hide clearField;
import 'package:agenda/domain/finance/debt_repository.dart';
import 'package:agenda/domain/finance/goal_repository.dart';
import 'package:agenda/domain/finance/savings_goal.dart' hide clearField;
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/domain/tasks/size_category.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_models.dart';

/// Active goals/debts to choose from, plus titles for whatever is linked.
class FinanceLinksSnapshot {
  const FinanceLinksSnapshot({
    this.activeGoals = const [],
    this.activeDebts = const [],
    this.linkedGoalTitle,
    this.linkedDebtTitle,
  });

  final List<SavingsGoal> activeGoals;
  final List<Debt> activeDebts;
  final String? linkedGoalTitle;
  final String? linkedDebtTitle;
}

/// Loads active goals/debts and resolves titles for any already-linked ids.
Future<FinanceLinksSnapshot> loadFinanceLinks(
  GoalRepository goalRepo,
  DebtRepository debtRepo, {
  int? linkedGoalId,
  int? linkedDebtId,
}) async {
  final goalsResult = await goalRepo.getActiveGoals();
  final goals = goalsResult is Success<List<SavingsGoal>>
      ? goalsResult.value
      : <SavingsGoal>[];
  String? goalTitle;
  if (linkedGoalId != null) {
    try {
      goalTitle = goals.firstWhere((g) => g.id == linkedGoalId).title;
    } catch (_) {}
  }

  final debtsResult = await debtRepo.getDebts();
  final debts = debtsResult is Success<List<Debt>>
      ? debtsResult.value
      : <Debt>[];
  String? debtTitle;
  if (linkedDebtId != null) {
    try {
      debtTitle = debts.firstWhere((d) => d.id == linkedDebtId).title;
    } catch (_) {}
  }

  return FinanceLinksSnapshot(
    activeGoals: goals,
    activeDebts: debts,
    linkedGoalTitle: goalTitle,
    linkedDebtTitle: debtTitle,
  );
}

/// Builds the [Item] to persist (nullable text fields already trimmed).
Item buildFormItem({
  required bool isEditing,
  required Item? original,
  required String title,
  required ItemType itemType,
  required Priority priority,
  required SizeCategory sizeCategory,
  required bool isUrgent,
  required bool isImportant,
  required bool isNextAction,
  required DateTime now,
  String? description,
  String? gtdContext,
  String? waitingFor,
  DateTime? dueDate,
  int? dueTimeMinutes,
  String? recurrenceRule,
  int? linkedGoalId,
  int? linkedDebtId,
}) {
  if (isEditing) {
    final item = original!;
    return item.copyWith(
      title: title,
      description: description,
      type: item.type == ItemType.subtask ? item.type : itemType,
      // Invariant: only subtasks may carry a parentId. A non-subtask item
      // must have parentId == null, otherwise updateItem's guard rejects the
      // save. Clearing it here lets the form recover any legacy item whose
      // type is not subtask but still holds a stale parentId.
      parentId: item.type == ItemType.subtask ? item.parentId : null,
      priority: priority, sizeCategory: sizeCategory,
      isUrgent: isUrgent, isImportant: isImportant,
      isNextAction: isNextAction,
      gtdContext: gtdContext, waitingFor: waitingFor,
      dueDate: dueDate, dueTimeMinutes: dueTimeMinutes,
      recurrenceRule: recurrenceRule,
      linkedGoalId: linkedGoalId ?? clearField,
      linkedDebtId: linkedDebtId ?? clearField,
      updatedAt: now,
    );
  }
  return Item(
    id: 0, type: itemType, title: title, description: description,
    priority: priority, sizeCategory: sizeCategory,
    isUrgent: isUrgent, isImportant: isImportant,
    isNextAction: isNextAction,
    gtdContext: gtdContext, waitingFor: waitingFor,
    dueDate: dueDate, dueTimeMinutes: dueTimeMinutes,
    recurrenceRule: recurrenceRule,
    linkedGoalId: linkedGoalId, linkedDebtId: linkedDebtId,
    createdAt: now, updatedAt: now,
  );
}

/// Field values a GTD walkthrough maps onto the form. `null` text fields
/// mean "leave alone"; `isNextAction` isn't here — it always becomes true.
typedef GtdFormValues = ({
  String title,
  String? description,
  Priority priority,
  bool isUrgent,
  bool isImportant,
  DateTime? dueDate,
  String? waitingFor,
  String? gtdContext,
});

/// Computes the form field values for a completed [GtdResult].
GtdFormValues applyGtdResult(
  GtdResult result, {
  required String currentDescription,
}) {
  return (
    title: result.title,
    description: result.description != null && currentDescription.isEmpty
        ? result.description
        : null,
    priority: result.priority,
    isUrgent: result.isUrgent,
    isImportant: result.isImportant,
    dueDate: result.dueDate,
    waitingFor: result.waitingFor,
    gtdContext: result.gtdContext,
  );
}
