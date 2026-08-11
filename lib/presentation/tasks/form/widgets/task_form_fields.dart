import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/form/task_form_fields_model.dart';
import 'package:agenda/presentation/tasks/form/widgets/advanced_options_card.dart';
import 'package:agenda/presentation/tasks/form/widgets/finance_link_sheet.dart';
import 'package:agenda/presentation/tasks/form/widgets/flags_size_notes_fields.dart';
import 'package:agenda/presentation/tasks/form/widgets/form_primitives.dart';
import 'package:agenda/presentation/tasks/form/widgets/gtd_guide_card.dart';
import 'package:agenda/presentation/tasks/form/widgets/schedule_fields.dart';
import 'package:agenda/presentation/tasks/form/widgets/title_type_card.dart';
import 'package:flutter/material.dart';

/// Applies a mutation to the screen's [TaskFormFieldsModel] inside
/// `setState`.
typedef TaskFormFieldsMutator = void Function(
    void Function(TaskFormFieldsModel model));

/// The task form's scrollable body: title/type, GTD entry point, advanced
/// options, and the finance-link summary.
///
/// Presentational only. [model] is read-only from here; every change goes
/// through [onModelChanged], which the screen wraps in `setState` — this
/// widget never mutates [model] itself, matching the sheet/widget
/// return-a-value convention documented in this slice's README. Date/time
/// pickers and the finance-link sheet only ever touch [model], so they are
/// implemented here rather than delegated back to the screen.
class TaskFormFields extends StatelessWidget {
  const TaskFormFields({
    required this.l10n, required this.theme, required this.cs,
    required this.model, required this.onModelChanged,
    required this.titleController, required this.descriptionController,
    required this.waitingForController, required this.isEditing,
    required this.onOpenGtdGuide,
    super.key,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final ColorScheme cs;
  final TaskFormFieldsModel model;
  final TaskFormFieldsMutator onModelChanged;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController waitingForController;
  final bool isEditing;
  final VoidCallback onOpenGtdGuide;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
        context: context, initialDate: model.dueDate ?? DateTime.now(),
        firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked == null) return;
    onModelChanged((m) {
      m.dueDate = picked;
      if (m.recurrenceRule?.startsWith('FREQ=MONTHLY') ?? false) {
        m.recurrenceRule = null;
      }
    });
  }

  Future<void> _pickTime(BuildContext context) async {
    if (model.dueDate == null) return;
    final picked = await showTimePicker(
        context: context, initialTime: model.dueTime ?? TimeOfDay.now());
    if (picked != null) onModelChanged((m) => m.dueTime = picked);
  }

  Future<void> _pickFinanceLink(BuildContext context) async {
    final selection = await showModalBottomSheet<FinanceLinkSelection>(
      context: context, isScrollControlled: true, useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => FinanceLinkSheet(
          l10n: l10n, activeGoals: model.activeGoals,
          activeDebts: model.activeDebts, linkedGoalId: model.linkedGoalId,
          linkedDebtId: model.linkedDebtId),
    );
    if (selection != null) onModelChanged((m) => m.applyFinanceLink(selection));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        TitleTypeCard(
            l10n: l10n, theme: theme, titleController: titleController,
            isEditing: isEditing, itemType: model.itemType,
            onItemTypeChanged: (v) => onModelChanged((m) => m.itemType = v)),
        const SizedBox(height: 12),
        if (!isEditing) ...[
          GtdGuideCard(onTap: onOpenGtdGuide, colorScheme: cs, theme: theme,
              label: l10n.gtdGuide),
          const SizedBox(height: 12),
        ],
        AdvancedOptionsCard(
          expanded: model.advancedExpanded,
          onToggle: () =>
              onModelChanged((m) => m.advancedExpanded = !m.advancedExpanded),
          label: l10n.advancedOptions,
          theme: theme,
          cs: cs,
          children: [
            ScheduleFields(
                l10n: l10n, theme: theme, cs: cs, priority: model.priority,
                dueDate: model.dueDate, dueTime: model.dueTime,
                recurrenceRule: model.recurrenceRule,
                onPriorityChanged: (v) => onModelChanged((m) => m.priority = v),
                onPickDate: () => _pickDate(context),
                onClearDate: () => onModelChanged((m) {
                      m.dueDate = null;
                      m.dueTime = null;
                      m.recurrenceRule = null;
                    }),
                onPickTime: () => _pickTime(context),
                onRecurrenceChanged: (v) =>
                    onModelChanged((m) => m.recurrenceRule = v)),
            const FieldDivider(),
            FlagsSizeNotesFields(
                l10n: l10n, theme: theme, cs: cs, isUrgent: model.isUrgent,
                isImportant: model.isImportant, sizeCategory: model.sizeCategory,
                descriptionController: descriptionController,
                waitingForController: waitingForController,
                onUrgentChanged: (v) => onModelChanged((m) => m.isUrgent = v),
                onImportantChanged: (v) =>
                    onModelChanged((m) => m.isImportant = v),
                onSizeCategoryChanged: (v) =>
                    onModelChanged((m) => m.sizeCategory = v)),
          ],
        ),
        const SizedBox(height: 12),
        FormCard(
          child: ListTile(
            leading: const Icon(Icons.link_outlined),
            title: Text(l10n.linkToFinance,
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
            subtitle: (model.linkedGoalTitle ?? model.linkedDebtTitle) != null
                ? Text(
                    '${l10n.linkedTo} ${model.linkedGoalTitle ?? model.linkedDebtTitle}',
                    style: theme.textTheme.bodyMedium)
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickFinanceLink(context),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
