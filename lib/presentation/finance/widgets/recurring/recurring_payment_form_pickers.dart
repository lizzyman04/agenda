import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/presentation/finance/widgets/category_picker_sheet.dart';
import 'package:flutter/material.dart';

/// BuildContext-driven picker helpers for the recurring payment form,
/// extracted from `RecurringPaymentFormScreen`'s `_pickCategory`/`_pickDate`
/// methods so the screen widget can stay under the architecture
/// line-count limit.

/// Presents the shared [CategoryPickerSheet] and returns the user's
/// selection, or `null` if the sheet was dismissed without a pick.
Future<TransactionCategory?> pickExpenseCategory({
  required BuildContext context,
  required List<TransactionCategory> categories,
  required int? selectedCategoryId,
}) {
  final locale = Localizations.localeOf(context);
  return showModalBottomSheet<TransactionCategory>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder:
        (_) => CategoryPickerSheet(
          categories: categories,
          selectedCategoryId: selectedCategoryId,
          locale: locale,
        ),
  );
}

/// Presents the native date picker for the next-due-date field.
Future<DateTime?> pickNextDueDate(BuildContext context, DateTime initialDate) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime.now(),
    lastDate: DateTime(2100),
  );
}

/// Shows a floating validation-error snackbar for the recurring payment
/// form.
void showFormError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}
