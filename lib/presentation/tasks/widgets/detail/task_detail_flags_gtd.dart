import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/widgets/detail/task_detail_chips.dart';
import 'package:agenda/presentation/tasks/widgets/detail/task_detail_section_card.dart';
import 'package:flutter/material.dart';

/// Flags card and GTD card for the task detail screen. Grouped in one file
/// because each is small and none is meaningful alone; each renders nothing
/// when its condition isn't met, so callers can place them unconditionally
/// in a `Column`.

/// Urgent/important/next-action flag chips, when any is set.
class TaskDetailFlagsCard extends StatelessWidget {
  const TaskDetailFlagsCard({required this.item, super.key});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final hasFlags = item.isUrgent || item.isImportant || item.isNextAction;
    if (!hasFlags) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SectionCard(
        icon: Icons.label_outline,
        title: 'Flags',
        cs: cs,
        theme: theme,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.isUrgent)
                  FlagChip(
                    label: l10n.fieldUrgent,
                    icon: Icons.bolt,
                    backgroundColor: cs.errorContainer,
                    foregroundColor: cs.onErrorContainer,
                  ),
                if (item.isImportant)
                  FlagChip(
                    label: l10n.fieldImportant,
                    icon: Icons.star,
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                  ),
                if (item.isNextAction)
                  FlagChip(
                    label: l10n.fieldNextAction,
                    icon: Icons.arrow_forward,
                    backgroundColor: cs.secondaryContainer,
                    foregroundColor: cs.onSecondaryContainer,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// GTD context/waiting-for card, when either is set.
class TaskDetailGtdCard extends StatelessWidget {
  const TaskDetailGtdCard({required this.item, super.key});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final hasGtd = (item.gtdContext != null && item.gtdContext!.isNotEmpty) ||
        (item.waitingFor != null && item.waitingFor!.isNotEmpty);
    if (!hasGtd) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SectionCard(
        icon: Icons.psychology_outlined,
        title: 'GTD',
        cs: cs,
        theme: theme,
        children: [
          if (item.gtdContext != null && item.gtdContext!.isNotEmpty)
            DetailRow(
              icon: Icons.tag_outlined,
              label: l10n.fieldGtdContext,
              value: item.gtdContext!,
              theme: theme,
              cs: cs,
            ),
          if (item.waitingFor != null && item.waitingFor!.isNotEmpty)
            DetailRow(
              icon: Icons.hourglass_empty_outlined,
              label: l10n.fieldWaitingFor,
              value: item.waitingFor!,
              theme: theme,
              cs: cs,
            ),
        ],
      ),
    );
  }
}
