import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/category/transaction_category_repository.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';

/// Result of [loadTransactionFormData]: everything the transaction form
/// needs to render, loaded in one awaited call.
class TransactionFormData {
  const TransactionFormData({
    required this.categories,
    required this.activeGoals,
    required this.preselectedCategory,
  });

  final List<TransactionCategory> categories;
  final List<SavingsGoal> activeGoals;

  /// Resolved category for edit mode, or `null` for create mode / a
  /// category that no longer exists.
  final TransactionCategory? preselectedCategory;
}

/// Loads all transaction categories and active savings goals, resolving the
/// pre-selected category for edit mode by [preselectedCategoryId].
///
/// Moves the combined bodies of `_loadCategories`/`_loadGoals` from
/// `transaction_form_screen.dart` into a single awaited call.
Future<TransactionFormData> loadTransactionFormData(
  TransactionCategoryRepository categoryRepo,
  GoalRepository goalRepo, {
  int? preselectedCategoryId,
}) async {
  final categoriesResult = await categoryRepo.getAll();
  final categories = categoriesResult is Success<List<TransactionCategory>>
      ? categoriesResult.value
      : <TransactionCategory>[];

  TransactionCategory? preselectedCategory;
  if (preselectedCategoryId != null) {
    try {
      preselectedCategory =
          categories.firstWhere((c) => c.id == preselectedCategoryId);
    } catch (_) {
      preselectedCategory = null;
    }
  }

  final goalsResult = await goalRepo.getActiveGoals();
  final activeGoals = goalsResult is Success<List<SavingsGoal>>
      ? goalsResult.value
      : <SavingsGoal>[];

  return TransactionFormData(
    categories: categories,
    activeGoals: activeGoals,
    preselectedCategory: preselectedCategory,
  );
}

/// Builds the [Transaction] to persist (verbatim from `_save()`'s
/// create/edit branches).
Transaction buildTransactionToSave({
  required bool isEditing,
  required Transaction? original,
  required TransactionType type,
  required int amountCents,
  required int categoryId,
  required DateTime date,
  required DateTime now,
  String? note,
  int? linkedGoalId,
}) {
  if (isEditing) {
    return original!.copyWith(
      type: type,
      amountCents: amountCents,
      categoryId: categoryId,
      date: date,
      note: note,
      linkedGoalId: linkedGoalId,
      updatedAt: now,
    );
  }
  return Transaction(
    id: 0,
    type: type,
    amountCents: amountCents,
    categoryId: categoryId,
    date: date,
    note: note,
    linkedGoalId: linkedGoalId,
    createdAt: now,
    updatedAt: now,
  );
}

/// Resolves the display label for the selected category (verbatim from the
/// inline ternary previously in `build()`). [preferEnglish] is
/// `Localizations.localeOf(context).languageCode == 'en'`, kept as a bool so
/// this file stays Flutter-widget-free.
String resolveCategoryDisplay(
  TransactionCategory? category, {
  required bool preferEnglish,
  required String fallback,
}) {
  if (category == null) return fallback;
  return preferEnglish && category.nameEn != null
      ? category.nameEn!
      : category.namePtBr;
}

/// Resolves the display label for the linked goal (verbatim from the inline
/// expression previously in `build()`).
String resolveGoalDisplay(
  int? linkedGoalId,
  List<SavingsGoal> activeGoals, {
  String fallback = 'Sem vínculo',
}) {
  if (linkedGoalId == null) return fallback;
  return activeGoals
          .where((g) => g.id == linkedGoalId)
          .map((g) => g.title)
          .firstOrNull ??
      '#$linkedGoalId';
}
