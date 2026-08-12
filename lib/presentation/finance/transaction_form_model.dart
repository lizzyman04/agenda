import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/domain/finance/transaction_category.dart';
import 'package:agenda/domain/finance/transaction_type.dart';

/// Mutable field state for the transaction form, held by
/// `TransactionFormScreen` and mutated inside `setState`.
///
/// Collapses the screen's seven separate `_selected*`/`_all*`/`_loading*`
/// members into one object so the screen stays under the architecture
/// line-count limit. Mirrors `presentation/tasks/form/task_form_fields_model.dart`,
/// the same pattern plan 3.1-02 introduced for the task form.
///
/// Holds no controllers — the screen still owns and disposes those.
class TransactionFormModel {
  TransactionFormModel({
    required this.type,
    required this.date,
    this.category,
    this.goalId,
  });

  /// Seeds create mode from defaults, or edit mode from [tx].
  factory TransactionFormModel.from(Transaction? tx) => TransactionFormModel(
    type: tx?.type ?? TransactionType.income,
    date: tx?.date ?? DateTime.now(),
    goalId: tx?.linkedGoalId,
  );

  TransactionType type;
  DateTime date;
  TransactionCategory? category;
  int? goalId;

  List<TransactionCategory> allCategories = [];
  List<SavingsGoal> activeGoals = [];
  bool loadingCategories = false;

  /// Categories matching the currently selected [type] — income categories
  /// are never offered for an expense and vice versa.
  List<TransactionCategory> get filteredCategories =>
      allCategories.where((c) => c.type == type).toList();

  /// True when the goal-link row applies: only expenses can fund a goal.
  bool get showGoalLink => type == TransactionType.expense;
}
