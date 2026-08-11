import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_answers.dart';
import 'package:agenda/presentation/tasks/form/gtd/widgets/gtd_atoms.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Terminal step of the GTD guide: a summary of everything the tree decided,
/// with the option to go back and edit or to save.
///
/// Presentation only — reads [answers] and reports intent through [onEdit] and
/// [onSave].
class GtdReviewNode extends StatelessWidget {
  const GtdReviewNode({
    required this.title,
    required this.answers,
    required this.l10n,
    required this.onEdit,
    required this.onSave,
    super.key,
  });

  final String title;
  final GtdAnswers answers;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fmt = DateFormat('dd/MM/yyyy');
    final dueDate = answers.dueDate;
    final waitingFor = answers.waitingFor;
    final gtdContext = answers.gtdContext;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GtdIconBox(
              icon: Icons.checklist,
              background: cs.tertiaryContainer,
              foreground: cs.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.gtdReviewTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                GtdReviewRow(
                  icon: Icons.title,
                  label: 'Título',
                  value: title,
                ),
                const GtdRowDivider(),
                GtdReviewRow(
                  icon: Icons.calendar_today,
                  label: l10n.gtdReviewDeadlineLabel,
                  value: dueDate != null
                      ? fmt.format(dueDate)
                      : l10n.gtdDeadlineNoDeadline,
                ),
                const GtdRowDivider(),
                GtdReviewRow(
                  icon: Icons.priority_high,
                  label: l10n.gtdReviewPriorityLabel,
                  value: answers.priorityLabel,
                ),
                const GtdRowDivider(),
                GtdReviewRow(
                  icon: Icons.star,
                  label: l10n.gtdReviewImportantLabel,
                  value: answers.isImportant
                      ? l10n.gtdAnswerYes
                      : l10n.gtdAnswerNo,
                ),
                const GtdRowDivider(),
                GtdReviewRow(
                  icon: Icons.bolt,
                  label: l10n.gtdReviewUrgentLabel,
                  value:
                      answers.isUrgent ? l10n.gtdAnswerYes : l10n.gtdAnswerNo,
                ),
                if (waitingFor != null) ...[
                  const GtdRowDivider(),
                  GtdReviewRow(
                    icon: Icons.person,
                    label: l10n.gtdReviewDelegatedLabel,
                    value: waitingFor,
                  ),
                ],
                if (gtdContext != null) ...[
                  const GtdRowDivider(),
                  GtdReviewRow(
                    icon: Icons.tag,
                    label: 'Contexto',
                    value: gtdContext,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onEdit,
                child: Text(l10n.gtdReviewEdit),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onSave,
                child: Text(l10n.gtdReviewSave),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
