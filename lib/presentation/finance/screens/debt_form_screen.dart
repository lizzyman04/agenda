import 'package:agenda/application/finance/debt/debt_cubit.dart';
import 'package:agenda/core/utils/amount_parser.dart';
import 'package:agenda/domain/finance/debt/debt.dart';
import 'package:agenda/domain/finance/debt/debt_direction.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/debt_form_logic.dart';
import 'package:agenda/presentation/finance/widgets/debt/debt_direction_toggle.dart';
import 'package:agenda/presentation/finance/widgets/debt/debt_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Form screen for creating or editing a debt (title, amount, direction,
/// counterparty, due date).
class DebtFormScreen extends StatefulWidget {
  const DebtFormScreen({super.key, this.debt});

  final Debt? debt;

  @override
  State<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends State<DebtFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _counterpartyController;
  late DebtDirection _direction;
  late DateTime _dueDate;
  bool get _isEditing => widget.debt != null;

  @override
  void initState() {
    super.initState();
    final debt = widget.debt;
    _titleController = TextEditingController(text: debt?.title ?? '');
    final amountStr =
        debt != null
            ? (debt.amountCents / 100).toStringAsFixed(2).replaceAll('.', ',')
            : '';
    _amountController = TextEditingController(text: amountStr);
    _counterpartyController = TextEditingController(
      text: debt?.counterparty ?? '',
    );
    _direction = debt?.direction ?? DebtDirection.toPay;
    _dueDate = debt?.dueDate ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _counterpartyController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amountCents = parseAmountCentsOrNull(_amountController.text);
    if (amountCents == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorAmountRequired),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final debt = buildDebtToSave(
      isEditing: _isEditing,
      original: widget.debt,
      title: _titleController.text.trim(),
      amountCents: amountCents,
      direction: _direction,
      counterparty: _counterpartyController.text.trim(),
      dueDate: _dueDate,
      now: DateTime.now(),
    );
    await _persist(debt);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _persist(Debt debt) {
    final cubit = context.read<DebtCubit>();
    return _isEditing ? cubit.updateDebt(debt) : cubit.createDebt(debt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.debtsTabLabel : l10n.addDebt,
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(onPressed: _save, child: Text(l10n.saveDebt)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            DebtDirectionToggle(
              direction: _direction,
              onChanged: (d) => setState(() => _direction = d),
            ),
            const SizedBox(height: 12),
            DebtFormFields(
              titleController: _titleController,
              amountController: _amountController,
              counterpartyController: _counterpartyController,
              isEditing: _isEditing,
              dueDate: _dueDate,
              onPickDate: _pickDate,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
