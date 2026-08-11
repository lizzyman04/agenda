import 'package:agenda/domain/tasks/size_category.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/form/widgets/form_primitives.dart';
import 'package:flutter/material.dart';

/// Urgent/important switches, size selector, description, and waiting-for
/// notes inside the advanced options card.
///
/// Presentational only: the screen owns [descriptionController] and
/// [waitingForController] and disposes them; this widget never creates or
/// disposes a `TextEditingController`.
class FlagsSizeNotesFields extends StatelessWidget {
  const FlagsSizeNotesFields({
    required this.l10n,
    required this.theme,
    required this.cs,
    required this.isUrgent,
    required this.isImportant,
    required this.sizeCategory,
    required this.descriptionController,
    required this.waitingForController,
    required this.onUrgentChanged,
    required this.onImportantChanged,
    required this.onSizeCategoryChanged,
    super.key,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final ColorScheme cs;
  final bool isUrgent;
  final bool isImportant;
  final SizeCategory sizeCategory;
  final TextEditingController descriptionController;
  final TextEditingController waitingForController;
  final ValueChanged<bool> onUrgentChanged;
  final ValueChanged<bool> onImportantChanged;
  final ValueChanged<SizeCategory> onSizeCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          secondary: Icon(Icons.bolt_outlined, color: cs.error),
          title: Text(l10n.fieldUrgent),
          dense: true,
          value: isUrgent,
          onChanged: onUrgentChanged,
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          secondary: Icon(Icons.star_outline, color: cs.primary),
          title: Text(l10n.fieldImportant),
          dense: true,
          value: isImportant,
          onChanged: onImportantChanged,
        ),
        const FieldDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(l10n.fieldSize,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<SizeCategory>(
            segments: [
              ButtonSegment(
                  value: SizeCategory.big, label: Text(l10n.sizeBig)),
              ButtonSegment(
                  value: SizeCategory.medium, label: Text(l10n.sizeMedium)),
              ButtonSegment(
                  value: SizeCategory.small, label: Text(l10n.sizeSmall)),
              ButtonSegment(
                  value: SizeCategory.none, label: Text(l10n.sizeNone)),
            ],
            selected: {sizeCategory},
            onSelectionChanged: (s) => onSizeCategoryChanged(s.first),
          ),
        ),
        const SizedBox(height: 12),
        const FieldDivider(),
        FieldRow(
          icon: Icons.notes_outlined,
          child: TextFormField(
            controller: descriptionController,
            decoration: InputDecoration(
              labelText: l10n.fieldDescription,
              border: InputBorder.none,
              isDense: true,
            ),
            maxLines: 3,
            minLines: 1,
          ),
        ),
        const FieldDivider(),
        FieldRow(
          icon: Icons.hourglass_empty_outlined,
          child: TextFormField(
            controller: waitingForController,
            decoration: InputDecoration(
              labelText: l10n.fieldWaitingFor,
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
