import 'package:agenda/presentation/finance/widgets/transaction/transaction_form_app_bar.dart';
import 'package:flutter/material.dart';

/// Chrome for the transaction form: surface colour, app bar, and the scrolling
/// [Form] that hosts [fields].
///
/// Extracted from `TransactionFormScreen.build()` so the screen widget can
/// stay under the architecture line-count limit. Presentational only — it owns
/// no state and reads nothing from [fields]; the screen still owns [formKey]
/// so it can validate before saving.
class TransactionFormScaffold extends StatelessWidget {
  const TransactionFormScaffold({
    required this.formKey,
    required this.isEditing,
    required this.onSave,
    required this.fields,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final bool isEditing;
  final VoidCallback onSave;
  final Widget fields;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: buildTransactionFormAppBar(
        context: context,
        isEditing: isEditing,
        onSave: onSave,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [fields],
        ),
      ),
    );
  }
}
