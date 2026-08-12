import 'package:agenda/domain/finance/debt/debt.dart' hide clearField;
import 'package:agenda/domain/finance/goal/savings_goal.dart' hide clearField;
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/domain/tasks/size_category.dart';
import 'package:agenda/presentation/tasks/form/widgets/finance_link_sheet.dart';
import 'package:flutter/material.dart' show TimeOfDay;

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

/// Field values a GTD walkthrough maps onto the form. `null` text fields
/// mean "leave alone"; `isNextAction` isn't here — it always becomes true.
typedef GtdFormValues =
    ({
      String title,
      String? description,
      Priority priority,
      bool isUrgent,
      bool isImportant,
      DateTime? dueDate,
      String? waitingFor,
      String? gtdContext,
    });

/// Mutable holder for every task-form field the screen doesn't keep in a
/// `TextEditingController`.
///
/// Owned exclusively by `TaskFormScreen`'s State. `TaskFormFields` and its
/// children receive it read-only and report changes back through
/// `TaskFormFields.onModelChanged`, which the screen wraps in `setState` —
/// so mutation still only ever happens on the screen's turn of the event
/// loop, preserving the "screens own state" convention with one object
/// instead of a dozen fields. The `apply*` methods bundle the multi-field
/// updates that follow a sheet or wizard result, so the screen's callbacks
/// stay one line each.
class TaskFormFieldsModel {
  TaskFormFieldsModel({
    required this.itemType,
    required this.priority,
    required this.sizeCategory,
    required this.isUrgent,
    required this.isImportant,
    required this.isNextAction,
    this.dueDate,
    this.dueTime,
    this.recurrenceRule,
    this.linkedGoalId,
    this.linkedDebtId,
    this.activeGoals = const [],
    this.activeDebts = const [],
    this.linkedGoalTitle,
    this.linkedDebtTitle,
    this.advancedExpanded = false,
  });

  /// Seeds every field from [item] (or defaults, in create mode).
  factory TaskFormFieldsModel.fromItem(Item? item) {
    TimeOfDay? dueTime;
    if (item?.dueTimeMinutes != null) {
      final m = item!.dueTimeMinutes!;
      dueTime = TimeOfDay(hour: m ~/ 60, minute: m % 60);
    }
    return TaskFormFieldsModel(
      itemType: item?.type ?? ItemType.task,
      priority: item?.priority ?? Priority.medium,
      sizeCategory: item?.sizeCategory ?? SizeCategory.medium,
      isUrgent: item?.isUrgent ?? false,
      isImportant: item?.isImportant ?? false,
      isNextAction: item?.isNextAction ?? false,
      dueDate: item?.dueDate,
      dueTime: dueTime,
      recurrenceRule: item?.recurrenceRule,
      linkedGoalId: item?.linkedGoalId,
      linkedDebtId: item?.linkedDebtId,
    );
  }

  ItemType itemType;
  Priority priority;
  SizeCategory sizeCategory;
  bool isUrgent;
  bool isImportant;
  bool isNextAction;
  DateTime? dueDate;
  TimeOfDay? dueTime;
  String? recurrenceRule;
  int? linkedGoalId;
  int? linkedDebtId;
  List<SavingsGoal> activeGoals;
  List<Debt> activeDebts;
  String? linkedGoalTitle;
  String? linkedDebtTitle;
  bool advancedExpanded;

  /// Applies a freshly-loaded [FinanceLinksSnapshot] (goals/debts + titles).
  void applySnapshot(FinanceLinksSnapshot s) {
    activeGoals = s.activeGoals;
    activeDebts = s.activeDebts;
    linkedGoalTitle = s.linkedGoalTitle;
    linkedDebtTitle = s.linkedDebtTitle;
  }

  /// Applies a [FinanceLinkSelection] returned by [FinanceLinkSheet].
  void applyFinanceLink(FinanceLinkSelection s) {
    linkedGoalId = s.goalId;
    linkedDebtId = s.debtId;
    linkedGoalTitle = s.goalTitle;
    linkedDebtTitle = s.debtTitle;
  }

  /// Applies the non-text fields of a completed GTD walkthrough. Text
  /// fields (title/description/waitingFor/gtdContext) stay in the screen's
  /// controllers and are applied separately.
  void applyGtd(GtdFormValues v) {
    priority = v.priority;
    isUrgent = v.isUrgent;
    isImportant = v.isImportant;
    isNextAction = true;
    dueDate = v.dueDate;
  }
}

/// Applies a mutation to a [TaskFormFieldsModel] inside the owning screen's
/// `setState`. Declared here rather than in `task_form_fields.dart` so the
/// picker helpers can reference it without importing that widget.
typedef TaskFormFieldsMutator =
    void Function(void Function(TaskFormFieldsModel model));
