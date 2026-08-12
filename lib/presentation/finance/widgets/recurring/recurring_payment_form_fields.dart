import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/recurring/recurring_cycle.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/widgets/finance_form_primitives.dart';
import 'package:agenda/presentation/finance/widgets/recurring/recurring_payment_schedule_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The title/amount/category/cycle/next-due-date card for the recurring
/// payment form, composed from the shared [FormCard]/[FieldRow]/
/// [FieldDivider] primitives.
///
/// Does not own its controllers — the caller creates/disposes
/// [titleController] and [amountController] and reacts to field changes
/// via the provided callbacks.
class RecurringPaymentFormFields extends StatelessWidget {
  const RecurringPaymentFormFields({
    required this.titleController,
    required this.amountController,
    required this.isEditing,
    required this.cycle,
    required this.selectedCategory,
    required this.categoryFallbackLabel,
    required this.loadingCategories,
    required this.nextDueDate,
    required this.onPickCategory,
    required this.onCycleChanged,
    required this.onPickDate,
    super.key,
  });

  final TextEditingController titleController;
  final TextEditingController amountController;
  final bool isEditing;
  final RecurringCycle cycle;
  final TransactionCategory? selectedCategory;
  final String categoryFallbackLabel;
  final bool loadingCategories;
  final DateTime nextDueDate;
  final VoidCallback onPickCategory;
  final ValueChanged<RecurringCycle> onCycleChanged;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final locale = Localizations.localeOf(context);
    final category = selectedCategory;
    final categoryDisplay =
        category != null
            ? (locale.languageCode == 'en' && category.nameEn != null
                ? category.nameEn!
                : category.namePtBr)
            : categoryFallbackLabel;

    return FormCard(
      child: Column(
        children: [
          FieldRow(
            icon: Icons.title_outlined,
            child: TextFormField(
              controller: titleController,
              autofocus: !isEditing,
              decoration: InputDecoration(
                labelText: l10n.fieldTitle,
                border: InputBorder.none,
                isDense: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              validator:
                  (val) =>
                      (val == null || val.trim().isEmpty)
                          ? l10n.errorTitleRequired
                          : null,
            ),
          ),
          const FieldDivider(),
          FieldRow(
            icon: Icons.attach_money_outlined,
            child: TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.fieldAmount,
                hintText: '0,00',
                border: InputBorder.none,
                isDense: true,
              ),
              validator:
                  (val) =>
                      (val == null || val.trim().isEmpty)
                          ? l10n.errorAmountRequired
                          : null,
            ),
          ),
          const FieldDivider(),
          FieldRow(
            icon: Icons.category_outlined,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                l10n.fieldCategory,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              subtitle: Text(
                categoryDisplay,
                style: theme.textTheme.bodyMedium,
              ),
              trailing:
                  loadingCategories
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.chevron_right),
              onTap: loadingCategories ? null : onPickCategory,
            ),
          ),
          const FieldDivider(),
          RecurringPaymentScheduleFields(
            cycle: cycle,
            nextDueDate: nextDueDate,
            onCycleChanged: onCycleChanged,
            onPickDate: onPickDate,
          ),
        ],
      ),
    );
  }
}
