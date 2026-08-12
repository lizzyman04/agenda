import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Builds the `AppBar` for the task form: the title switches between the
/// create and edit labels, and the trailing action triggers save.
///
/// Extracted from `TaskFormScreen.build()` so the screen widget can stay
/// under the architecture line-count limit. Mirrors the finance forms'
/// `*_form_app_bar.dart` helpers.
AppBar buildTaskFormAppBar({
  required BuildContext context,
  required bool isEditing,
  required VoidCallback onSave,
}) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  return AppBar(
    title: Text(
      isEditing ? l10n.taskFormTitleEdit : l10n.taskFormTitleCreate,
      style: theme.textTheme.titleLarge,
    ),
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 1,
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilledButton(onPressed: onSave, child: Text(l10n.saveButton)),
      ),
    ],
  );
}
