import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/form/task_form_fields_model.dart';
import 'package:agenda/presentation/tasks/form/task_form_pickers.dart';
import 'package:agenda/presentation/tasks/form/widgets/form_primitives.dart';
import 'package:flutter/material.dart';

/// Summary row for the task's finance link: shows the linked goal or debt
/// title when one is set, and opens the finance-link sheet on tap.
///
/// Split out of [TaskFormFields] so that widget can stay under the
/// architecture line-count limit. Presentational — every change is routed back
/// through [onModelChanged], matching this slice's README.
class FinanceLinkCard extends StatelessWidget {
  const FinanceLinkCard({
    required this.l10n,
    required this.theme,
    required this.cs,
    required this.model,
    required this.onModelChanged,
    super.key,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final ColorScheme cs;
  final TaskFormFieldsModel model;
  final TaskFormFieldsMutator onModelChanged;

  @override
  Widget build(BuildContext context) {
    final linkedTitle = model.linkedGoalTitle ?? model.linkedDebtTitle;
    return FormCard(
      child: ListTile(
        leading: const Icon(Icons.link_outlined),
        title: Text(
          l10n.linkToFinance,
          style: theme.textTheme.titleSmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        subtitle:
            linkedTitle != null
                ? Text(
                  '${l10n.linkedTo} $linkedTitle',
                  style: theme.textTheme.bodyMedium,
                )
                : null,
        trailing: const Icon(Icons.chevron_right),
        onTap:
            () => pickTaskFinanceLink(
              context: context,
              l10n: l10n,
              model: model,
              mutator: onModelChanged,
            ),
      ),
    );
  }
}
