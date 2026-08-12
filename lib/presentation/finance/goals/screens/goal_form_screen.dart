import 'package:agenda/application/finance/goal/goal_cubit.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/utils/amount_parser.dart';
import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/goal_form_logic.dart';
import 'package:agenda/presentation/finance/widgets/finance_form_primitives.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Form screen for creating or editing a savings goal.
///
/// Fields: title, target amount, optional deadline.
class GoalFormScreen extends StatefulWidget {
  const GoalFormScreen({super.key, this.goal});

  /// If non-null, the form is in edit mode pre-filled with [goal].
  final SavingsGoal? goal;

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _targetController;

  DateTime? _deadline;

  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    final targetStr = goal != null
        ? (goal.targetAmountCents / 100)
            .toStringAsFixed(2)
            .replaceAll('.', ',')
        : '';
    _targetController = TextEditingController(text: targetStr);
    _deadline = goal?.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final targetCents = parseAmountCentsOrNull(_targetController.text);
    if (targetCents == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorAmountRequired),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final now = DateTime.now();

    final goal = buildGoalToSave(
      isEditing: _isEditing,
      original: widget.goal,
      title: _titleController.text.trim(),
      targetAmountCents: targetCents,
      deadline: _deadline,
      now: now,
    );

    if (_isEditing) {
      final goalCubit = getIt<GoalCubit>();
      await goalCubit.updateGoal(goal);
    } else {
      // Use GoalListCubit from context if available, else create via GoalCubit
      try {
        final goalCubit = getIt<GoalCubit>();
        await goalCubit.createGoal(goal);
      } catch (_) {
        // fallback: already covered by BlocProvider in parent
      }
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
          _isEditing ? l10n.goalsTabLabel : l10n.addGoal,
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
              child: Text(l10n.saveGoal),
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
            FormCard(
              child: Column(
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.title_outlined,
                            size: 20, color: cs.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
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
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 48, endIndent: 16),

                  // Target amount
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.attach_money_outlined,
                            size: 20, color: cs.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _targetController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
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
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 48, endIndent: 16),

                  // Optional deadline
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 20, color: cs.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              l10n.fieldDueDate,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            subtitle: Text(
                              _deadline != null
                                  ? dateFormat.format(_deadline!)
                                  : l10n.noDueDate,
                              style: theme.textTheme.bodyMedium,
                            ),
                            trailing: _deadline != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () =>
                                        setState(() => _deadline = null),
                                  )
                                : const Icon(Icons.edit_calendar_outlined),
                            onTap: _pickDeadline,
                          ),
                        ),
                      ],
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
