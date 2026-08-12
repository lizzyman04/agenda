import 'package:agenda/application/finance/recurring/recurring_payment_cubit.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/utils/amount_parser.dart';
import 'package:agenda/domain/finance/recurring_cycle.dart';
import 'package:agenda/domain/finance/recurring_payment.dart';
import 'package:agenda/domain/finance/transaction_category.dart';
import 'package:agenda/domain/finance/transaction_category_repository.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/recurring_payment_form_logic.dart';
import 'package:agenda/presentation/finance/widgets/category_picker_sheet.dart';
import 'package:agenda/presentation/finance/widgets/finance_form_primitives.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Form screen for creating or editing a recurring payment.
///
/// Fields: title, amount, category (expense only), cycle, next due date.
class RecurringPaymentFormScreen extends StatefulWidget {
  const RecurringPaymentFormScreen({super.key, this.payment});

  final RecurringPayment? payment;

  @override
  State<RecurringPaymentFormScreen> createState() =>
      _RecurringPaymentFormScreenState();
}

class _RecurringPaymentFormScreenState
    extends State<RecurringPaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;

  late RecurringCycle _cycle;
  late DateTime _nextDueDate;
  TransactionCategory? _selectedCategory;

  List<TransactionCategory> _expenseCategories = [];
  bool _loadingCategories = false;

  bool get _isEditing => widget.payment != null;

  @override
  void initState() {
    super.initState();
    final payment = widget.payment;
    _titleController = TextEditingController(text: payment?.title ?? '');
    _amountController = TextEditingController(
      text: payment != null ? formatCentsForInput(payment.amountCents) : '',
    );
    _cycle = payment?.cycle ?? RecurringCycle.monthly;
    _nextDueDate = payment?.nextDueDate ??
        DateTime.now().add(const Duration(days: 30));
    _loadCategories(payment?.categoryId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories(int? preselectedId) async {
    setState(() => _loadingCategories = true);
    final categories =
        await loadExpenseCategories(getIt<TransactionCategoryRepository>());
    if (!mounted) return;
    setState(() {
      _expenseCategories = categories;
      _loadingCategories = false;
      if (preselectedId != null) {
        try {
          _selectedCategory =
              _expenseCategories.firstWhere((c) => c.id == preselectedId);
        } catch (_) {}
      }
    });
  }

  Future<void> _pickCategory() async {
    final locale = Localizations.localeOf(context);
    final picked = await showModalBottomSheet<TransactionCategory>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CategoryPickerSheet(
        categories: _expenseCategories,
        selectedCategoryId: _selectedCategory?.id,
        locale: locale,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedCategory = picked);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _nextDueDate = picked);
    }
  }

  String _cycleLabel(RecurringCycle cycle) => switch (cycle) {
        RecurringCycle.daily => 'Diário',
        RecurringCycle.weekly => 'Semanal',
        RecurringCycle.biweekly => 'Quinzenal',
        RecurringCycle.monthly => 'Mensal',
        RecurringCycle.quarterly => 'Trimestral',
        RecurringCycle.yearly => 'Anual',
      };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorCategoryRequired),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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

    final now = DateTime.now();
    final payment = buildRecurringPaymentToSave(
      isEditing: _isEditing,
      original: widget.payment,
      title: _titleController.text.trim(),
      amountCents: amountCents,
      categoryId: _selectedCategory!.id,
      cycle: _cycle,
      nextDueDate: _nextDueDate,
      now: now,
    );

    final cubit = context.read<RecurringPaymentCubit>();
    if (_isEditing) {
      await cubit.updatePayment(payment);
    } else {
      await cubit.createPayment(payment);
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
    final locale = Localizations.localeOf(context);

    final catDisplay = _selectedCategory != null
        ? (locale.languageCode == 'en' && _selectedCategory!.nameEn != null
            ? _selectedCategory!.nameEn!
            : _selectedCategory!.namePtBr)
        : l10n.fieldCategory;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.recurringTabLabel : l10n.addRecurring,
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
              child: Text(l10n.saveRecurringPayment),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
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

                  // Category
                  FieldRow(
                    icon: Icons.category_outlined,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        l10n.fieldCategory,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      subtitle: Text(
                        catDisplay,
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: _loadingCategories
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap:
                          _loadingCategories ? null : _pickCategory,
                    ),
                  ),
                  const FieldDivider(),

                  // Cycle
                  FieldRow(
                    icon: Icons.repeat_outlined,
                    child: DropdownButtonFormField<RecurringCycle>(
                      initialValue: _cycle,
                      decoration: const InputDecoration(
                        labelText: 'Ciclo',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      items: RecurringCycle.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(_cycleLabel(c)),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _cycle = val);
                      },
                    ),
                  ),
                  const FieldDivider(),

                  // Next due date
                  FieldRow(
                    icon: Icons.calendar_today_outlined,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        'Próximo vencimento',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      subtitle: Text(
                        dateFormat.format(_nextDueDate),
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
