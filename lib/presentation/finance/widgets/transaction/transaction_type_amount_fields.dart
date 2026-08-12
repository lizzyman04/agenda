import 'package:agenda/domain/finance/transaction_type.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/widgets/finance_form_primitives.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Type toggle (income/expense) plus the amount input field.
///
/// Pure display widget: `amountController` is owned by the caller (the
/// screen creates/disposes it); this widget never reads or mutates state
/// beyond notifying [onTypeChanged].
class TransactionTypeAmountFields extends StatelessWidget {
  const TransactionTypeAmountFields({
    required this.amountController,
    required this.selectedType,
    required this.onTypeChanged,
    super.key,
  });

  final TextEditingController amountController;
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FormCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SegmentedButton<TransactionType>(
              segments: [
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text(l10n.income),
                  icon: const Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text(l10n.expense),
                  icon: const Icon(Icons.arrow_downward),
                ),
              ],
              selected: {selectedType},
              onSelectionChanged: (s) => onTypeChanged(s.first),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FormCard(
          child: FieldRow(
            icon: Icons.attach_money_outlined,
            child: TextFormField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.fieldAmount,
                hintText: '0,00',
                border: InputBorder.none,
                isDense: true,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return l10n.errorAmountRequired;
                }
                final cleaned =
                    val.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '');
                final parsed = double.tryParse(cleaned);
                if (parsed == null || parsed <= 0) {
                  return l10n.errorAmountRequired;
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }
}
