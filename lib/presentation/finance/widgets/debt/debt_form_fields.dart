import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/widgets/finance_form_primitives.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Title/amount/counterparty/due-date card for the debt form.
///
/// Controllers are owned by the caller (not created or disposed here).
class DebtFormFields extends StatelessWidget {
  const DebtFormFields({
    required this.titleController,
    required this.amountController,
    required this.counterpartyController,
    required this.isEditing,
    required this.dueDate,
    required this.onPickDate,
    super.key,
  });

  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController counterpartyController;
  final bool isEditing;
  final DateTime dueDate;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy');

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
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return l10n.errorTitleRequired;
                }
                return null;
              },
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
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return l10n.errorAmountRequired;
                }
                return null;
              },
            ),
          ),
          const FieldDivider(),
          FieldRow(
            icon: Icons.person_outline,
            child: TextFormField(
              controller: counterpartyController,
              decoration: const InputDecoration(
                labelText: 'Contraparte',
                border: InputBorder.none,
                isDense: true,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Informe a contraparte.';
                }
                return null;
              },
            ),
          ),
          const FieldDivider(),
          FieldRow(
            icon: Icons.calendar_today_outlined,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                l10n.fieldDueDate,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              subtitle: Text(
                dateFormat.format(dueDate),
                style: theme.textTheme.bodyMedium,
              ),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: onPickDate,
            ),
          ),
        ],
      ),
    );
  }
}
