import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/widgets/finance_form_primitives.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Title/target-amount/deadline card for the goal form screen, built on the
/// shared [FormCard]/[FieldRow]/[FieldDivider] primitives — bringing this
/// form's field layout in line with the other three finance forms, which
/// already use [FieldRow] for their inline field blocks.
///
/// Does not own its controllers; the caller creates and disposes them.
class GoalFormFields extends StatelessWidget {
  const GoalFormFields({
    required this.titleController,
    required this.targetController,
    required this.isEditing,
    required this.deadline,
    required this.onPickDeadline,
    required this.onClearDeadline,
    super.key,
  });

  final TextEditingController titleController;
  final TextEditingController targetController;
  final bool isEditing;
  final DateTime? deadline;
  final VoidCallback onPickDeadline;
  final VoidCallback onClearDeadline;

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
              controller: targetController,
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
            icon: Icons.calendar_today_outlined,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                l10n.fieldDueDate,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              subtitle: Text(
                deadline != null
                    ? dateFormat.format(deadline!)
                    : l10n.noDueDate,
                style: theme.textTheme.bodyMedium,
              ),
              trailing: deadline != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: onClearDeadline,
                    )
                  : const Icon(Icons.edit_calendar_outlined),
              onTap: onPickDeadline,
            ),
          ),
        ],
      ),
    );
  }
}
