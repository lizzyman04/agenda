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
import 'package:agenda/presentation/finance/widgets/transaction/goal_link_picker_sheet.dart';
import 'package:agenda/presentation/finance/widgets/transaction/transaction_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Form screen for creating/editing a transaction; see
/// `transaction_form_logic.dart` for load/save logic.
class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, this.transaction});
  final Transaction? transaction;
  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController, _noteController;
  late TransactionType _selectedType; TransactionCategory? _selectedCategory;
  late DateTime _selectedDate; int? _selectedGoalId;
  List<TransactionCategory> _allCategories = [];
  List<SavingsGoal> _activeGoals = [];
  bool _loadingCategories = false;
  bool get _isEditing => widget.transaction != null;
  List<TransactionCategory> get _filteredCategories =>
      _allCategories.where((c) => c.type == _selectedType).toList();
  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _amountController = TextEditingController(text: formatCentsForInput(tx?.amountCents ?? 0));
    _noteController = TextEditingController(text: tx?.note ?? '');
    _selectedType = tx?.type ?? TransactionType.income; _selectedDate = tx?.date ?? DateTime.now();
    _selectedGoalId = tx?.linkedGoalId;
    _loadFormData();
  }
  @override
  void dispose() {
    _amountController.dispose(); _noteController.dispose();
    super.dispose();
  }
  Future<void> _loadFormData() async {
    setState(() => _loadingCategories = true);
    final data = await loadTransactionFormData(getIt<TransactionCategoryRepository>(),
        getIt<GoalRepository>(), preselectedCategoryId: widget.transaction?.categoryId);
    if (!mounted) return;
    setState(() {
      _allCategories = data.categories; _activeGoals = data.activeGoals;
      _loadingCategories = false;
      if (widget.transaction != null && _selectedCategory == null) {
        _selectedCategory = data.preselectedCategory;
      }
    });
  }
  Future<T?> _showSheet<T>(WidgetBuilder builder) => showModalBottomSheet<T>(
      context: context, isScrollControlled: true, useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: builder);
  Future<void> _pickCategory() async {
    final locale = Localizations.localeOf(context);
    final picked = await _showSheet<TransactionCategory>((_) => CategoryPickerSheet(
        categories: _filteredCategories, selectedCategoryId: _selectedCategory?.id, locale: locale));
    if (picked != null && mounted) setState(() => _selectedCategory = picked);
  }
  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate,
        firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }
  Future<void> _pickGoal() async {
    if (_activeGoals.isEmpty) return;
    final picked = await _showSheet<int?>((_) =>
        GoalLinkPickerSheet(activeGoals: _activeGoals, selectedGoalId: _selectedGoalId));
    if (mounted) setState(() => _selectedGoalId = picked);
  }
  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showError(AppLocalizations.of(context).errorCategoryRequired);
      return;
    }
    final amountCents = parseAmountCentsOrNull(_amountController.text);
    if (amountCents == null) {
      _showError(AppLocalizations.of(context).errorAmountRequired);
      return;
    }
    final tx = buildTransactionToSave(isEditing: _isEditing, original: widget.transaction,
        type: _selectedType, amountCents: amountCents, categoryId: _selectedCategory!.id,
        date: _selectedDate, now: DateTime.now(), linkedGoalId: _selectedGoalId,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null);
    await _persist(tx);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
  Future<void> _persist(Transaction tx) {
    final cubit = context.read<TransactionCubit>();
    return _isEditing ? cubit.updateTransaction(tx) : cubit.createTransaction(tx);
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context); final cs = theme.colorScheme;
    final categoryDisplay = resolveCategoryDisplay(_selectedCategory,
        preferEnglish: Localizations.localeOf(context).languageCode == 'en',
        fallback: l10n.fieldCategory);
    final goalDisplay = resolveGoalDisplay(_selectedGoalId, _activeGoals);
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editTransaction : l10n.addTransaction,
            style: theme.textTheme.titleLarge),
        centerTitle: false, elevation: 0, scrolledUnderElevation: 1,
        actions: [Padding(padding: const EdgeInsets.only(right: 8),
            child: FilledButton(onPressed: _save, child: Text(l10n.saveTransaction)))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [TransactionFormFields(
            amountController: _amountController, noteController: _noteController,
            selectedType: _selectedType, categoryDisplay: categoryDisplay,
            loadingCategories: _loadingCategories, selectedDate: _selectedDate,
            goalDisplay: goalDisplay, showGoalLink: _selectedType == TransactionType.expense,
            onTypeChanged: (type) => setState(() {
              _selectedType = type; _selectedCategory = null;
              if (type == TransactionType.income) _selectedGoalId = null;
            }),
            onPickCategory: _pickCategory, onPickDate: _pickDate,
            onPickGoal: _activeGoals.isNotEmpty ? _pickGoal : null,
          )],
        ),
      ),
    );
  }
}
