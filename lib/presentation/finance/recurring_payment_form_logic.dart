import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/recurring_cycle.dart';
import 'package:agenda/domain/finance/recurring_payment.dart';
import 'package:agenda/domain/finance/transaction_category.dart';
import 'package:agenda/domain/finance/transaction_category_repository.dart';
import 'package:agenda/domain/finance/transaction_type.dart';

/// Pure logic extracted from `RecurringPaymentFormScreen`'s `_loadCategories`
/// and `_save` methods, so the screen widget can stay under the
/// architecture line-count limit.

/// Loads the expense-only categories used by the recurring payment form.
///
/// Returns an empty list on failure, matching the previous inline
/// behavior where `_expenseCategories` was left untouched (and therefore
/// still `[]`) if the repository call did not return [Success].
Future<List<TransactionCategory>> loadExpenseCategories(
  TransactionCategoryRepository repo,
) async {
  final result = await repo.getByType(TransactionType.expense);
  if (result is Success<List<TransactionCategory>>) {
    return result.value;
  }
  return const [];
}

/// Builds the [RecurringPayment] to persist, mirroring the previous inline
/// `_save()` construction verbatim — including the `isActive: true`
/// create-default.
RecurringPayment buildRecurringPaymentToSave({
  required bool isEditing,
  required RecurringPayment? original,
  required String title,
  required int amountCents,
  required int categoryId,
  required RecurringCycle cycle,
  required DateTime nextDueDate,
  required DateTime now,
}) {
  if (isEditing && original != null) {
    return original.copyWith(
      title: title,
      amountCents: amountCents,
      categoryId: categoryId,
      cycle: cycle,
      nextDueDate: nextDueDate,
      updatedAt: now,
    );
  }
  return RecurringPayment(
    id: 0,
    title: title,
    amountCents: amountCents,
    categoryId: categoryId,
    cycle: cycle,
    nextDueDate: nextDueDate,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}
