import 'package:agenda/application/finance/transaction/transaction_cubit.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/goal_repository.dart';
import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/domain/finance/transaction_category.dart';
import 'package:agenda/domain/finance/transaction_category_repository.dart';
import 'package:agenda/domain/finance/transaction_type.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
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
    final amountStr = tx != null
        ? (tx.amountCents / 100).toStringAsFixed(2).replaceAll('.', ',')
        : '';
    _amountController = TextEditingController(text: amountStr);
    _noteController = TextEditingController(text: tx?.note ?? '');

    _selectedType = tx?.type ?? TransactionType.income;
    _selectedDate = tx?.date ?? DateTime.now();
    _selectedGoalId = tx?.linkedGoalId;

    _loadCategories();
    _loadGoals();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    final repo = getIt<TransactionCategoryRepository>();
    final result = await repo.getAll();
    if (result is Success<List<TransactionCategory>> && mounted) {
      final cats = result.value;
      setState(() {
        _allCategories = cats;
        _loadingCategories = false;
        // Pre-select category for edit mode
        if (widget.transaction != null && _selectedCategory == null) {
          try {
            _selectedCategory = cats.firstWhere(
              (c) => c.id == widget.transaction!.categoryId,
            );
          } catch (_) {
            _selectedCategory = null;
          }
        }
      });
    } else {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadGoals() async {
    final repo = getIt<GoalRepository>();
    final result = await repo.getActiveGoals();
    if (result is Success<List<SavingsGoal>> && mounted) {
      setState(() => _activeGoals = result.value);
    }
  }

  List<TransactionCategory> get _filteredCategories => _allCategories
      .where((c) => c.type == _selectedType)
      .toList();

  Future<void> _pickCategory() async {
    final cats = _filteredCategories;
    final locale = Localizations.localeOf(context);
    final picked = await showModalBottomSheet<TransactionCategory>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: cats.length,
                itemBuilder: (_, i) {
                  final cat = cats[i];
                  final name = locale.languageCode == 'en' && cat.nameEn != null
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
          ],
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
    final picked = await showModalBottomSheet<SavingsGoal?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.7,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // None option to clear link
            ListTile(
              leading: const Icon(Icons.link_off),
              title: const Text('Sem vínculo'),
              trailing: _selectedGoalId == null
                  ? Icon(Icons.check,
                      color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(ctx).pop(),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: _activeGoals.length,
                itemBuilder: (_, i) {
                  final goal = _activeGoals[i];
                  return ListTile(
                    leading: const Icon(Icons.savings_outlined),
                    title: Text(goal.title),
                    trailing: _selectedGoalId == goal.id
                        ? Icon(Icons.check,
                            color: Theme.of(ctx).colorScheme.primary)
                        : null,
                    onTap: () => Navigator.of(ctx).pop(goal),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (mounted) {
      setState(() {
        // `picked` is null when user presses "Sem vínculo", or a goal when selected
        // showModalBottomSheet returns null when dismissed by back button too
        if (picked == null) {
          _selectedGoalId = null;
        } else {
          _selectedGoalId = picked.id;
        }
      });
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

    final rawAmount = _amountController.text
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^\d.]'), '');
    final parsedAmount = double.tryParse(rawAmount);
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorAmountRequired),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final amountCents = (parsedAmount * 100).round();
    final now = DateTime.now();
    final cubit = context.read<TransactionCubit>();

    if (_isEditing) {
      final updated = widget.transaction!.copyWith(
        type: _selectedType,
        amountCents: amountCents,
        categoryId: _selectedCategory!.id,
        date: _selectedDate,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        linkedGoalId: _selectedGoalId,
        updatedAt: now,
      );
      await cubit.updateTransaction(updated);
    } else {
      final tx = Transaction(
        id: 0,
        type: _selectedType,
        amountCents: amountCents,
        categoryId: _selectedCategory!.id,
        date: _selectedDate,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        linkedGoalId: _selectedGoalId,
        createdAt: now,
        updatedAt: now,
      );
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
            _FormCard(
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
            _FormCard(
              child: Column(
                children: [
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
                  const _FieldDivider(),

                  // Date
                  _FieldRow(
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
                  const _FieldDivider(),

                  // Note
                  _FieldRow(
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
              _FormCard(
                child: _FieldRow(
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

// ---------------------------------------------------------------------------
// Layout helpers (reuse Phase 2 pattern)
// ---------------------------------------------------------------------------

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
