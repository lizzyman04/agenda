import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:agenda/domain/finance/transaction_category.dart';
import 'package:agenda/presentation/finance/widgets/category_picker_sheet.dart';
import 'package:agenda/presentation/finance/widgets/transaction/goal_link_picker_sheet.dart';
import 'package:flutter/material.dart';

/// BuildContext-driven picker helpers for the transaction form, extracted
/// from `TransactionFormScreen`'s `_showSheet`/`_pickCategory`/`_pickDate`/
/// `_pickGoal` methods so the screen widget can stay under the architecture
/// line-count limit.
///
/// Mirrors `recurring/recurring_payment_form_pickers.dart`. Each helper
/// returns the user's selection and never mutates caller state, matching the
/// pop-not-mutate convention documented in `finance/goals/README.md`.

/// Presents [builder] in the rounded modal bottom sheet shape shared by every
/// picker on this form.
Future<T?> showTransactionFormSheet<T>(
  BuildContext context,
  WidgetBuilder builder,
) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: builder,
  );
}

/// Presents the shared [CategoryPickerSheet] and returns the user's
/// selection, or `null` if the sheet was dismissed without a pick.
Future<TransactionCategory?> pickTransactionCategory({
  required BuildContext context,
  required List<TransactionCategory> categories,
  required int? selectedCategoryId,
}) {
  final locale = Localizations.localeOf(context);
  return showTransactionFormSheet<TransactionCategory>(
    context,
    (_) => CategoryPickerSheet(
      categories: categories,
      selectedCategoryId: selectedCategoryId,
      locale: locale,
    ),
  );
}

/// Presents the native date picker for the transaction date field.
Future<DateTime?> pickTransactionDate(
  BuildContext context,
  DateTime initialDate,
) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );
}

/// Presents the goal-link sheet. Returns the chosen goal id, or `null` when
/// the user cleared the link or dismissed the sheet.
Future<int?> pickTransactionGoal({
  required BuildContext context,
  required List<SavingsGoal> activeGoals,
  required int? selectedGoalId,
}) {
  return showTransactionFormSheet<int?>(
    context,
    (_) => GoalLinkPickerSheet(
      activeGoals: activeGoals,
      selectedGoalId: selectedGoalId,
    ),
  );
}

/// Shows a floating validation-error snackbar for the transaction form.
void showTransactionFormError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}
