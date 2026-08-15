import 'package:agenda/core/utils/amount_parser.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom-sheet body for setting a category budget limit.
///
/// Owns its own [TextEditingController] so the controller is disposed by the
/// framework in the correct order (after the TextField unmounts). Disposing a
/// controller created in the caller's method scope — right after the sheet's
/// `await` returned — caused a "TextEditingController used after being
/// disposed" error during the dismiss transition, which cascaded into the
/// `InheritedElement._dependents.isEmpty` assertion on the overlay.
///
/// Returns the parsed limit (in cents) via `Navigator.pop` once a valid
/// amount is entered. An empty or unparseable amount does NOT pop the
/// sheet — it shows a validation error and leaves the sheet open so the
/// user can correct the input, instead of silently discarding the save.
class BudgetLimitSheet extends StatefulWidget {
  const BudgetLimitSheet({
    required this.categoryName,
    required this.existingLimitCents,
    super.key,
  });

  final String categoryName;
  final int existingLimitCents;

  @override
  State<BudgetLimitSheet> createState() => BudgetLimitSheetState();
}

class BudgetLimitSheetState extends State<BudgetLimitSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.existingLimitCents > 0
          ? (widget.existingLimitCents / 100)
              .toStringAsFixed(2)
              .replaceAll('.', ',')
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    // Shared parser, not a sixth inline copy. Note: `parseAmountCentsOrNull`
    // currently rejects a PT-BR thousands separator — '1.250,00' becomes
    // '1.250.50' (two dots) and parses to null. That is a known,
    // deliberately deferred defect in amount_parser.dart, not fixed here;
    // this call site's job is only to stop swallowing the rejection.
    final limitCents = parseAmountCentsOrNull(_controller.text);
    if (limitCents == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorAmountRequired),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).pop(limitCents);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 40,
            height: 4,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.categoryName, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            ],
            decoration: InputDecoration(
              labelText: l10n.fieldAmount,
              hintText: '0,00',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            child: Text(l10n.setBudgetLimit),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
