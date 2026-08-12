import 'package:agenda/application/finance/recurring/recurring_payment_cubit.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/utils/amount_parser.dart';
import 'package:agenda/domain/finance/recurring_cycle.dart';
import 'package:agenda/domain/finance/recurring_payment.dart';
import 'package:agenda/domain/finance/transaction_category.dart';
import 'package:agenda/domain/finance/transaction_category_repository.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/recurring_payment_form_logic.dart';
import 'package:agenda/presentation/finance/widgets/recurring/recurring_payment_form_app_bar.dart';
import 'package:agenda/presentation/finance/widgets/recurring/recurring_payment_form_fields.dart';
import 'package:agenda/presentation/finance/widgets/recurring/recurring_payment_form_pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Form screen for creating or editing a recurring payment.
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
        text: payment != null ? formatCentsForInput(payment.amountCents) : '');
    _cycle = payment?.cycle ?? RecurringCycle.monthly;
    _nextDueDate =
        payment?.nextDueDate ?? DateTime.now().add(const Duration(days: 30));
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
      _selectedCategory =
          findCategoryById(categories, preselectedId) ?? _selectedCategory;
    });
  }

  Future<void> _pickCategory() async {
    final picked = await pickExpenseCategory(
        context: context,
        categories: _expenseCategories,
        selectedCategoryId: _selectedCategory?.id);
    if (picked != null && mounted) setState(() => _selectedCategory = picked);
  }

  Future<void> _pickDate() async {
    final picked = await pickNextDueDate(context, _nextDueDate);
    if (picked != null && mounted) setState(() => _nextDueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    if (_selectedCategory == null) {
      return showFormError(context, l10n.errorCategoryRequired);
    }
    final amountCents = parseAmountCentsOrNull(_amountController.text);
    if (amountCents == null) {
      return showFormError(context, l10n.errorAmountRequired);
    }
    final payment = buildRecurringPaymentToSave(
      isEditing: _isEditing, original: widget.payment,
      title: _titleController.text.trim(), amountCents: amountCents,
      categoryId: _selectedCategory!.id, cycle: _cycle,
      nextDueDate: _nextDueDate, now: DateTime.now(),
    );
    await _persist(payment);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _persist(RecurringPayment payment) {
    final cubit = context.read<RecurringPaymentCubit>();
    return _isEditing
        ? cubit.updatePayment(payment)
        : cubit.createPayment(payment);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: buildRecurringPaymentFormAppBar(
          context: context, isEditing: _isEditing, onSave: _save),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            RecurringPaymentFormFields(
              titleController: _titleController,
              amountController: _amountController,
              isEditing: _isEditing,
              cycle: _cycle,
              selectedCategory: _selectedCategory,
              categoryFallbackLabel: l10n.fieldCategory,
              loadingCategories: _loadingCategories,
              nextDueDate: _nextDueDate,
              onPickCategory: _pickCategory,
              onCycleChanged: (val) => setState(() => _cycle = val),
              onPickDate: _pickDate,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
