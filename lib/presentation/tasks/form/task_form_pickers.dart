import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/form/task_form_fields_model.dart';
import 'package:agenda/presentation/tasks/form/widgets/finance_link_sheet.dart';
import 'package:flutter/material.dart';

/// BuildContext-driven picker helpers for the task form, extracted from
/// [TaskFormFields] so that widget can stay under the architecture
/// line-count limit.
///
/// Each helper applies its result through the caller's [mutator] rather than
/// mutating [model] directly, preserving the "screens own state, widgets take
/// data + callbacks" rule documented in `presentation/tasks/form/README.md`.

/// Prompts for the due date. Clearing the date also clears a monthly
/// recurrence rule, which is only meaningful relative to a chosen day.
Future<void> pickTaskDueDate({
  required BuildContext context,
  required TaskFormFieldsModel model,
  required TaskFormFieldsMutator mutator,
}) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: model.dueDate ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );
  if (picked == null) return;
  mutator((m) {
    m.dueDate = picked;
    if (m.recurrenceRule?.startsWith('FREQ=MONTHLY') ?? false) {
      m.recurrenceRule = null;
    }
  });
}

/// Prompts for the due time. No-op until a due date exists — a time without
/// a date has nothing to anchor to.
Future<void> pickTaskDueTime({
  required BuildContext context,
  required TaskFormFieldsModel model,
  required TaskFormFieldsMutator mutator,
}) async {
  if (model.dueDate == null) return;
  final picked = await showTimePicker(
    context: context,
    initialTime: model.dueTime ?? TimeOfDay.now(),
  );
  if (picked != null) mutator((m) => m.dueTime = picked);
}

/// Presents [FinanceLinkSheet] and applies the returned selection, following
/// the sheet's pop-not-mutate convention.
Future<void> pickTaskFinanceLink({
  required BuildContext context,
  required AppLocalizations l10n,
  required TaskFormFieldsModel model,
  required TaskFormFieldsMutator mutator,
}) async {
  final selection = await showModalBottomSheet<FinanceLinkSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder:
        (_) => FinanceLinkSheet(
          l10n: l10n,
          activeGoals: model.activeGoals,
          activeDebts: model.activeDebts,
          linkedGoalId: model.linkedGoalId,
          linkedDebtId: model.linkedDebtId,
        ),
  );
  if (selection != null) mutator((m) => m.applyFinanceLink(selection));
}
