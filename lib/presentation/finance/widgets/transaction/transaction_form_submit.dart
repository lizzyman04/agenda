import 'package:agenda/application/finance/transaction/transaction_cubit.dart';
import 'package:agenda/core/utils/amount_parser.dart';
import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/domain/finance/transaction/transaction_type.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/transaction_form_logic.dart';
import 'package:agenda/presentation/finance/widgets/transaction/transaction_form_pickers.dart';
import 'package:flutter/material.dart';

/// Validates the transaction form, builds the [Transaction] and persists it
/// through [cubit].
///
/// Extracted verbatim from `TransactionFormScreen`'s `_save`/`_persist` pair
/// so the screen widget can stay under the architecture line-count limit.
/// Lives here rather than in `transaction_form_logic.dart` because it needs a
/// [BuildContext] for localisation and the validation snackbar, and that file
/// is deliberately Flutter-widget-free.
///
/// Returns `true` when the transaction was saved and the caller should pop.
/// Every failure path shows its own snackbar and returns `false`.
Future<bool> submitTransactionForm({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required TransactionCubit cubit,
  required bool isEditing,
  required Transaction? original,
  required TransactionType type,
  required TransactionCategory? category,
  required DateTime date,
  required int? linkedGoalId,
  required String amountText,
  required String noteText,
}) async {
  if (!formKey.currentState!.validate()) return false;
  final l10n = AppLocalizations.of(context);
  if (category == null) {
    showTransactionFormError(context, l10n.errorCategoryRequired);
    return false;
  }
  final amountCents = parseAmountCentsOrNull(amountText);
  if (amountCents == null) {
    showTransactionFormError(context, l10n.errorAmountRequired);
    return false;
  }
  final note = noteText.trim();
  final tx = buildTransactionToSave(
    isEditing: isEditing,
    original: original,
    type: type,
    amountCents: amountCents,
    categoryId: category.id,
    date: date,
    now: DateTime.now(),
    linkedGoalId: linkedGoalId,
    note: note.isNotEmpty ? note : null,
  );
  await (isEditing ? cubit.updateTransaction(tx) : cubit.createTransaction(tx));
  return true;
}
