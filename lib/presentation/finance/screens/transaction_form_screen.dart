import 'package:agenda/application/finance/transaction/transaction_cubit.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/utils/amount_parser.dart';
import 'package:agenda/domain/finance/goal_repository.dart';
import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/domain/finance/transaction_category.dart';
import 'package:agenda/domain/finance/transaction_category_repository.dart';
import 'package:agenda/domain/finance/transaction_type.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/transaction_form_logic.dart';
import 'package:agenda/presentation/finance/widgets/category_picker_sheet.dart';
import 'package:agenda/presentation/finance/widgets/finance_form_primitives.dart';
import 'package:agenda/presentation/finance/widgets/transaction/goal_link_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Form screen for creating or editing a financial transaction.
///
/// Fields: type toggle (income/expense), amount, category (BottomSheet picker),
/// date picker, optional note, optional goal link (if expense).
class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, this.transaction});

  /// If non-null, the form is in edit mode pre-filled with [transaction].
  final Transaction? transaction;

  @override
  State<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late TransactionType _selectedType;
  TransactionCategory? _selectedCategory;
  late DateTime _selectedDate;
  int? _selectedGoalId;

  List<TransactionCategory> _allCategories = [];
  List<SavingsGoal> _activeGoals = [];
  bool _loadingCategories = false;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;

    // Pre-fill amount: convert cents to decimal string
    _amountController =
        TextEditingController(text: formatCentsForInput(tx?.amountCents ?? 0));
    _noteController = TextEditingController(text: tx?.note ?? '');

    _selectedType = tx?.type ?? TransactionType.income;
    _selectedDate = tx?.date ?? DateTime.now();
    _selectedGoalId = tx?.linkedGoalId;

    _loadFormData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() => _loadingCategories = true);
    final data = await loadTransactionFormData(
      getIt<TransactionCategoryRepository>(),
      getIt<GoalRepository>(),
      preselectedCategoryId: widget.transaction?.categoryId,
    );
    if (!mounted) return;
    setState(() {
      _allCategories = data.categories;
      _activeGoals = data.activeGoals;
      _loadingCategories = false;
      if (widget.transaction != null && _selectedCategory == null) {
        _selectedCategory = data.preselectedCategory;
      }
    });
  }

  List<TransactionCategory> get _filteredCategories => _allCategories
      .where((c) => c.type == _selectedType)
      .toList();

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
        categories: _filteredCategories,
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
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickGoal() async {
    if (_activeGoals.isEmpty) return;
    final picked = await showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => GoalLinkPickerSheet(
        activeGoals: _activeGoals,
        selectedGoalId: _selectedGoalId,
      ),
    );
    // `picked` is null both when the user chose "Sem vínculo" and when the
    // sheet is dismissed by the back button — matches the pre-existing
    // showModalBottomSheet contract.
    if (mounted) {
      setState(() => _selectedGoalId = picked);
    }
  }

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

    final tx = buildTransactionToSave(
      isEditing: _isEditing,
      original: widget.transaction,
      type: _selectedType,
      amountCents: amountCents,
      categoryId: _selectedCategory!.id,
      date: _selectedDate,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
      linkedGoalId: _selectedGoalId,
      now: DateTime.now(),
    );

    final cubit = context.read<TransactionCubit>();
    if (_isEditing) {
      await cubit.updateTransaction(tx);
    } else {
      await cubit.createTransaction(tx);
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

    final categoryDisplay = _selectedCategory != null
        ? (Localizations.localeOf(context).languageCode == 'en' &&
                _selectedCategory!.nameEn != null
            ? _selectedCategory!.nameEn!
            : _selectedCategory!.namePtBr)
        : l10n.fieldCategory;

    final goalDisplay = _selectedGoalId != null
        ? (_activeGoals
                .where((g) => g.id == _selectedGoalId)
                .map((g) => g.title)
                .firstOrNull ??
            '#$_selectedGoalId')
        : 'Sem vínculo';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.editTransaction : l10n.addTransaction,
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
              child: Text(l10n.saveTransaction),
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
            // Type toggle
            FormCard(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SegmentedButton<TransactionType>(
                  segments: [
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text(l10n.income),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text(l10n.expense),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (s) {
                    setState(() {
                      _selectedType = s.first;
                      // Clear category when type changes
                      _selectedCategory = null;
                      // Clear goal link when switching to income
                      if (_selectedType == TransactionType.income) {
                        _selectedGoalId = null;
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Amount + Category + Date + Note card
            FormCard(
              child: Column(
                children: [
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
                        final cleaned = val
                            .replaceAll(',', '.')
                            .replaceAll(RegExp(r'[^\d.]'), '');
                        final parsed = double.tryParse(cleaned);
                        if (parsed == null || parsed <= 0) {
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
                        categoryDisplay,
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: _loadingCategories
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _loadingCategories ? null : _pickCategory,
                    ),
                  ),
                  const FieldDivider(),

                  // Date
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
                        dateFormat.format(_selectedDate),
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: _pickDate,
                    ),
                  ),
                  const FieldDivider(),

                  // Note
                  FieldRow(
                    icon: Icons.notes_outlined,
                    child: TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: l10n.fieldNote,
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      maxLines: 2,
                      minLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Goal link (expense only)
            if (_selectedType == TransactionType.expense) ...[
              FormCard(
                child: FieldRow(
                  icon: Icons.savings_outlined,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      l10n.linkToFinance,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    subtitle: Text(
                      goalDisplay,
                      style: theme.textTheme.bodyMedium,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _activeGoals.isNotEmpty ? _pickGoal : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
