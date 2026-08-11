import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/form/widgets/form_primitives.dart';
import 'package:flutter/material.dart';

/// Title field plus the task/project type toggle at the top of the form.
///
/// Presentational only: the screen owns [titleController] and disposes it;
/// this widget merely renders it and reports selection changes.
class TitleTypeCard extends StatelessWidget {
  const TitleTypeCard({
    required this.l10n,
    required this.theme,
    required this.titleController,
    required this.isEditing,
    required this.itemType,
    required this.onItemTypeChanged,
    super.key,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final TextEditingController titleController;
  final bool isEditing;
  final ItemType itemType;
  final ValueChanged<ItemType> onItemTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormCard(
          child: TextFormField(
            controller: titleController,
            autofocus: !isEditing,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: l10n.fieldTitle,
              hintText: l10n.gtdQ1,
              prefixIcon: const Icon(Icons.title_outlined),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.fieldTitleRequired;
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 12),
        FormCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SegmentedButton<ItemType>(
              segments: [
                ButtonSegment(
                  value: ItemType.task,
                  label: Text(l10n.typeTask),
                  icon: const Icon(Icons.task_alt_outlined),
                ),
                ButtonSegment(
                  value: ItemType.project,
                  label: Text(l10n.typeProject),
                  icon: const Icon(Icons.folder_outlined),
                ),
              ],
              selected: {itemType},
              onSelectionChanged: (s) => onItemTypeChanged(s.first),
            ),
          ),
        ),
      ],
    );
  }
}
