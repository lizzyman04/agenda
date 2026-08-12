import 'package:agenda/domain/finance/transaction_type.dart';
import 'package:agenda/presentation/finance/widgets/transaction/transaction_category_date_note_fields.dart';
import 'package:agenda/presentation/finance/widgets/transaction/transaction_type_amount_fields.dart';
import 'package:flutter/material.dart';

/// Composes the transaction form body: type toggle + amount, then
/// category/date/note plus the conditional goal-link field.
///
/// Pure display widget: owns no state, all values/callbacks are passed in
/// by the screen. Composed from [TransactionTypeAmountFields] and
/// [TransactionCategoryDateNoteFields].
class TransactionFormFields extends StatelessWidget {
  const TransactionFormFields({
    required this.amountController,
    required this.noteController,
    required this.selectedType,
    required this.categoryDisplay,
    required this.loadingCategories,
    required this.selectedDate,
    required this.goalDisplay,
    required this.showGoalLink,
    required this.onTypeChanged,
    required this.onPickCategory,
    required this.onPickDate,
    required this.onPickGoal,
    super.key,
  });

  final TextEditingController amountController;
  final TextEditingController noteController;
  final TransactionType selectedType;
  final String categoryDisplay;
  final bool loadingCategories;
  final DateTime selectedDate;
  final String goalDisplay;
  final bool showGoalLink;
  final ValueChanged<TransactionType> onTypeChanged;
  final VoidCallback onPickCategory;
  final VoidCallback onPickDate;
  final VoidCallback? onPickGoal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TransactionTypeAmountFields(
          amountController: amountController,
          selectedType: selectedType,
          onTypeChanged: onTypeChanged,
        ),
        const SizedBox(height: 12),
        TransactionCategoryDateNoteFields(
          noteController: noteController,
          categoryDisplay: categoryDisplay,
          loadingCategories: loadingCategories,
          selectedDate: selectedDate,
          goalDisplay: goalDisplay,
          showGoalLink: showGoalLink,
          onPickCategory: onPickCategory,
          onPickDate: onPickDate,
          onPickGoal: onPickGoal,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
