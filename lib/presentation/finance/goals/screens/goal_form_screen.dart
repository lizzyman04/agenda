import 'package:agenda/application/finance/goal/goal_cubit.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/utils/amount_parser.dart';
import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/goal_form_logic.dart';
import 'package:agenda/presentation/finance/goals/widgets/goal_form_fields.dart';
import 'package:flutter/material.dart';

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
        ? (goal.targetAmountCents / 100).toStringAsFixed(2).replaceAll('.', ',')
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            GoalFormFields(
              titleController: _titleController,
              targetController: _targetController,
              isEditing: _isEditing,
              deadline: _deadline,
              onPickDeadline: _pickDeadline,
              onClearDeadline: () => setState(() => _deadline = null),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
