import 'package:agenda/application/finance/recurring/recurring_payment_cubit.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/recurring_cycle.dart';
import 'package:agenda/domain/finance/recurring_payment.dart';
import 'package:agenda/domain/finance/transaction_category.dart';
import 'package:agenda/domain/finance/transaction_category_repository.dart';
import 'package:agenda/domain/finance/transaction_type.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
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
    final amountStr = payment != null
        ? (payment.amountCents / 100)
            .toStringAsFixed(2)
            .replaceAll('.', ',')
        : '';
    _amountController = TextEditingController(text: amountStr);
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
    final repo = getIt<TransactionCategoryRepository>();
    final result = await repo.getByType(TransactionType.expense);
    if (result is Success<List<TransactionCategory>> && mounted) {
      setState(() {
        _expenseCategories = result.value;
        _loadingCategories = false;
        if (preselectedId != null) {
          try {
            _selectedCategory = _expenseCategories
                .firstWhere((c) => c.id == preselectedId);
          } catch (_) {}
        }
      });
    } else {
      if (mounted) setState(() => _loadingCategories = false);
    }
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
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollCtrl) => ListView.builder(
          controller: scrollCtrl,
          itemCount: _expenseCategories.length,
          itemBuilder: (_, i) {
            final cat = _expenseCategories[i];
            final name =
                locale.languageCode == 'en' && cat.nameEn != null
                    ? cat.nameEn!
                    : cat.namePtBr;
            return ListTile(
              title: Text(name),
              trailing: _selectedCategory?.id == cat.id
                  ? Icon(Icons.check,
                      color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(ctx).pop(cat),
            );
          },
        ),
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
          content:
              Text(AppLocalizations.of(context).errorCategoryRequired),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final raw = _amountController.text
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^\d.]'), '');
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context).errorAmountRequired),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final amountCents = (parsed * 100).round();
    final now = DateTime.now();
    final cubit = context.read<RecurringPaymentCubit>();

    if (_isEditing) {
      final updated = widget.payment!.copyWith(
        title: _titleController.text.trim(),
        amountCents: amountCents,
        categoryId: _selectedCategory!.id,
        cycle: _cycle,
        nextDueDate: _nextDueDate,
        updatedAt: now,
      );
      await cubit.updatePayment(updated);
    } else {
      final payment = RecurringPayment(
        id: 0,
        title: _titleController.text.trim(),
        amountCents: amountCents,
        categoryId: _selectedCategory!.id,
        cycle: _cycle,
        nextDueDate: _nextDueDate,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
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
        ? (locale.languageCode == 'en' &&
                _selectedCategory!.nameEn != null
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _FormCard(
              child: Column(
                children: [
                  // Title
                  _FieldRow(
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
                  const _FieldDivider(),

                  // Amount
                  _FieldRow(
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
                  const _FieldDivider(),

                  // Category
                  _FieldRow(
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
                  const _FieldDivider(),

                  // Cycle
                  _FieldRow(
                    icon: Icons.repeat_outlined,
                    child: DropdownButtonFormField<RecurringCycle>(
                      value: _cycle,
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
                  const _FieldDivider(),

                  // Next due date
                  _FieldRow(
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

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.icon, required this.child});
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 48, endIndent: 16);
  }
}
