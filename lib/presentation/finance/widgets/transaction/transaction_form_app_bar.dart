import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Builds the `AppBar` for the transaction form: the title switches between
/// "add" and "edit" labels, and the trailing action triggers save.
///
/// Extracted from `TransactionFormScreen.build()` so the screen widget can
/// stay under the architecture line-count limit. Mirrors
/// `recurring/recurring_payment_form_app_bar.dart`.
AppBar buildTransactionFormAppBar({
  required BuildContext context,
  required bool isEditing,
  required VoidCallback onSave,
}) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  return AppBar(
    title: Text(
      isEditing ? l10n.editTransaction : l10n.addTransaction,
      style: theme.textTheme.titleLarge,
    ),
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 1,
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilledButton(
          onPressed: onSave,
          child: Text(l10n.saveTransaction),
        ),
      ),
    ],
  );
}
