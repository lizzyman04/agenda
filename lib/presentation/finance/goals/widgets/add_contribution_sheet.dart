import 'package:agenda/domain/finance/savings_goal_contribution.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Bottom-sheet body for adding a contribution to a savings goal.
///
/// Owns its own [TextEditingController]s so they are disposed by the framework
/// in the correct order (after the TextFields unmount). Disposing controllers
/// created in the caller's method scope — right after the sheet's `await`
/// returned — caused a "TextEditingController used after being disposed" error
/// during the dismiss transition, which cascaded into the
/// `InheritedElement._dependents.isEmpty` assertion on the overlay. Same defect
/// and same fix as the budget limit sheet in `budget_overview_screen.dart`.
///
/// Returns the built [SavingsGoalContribution] via `Navigator.pop`, or `null`
/// when the amount is empty/invalid. The caller applies the mutation once the
/// sheet has closed, so no cubit emit races the teardown.
///
/// Presentation-only: takes no cubit and performs no persistence.
class AddContributionSheet extends StatefulWidget {
  const AddContributionSheet({super.key});

  @override
  State<AddContributionSheet> createState() => _AddContributionSheetState();
}

class _AddContributionSheetState extends State<AddContributionSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _amountCtrl.text
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^\d.]'), '');
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      Navigator.of(context).pop();
      return;
    }
    final note = _noteCtrl.text.trim();
    Navigator.of(context).pop(
      SavingsGoalContribution(
        amountCents: (parsed * 100).round(),
        date: _selectedDate,
        note: note.isNotEmpty ? note : null,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
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
          Text(l10n.addContribution, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: l10n.fieldNote,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _submit,
            child: Text(l10n.addContribution),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
