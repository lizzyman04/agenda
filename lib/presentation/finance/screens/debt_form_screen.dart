import 'package:agenda/application/finance/debt/debt_cubit.dart';
import 'package:agenda/core/utils/amount_parser.dart';
import 'package:agenda/domain/finance/debt.dart';
import 'package:agenda/domain/finance/debt_direction.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/debt_form_logic.dart';
import 'package:agenda/presentation/finance/widgets/finance_form_primitives.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Form screen for creating or editing a debt.
///
/// Fields: title, amount, direction (SegmentedButton), counterparty, due date.
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
    final amountStr = debt != null
        ? (debt.amountCents / 100).toStringAsFixed(2).replaceAll('.', ',')
        : '';
    _amountController = TextEditingController(text: amountStr);
    _counterpartyController =
        TextEditingController(text: debt?.counterparty ?? '');
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
    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amountCents = parseAmountCentsOrNull(_amountController.text);
    if (amountCents == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context).errorAmountRequired),
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
    final cubit = context.read<DebtCubit>();

    if (_isEditing) {
      await cubit.updateDebt(debt);
    } else {
      await cubit.createDebt(debt);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy');

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
            child: FilledButton(
              onPressed: _save,
              child: Text(l10n.saveDebt),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Direction toggle
            FormCard(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SegmentedButton<DebtDirection>(
                  segments: [
                    ButtonSegment(
                      value: DebtDirection.toPay,
                      label: Text(l10n.toPay),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: DebtDirection.toReceive,
                      label: Text(l10n.toReceive),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {_direction},
                  onSelectionChanged: (s) =>
                      setState(() => _direction = s.first),
                ),
              ),
            ),
            const SizedBox(height: 12),

            FormCard(
              child: Column(
                children: [
                  // Title
                  FieldRow(
                    icon: Icons.title_outlined,
                    child: TextFormField(
                      controller: _titleController,
                      autofocus: !_isEditing,
                      decoration: InputDecoration(
                        labelText: l10n.fieldTitle,
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return l10n.errorTitleRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                  const FieldDivider(),

                  // Amount
                  FieldRow(
                    icon: Icons.attach_money_outlined,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[\d,.]')),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.fieldAmount,
                        hintText: '0,00',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return l10n.errorAmountRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                  const FieldDivider(),

                  // Counterparty
                  FieldRow(
                    icon: Icons.person_outline,
                    child: TextFormField(
                      controller: _counterpartyController,
                      decoration: const InputDecoration(
                        labelText: 'Contraparte',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Informe a contraparte.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const FieldDivider(),

                  // Due date
                  FieldRow(
                    icon: Icons.calendar_today_outlined,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        l10n.fieldDueDate,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      subtitle: Text(
                        dateFormat.format(_dueDate),
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing:
                          const Icon(Icons.edit_calendar_outlined),
                      onTap: _pickDate,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
