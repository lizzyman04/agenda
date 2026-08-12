import 'package:agenda/application/finance/transaction/transaction_cubit.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/utils/amount_parser.dart';
import 'package:agenda/domain/finance/goal_repository.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/domain/finance/transaction_category_repository.dart';
import 'package:agenda/domain/finance/transaction_type.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/transaction_form_logic.dart';
import 'package:agenda/presentation/finance/transaction_form_model.dart';
import 'package:agenda/presentation/finance/widgets/transaction/transaction_form_fields.dart';
import 'package:agenda/presentation/finance/widgets/transaction/transaction_form_pickers.dart';
import 'package:agenda/presentation/finance/widgets/transaction/transaction_form_scaffold.dart';
import 'package:agenda/presentation/finance/widgets/transaction/transaction_form_submit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Form screen for creating/editing a transaction.
///
/// Owns the text controllers and the mutable [TransactionFormModel]; load,
/// save and picker logic live in the sibling `transaction_form_*` files.
class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, this.transaction});

  final Transaction? transaction;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late TransactionFormModel _model;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _amountController = TextEditingController(
      text: formatCentsForInput(tx?.amountCents ?? 0),
    );
    _noteController = TextEditingController(text: tx?.note ?? '');
    _model = TransactionFormModel.from(tx);
    _loadFormData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() => _model.loadingCategories = true);
    final data = await loadTransactionFormData(
      getIt<TransactionCategoryRepository>(),
      getIt<GoalRepository>(),
      preselectedCategoryId: widget.transaction?.categoryId,
    );
    if (!mounted) return;
    setState(() {
      _model.allCategories = data.categories;
      _model.activeGoals = data.activeGoals;
      _model.loadingCategories = false;
      if (_isEditing && _model.category == null) {
        _model.category = data.preselectedCategory;
      }
    });
  }

  Future<void> _pickCategory() async {
    final picked = await pickTransactionCategory(
      context: context,
      categories: _model.filteredCategories,
      selectedCategoryId: _model.category?.id,
    );
    if (picked != null && mounted) setState(() => _model.category = picked);
  }

  Future<void> _pickDate() async {
    final picked = await pickTransactionDate(context, _model.date);
    if (picked != null && mounted) setState(() => _model.date = picked);
  }

  Future<void> _pickGoal() async {
    if (_model.activeGoals.isEmpty) return;
    final picked = await pickTransactionGoal(
      context: context,
      activeGoals: _model.activeGoals,
      selectedGoalId: _model.goalId,
    );
    if (mounted) setState(() => _model.goalId = picked);
  }

  Future<void> _save() async {
    final saved = await submitTransactionForm(
      context: context,
      formKey: _formKey,
      cubit: context.read<TransactionCubit>(),
      isEditing: _isEditing,
      original: widget.transaction,
      type: _model.type,
      category: _model.category,
      date: _model.date,
      linkedGoalId: _model.goalId,
      amountText: _amountController.text,
      noteText: _noteController.text,
    );
    if (saved && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TransactionFormScaffold(
      formKey: _formKey,
      isEditing: _isEditing,
      onSave: _save,
      fields: TransactionFormFields(
        amountController: _amountController,
        noteController: _noteController,
        selectedType: _model.type,
        categoryDisplay: resolveCategoryDisplay(
          _model.category,
          preferEnglish: Localizations.localeOf(context).languageCode == 'en',
          fallback: l10n.fieldCategory,
        ),
        loadingCategories: _model.loadingCategories,
        selectedDate: _model.date,
        goalDisplay: resolveGoalDisplay(_model.goalId, _model.activeGoals),
        showGoalLink: _model.showGoalLink,
        onTypeChanged:
            (type) => setState(() {
              _model.type = type;
              _model.category = null;
              if (type == TransactionType.income) _model.goalId = null;
            }),
        onPickCategory: _pickCategory,
        onPickDate: _pickDate,
        onPickGoal: _model.activeGoals.isNotEmpty ? _pickGoal : null,
      ),
    );
  }
}
