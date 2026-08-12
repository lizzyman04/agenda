import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/widgets/finance_form_primitives.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Category/date/note fields plus the conditional goal-link field.
///
/// Pure display widget: `noteController` is owned by the caller; all other
/// values are already-resolved display strings/flags, and every
/// interaction is routed back through the `onPick*` callbacks.
class TransactionCategoryDateNoteFields extends StatelessWidget {
  const TransactionCategoryDateNoteFields({
    required this.noteController,
    required this.categoryDisplay,
    required this.loadingCategories,
    required this.selectedDate,
    required this.goalDisplay,
    required this.showGoalLink,
    required this.onPickCategory,
    required this.onPickDate,
    required this.onPickGoal,
    super.key,
  });

  final TextEditingController noteController;
  final String categoryDisplay;
  final bool loadingCategories;
  final DateTime selectedDate;
  final String goalDisplay;
  final bool showGoalLink;
  final VoidCallback onPickCategory;
  final VoidCallback onPickDate;

  /// `null` disables the goal-link row (matches the pre-existing
  /// `_activeGoals.isNotEmpty ? _pickGoal : null` guard).
  final VoidCallback? onPickGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FormCard(
          child: Column(
            children: [
              FieldRow(
                icon: Icons.category_outlined,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    l10n.fieldCategory,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  subtitle: Text(
                    categoryDisplay,
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: loadingCategories
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
                    dateFormat.format(selectedDate),
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: onPickDate,
                ),
              ),
              const FieldDivider(),
              FieldRow(
                icon: Icons.notes_outlined,
                child: TextFormField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: l10n.fieldNote,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),
              ),
            ],
          ),
        ),
        if (showGoalLink) ...[
          const SizedBox(height: 12),
          FormCard(
            child: FieldRow(
              icon: Icons.savings_outlined,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  l10n.linkToFinance,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                subtitle: Text(
                  goalDisplay,
                  style: theme.textTheme.bodyMedium,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: onPickGoal,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
