import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/debt.dart' hide clearField;
import 'package:agenda/domain/finance/debt_repository.dart';
import 'package:agenda/domain/finance/goal_repository.dart';
import 'package:agenda/domain/finance/savings_goal.dart' hide clearField;
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/domain/tasks/size_category.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_models.dart';
import 'package:agenda/presentation/tasks/form/gtd/screens/gtd_guide_sheet.dart';
import 'package:agenda/presentation/tasks/form/widgets/advanced_options_card.dart';
import 'package:agenda/presentation/tasks/form/widgets/form_primitives.dart';
import 'package:agenda/presentation/tasks/form/widgets/gtd_guide_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.item});

  final Item? item;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _gtdContextController;
  late final TextEditingController _waitingForController;

  late ItemType _itemType;
  late Priority _priority;
  late SizeCategory _sizeCategory;
  late bool _isUrgent;
  late bool _isImportant;
  late bool _isNextAction;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  String? _recurrenceRule;
  bool _advancedExpanded = false;

  // Finance link state
  int? _linkedGoalId;
  int? _linkedDebtId;
  List<SavingsGoal> _activeGoals = [];
  List<Debt> _activeDebts = [];
  String? _linkedGoalTitle;
  String? _linkedDebtTitle;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descriptionController =
        TextEditingController(text: item?.description ?? '');
    _gtdContextController =
        TextEditingController(text: item?.gtdContext ?? '');
    _waitingForController =
        TextEditingController(text: item?.waitingFor ?? '');

    _itemType = item?.type ?? ItemType.task;
    _priority = item?.priority ?? Priority.medium;
    _sizeCategory = item?.sizeCategory ?? SizeCategory.medium;
    _isUrgent = item?.isUrgent ?? false;
    _isImportant = item?.isImportant ?? false;
    _isNextAction = item?.isNextAction ?? false;
    _dueDate = item?.dueDate;
    if (item?.dueTimeMinutes != null) {
      final minutes = item!.dueTimeMinutes!;
      _dueTime = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    }
    _recurrenceRule = item?.recurrenceRule;
    _linkedGoalId = item?.linkedGoalId;
    _linkedDebtId = item?.linkedDebtId;
    _loadFinanceLinks();
  }

  Future<void> _loadFinanceLinks() async {
    final goalRepo = getIt<GoalRepository>();
    final debtRepo = getIt<DebtRepository>();

    final goalsResult = await goalRepo.getActiveGoals();
    if (goalsResult is Success<List<SavingsGoal>> && mounted) {
      final goals = goalsResult.value;
      setState(() {
        _activeGoals = goals;
        if (_linkedGoalId != null) {
          try {
            _linkedGoalTitle = goals
                .firstWhere((g) => g.id == _linkedGoalId)
                .title;
          } catch (_) {}
        }
      });
    }

    final debtsResult = await debtRepo.getDebts();
    if (debtsResult is Success<List<Debt>> && mounted) {
      final debts = debtsResult.value;
      setState(() {
        _activeDebts = debts;
        if (_linkedDebtId != null) {
          try {
            _linkedDebtTitle = debts
                .firstWhere((d) => d.id == _linkedDebtId)
                .title;
          } catch (_) {}
        }
      });
    }
  }

  Future<void> _pickFinanceLink() async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                l10n.linkToFinance,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: [
                  // Clear option
                  ListTile(
                    leading: const Icon(Icons.link_off),
                    title: const Text('Sem vínculo'),
                    onTap: () {
                      setState(() {
                        _linkedGoalId = null;
                        _linkedDebtId = null;
                        _linkedGoalTitle = null;
                        _linkedDebtTitle = null;
                      });
                      Navigator.of(ctx).pop();
                    },
                  ),
                  if (_activeGoals.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        l10n.goalsTabLabel,
                        style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    ..._activeGoals.map(
                      (g) => ListTile(
                        leading: const Icon(Icons.savings_outlined),
                        title: Text(g.title),
                        trailing: _linkedGoalId == g.id
                            ? Icon(Icons.check,
                                color: Theme.of(ctx).colorScheme.primary)
                            : null,
                        onTap: () {
                          setState(() {
                            _linkedGoalId = g.id;
                            _linkedGoalTitle = g.title;
                            _linkedDebtId = null;
                            _linkedDebtTitle = null;
                          });
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ),
                  ],
                  if (_activeDebts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        l10n.debtsTabLabel,
                        style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    ..._activeDebts.map(
                      (d) => ListTile(
                        leading: const Icon(Icons.handshake_outlined),
                        title: Text(d.title),
                        subtitle: Text(d.counterparty),
                        trailing: _linkedDebtId == d.id
                            ? Icon(Icons.check,
                                color: Theme.of(ctx).colorScheme.primary)
                            : null,
                        onTap: () {
                          setState(() {
                            _linkedDebtId = d.id;
                            _linkedDebtTitle = d.title;
                            _linkedGoalId = null;
                            _linkedGoalTitle = null;
                          });
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _gtdContextController.dispose();
    _waitingForController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        if (_recurrenceRule != null &&
            _recurrenceRule!.startsWith('FREQ=MONTHLY')) {
          _recurrenceRule = null;
        }
      });
    }
  }

  Future<void> _pickTime() async {
    if (_dueDate == null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final dueTimeMinutes =
        _dueTime != null ? _dueTime!.hour * 60 + _dueTime!.minute : null;

    final Item saved;
    if (_isEditing) {
      saved = widget.item!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        type: widget.item!.type == ItemType.subtask
            ? widget.item!.type
            : _itemType,
        // Invariant: only subtasks may carry a parentId. A non-subtask item
        // must have parentId == null, otherwise updateItem's guard rejects the
        // save. Clearing it here lets the form recover any legacy item whose
        // type is not subtask but still holds a stale parentId.
        parentId:
            widget.item!.type == ItemType.subtask ? widget.item!.parentId : null,
        priority: _priority,
        sizeCategory: _sizeCategory,
        isUrgent: _isUrgent,
        isImportant: _isImportant,
        isNextAction: _isNextAction,
        gtdContext: _gtdContextController.text.trim().isNotEmpty
            ? _gtdContextController.text.trim()
            : null,
        waitingFor: _waitingForController.text.trim().isNotEmpty
            ? _waitingForController.text.trim()
            : null,
        dueDate: _dueDate,
        dueTimeMinutes: dueTimeMinutes,
        recurrenceRule: _recurrenceRule,
        linkedGoalId: _linkedGoalId ?? clearField,
        linkedDebtId: _linkedDebtId ?? clearField,
        updatedAt: now,
      );
      final ok = await context.read<TaskListCubit>().updateItem(saved);
      if (!mounted) return;
      if (!ok) {
        // updateItem returned false → it emitted a TaskListError for THIS
        // save, so the current state carries the relevant failure message.
        final state = context.read<TaskListCubit>().state;
        final message = state is TaskListError
            ? state.failure.message
            : AppLocalizations.of(context).errorSaveFailed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }
    } else {
      saved = Item(
        id: 0,
        type: _itemType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        priority: _priority,
        sizeCategory: _sizeCategory,
        isUrgent: _isUrgent,
        isImportant: _isImportant,
        isNextAction: _isNextAction,
        gtdContext: _gtdContextController.text.trim().isNotEmpty
            ? _gtdContextController.text.trim()
            : null,
        waitingFor: _waitingForController.text.trim().isNotEmpty
            ? _waitingForController.text.trim()
            : null,
        dueDate: _dueDate,
        dueTimeMinutes: dueTimeMinutes,
        recurrenceRule: _recurrenceRule,
        linkedGoalId: _linkedGoalId,
        linkedDebtId: _linkedDebtId,
        createdAt: now,
        updatedAt: now,
      );
      final ok = await context.read<TaskListCubit>().createItem(saved);
      if (!mounted) return;
      if (!ok) {
        // createItem returned false → it emitted a TaskListError for THIS
        // save, so the current state carries the relevant failure message.
        final state = context.read<TaskListCubit>().state;
        final message = state is TaskListError
            ? state.failure.message
            : AppLocalizations.of(context).errorSaveFailed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }
    }

    Navigator.of(context).pop();
  }

  Future<void> _openGtdGuide() async {
    final l10n = AppLocalizations.of(context);
    final result = await showModalBottomSheet<GtdResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => GtdGuideSheet(l10n: l10n),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (result.title.isNotEmpty) _titleController.text = result.title;
      if (result.description != null && _descriptionController.text.isEmpty) {
        _descriptionController.text = result.description!;
      }
      _priority = result.priority;
      _isUrgent = result.isUrgent;
      _isImportant = result.isImportant;
      _isNextAction = true;
      _dueDate = result.dueDate;
      if (result.waitingFor != null) {
        _waitingForController.text = result.waitingFor!;
      }
      if (result.gtdContext != null) {
        _gtdContextController.text = result.gtdContext!;
      }
    });
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
          _isEditing ? l10n.taskFormTitleEdit : l10n.taskFormTitleCreate,
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
              child: Text(l10n.saveButton),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Title field
            FormCard(
              child: TextFormField(
                controller: _titleController,
                autofocus: !_isEditing,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: l10n.fieldTitle,
                  hintText: l10n.gtdQ1,
                  prefixIcon: const Icon(Icons.title_outlined),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.fieldTitleRequired;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),

            // Type toggle
            FormCard(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SegmentedButton<ItemType>(
                  segments: [
                    ButtonSegment(
                      value: ItemType.task,
                      label: Text(l10n.typeTask),
                      icon: const Icon(Icons.task_alt_outlined),
                    ),
                    ButtonSegment(
                      value: ItemType.project,
                      label: Text(l10n.typeProject),
                      icon: const Icon(Icons.folder_outlined),
                    ),
                  ],
                  selected: {_itemType},
                  onSelectionChanged: (s) =>
                      setState(() => _itemType = s.first),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // GTD Guide card (create mode only)
            if (!_isEditing) ...[
              GtdGuideCard(
                onTap: _openGtdGuide,
                colorScheme: cs,
                theme: theme,
                label: l10n.gtdGuide,
              ),
              const SizedBox(height: 12),
            ],

            // Advanced options
            AdvancedOptionsCard(
              expanded: _advancedExpanded,
              onToggle: () =>
                  setState(() => _advancedExpanded = !_advancedExpanded),
              label: l10n.advancedOptions,
              theme: theme,
              cs: cs,
              children: [
                // Priority
                FieldRow(
                  icon: Icons.flag_outlined,
                  child: DropdownButtonFormField<Priority>(
                    initialValue: _priority,
                    decoration: InputDecoration(
                      labelText: l10n.fieldPriority,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    items: Priority.values
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(_priorityLabel(l10n, p)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _priority = val);
                    },
                  ),
                ),
                const FieldDivider(),

                // Due Date
                FieldRow(
                  icon: Icons.calendar_today_outlined,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(l10n.fieldDueDate,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    subtitle: Text(
                      _dueDate != null
                          ? dateFormat.format(_dueDate!)
                          : l10n.noDueDate,
                      style: theme.textTheme.bodyMedium,
                    ),
                    trailing: _dueDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() {
                              _dueDate = null;
                              _dueTime = null;
                              _recurrenceRule = null;
                            }),
                          )
                        : IconButton(
                            icon: const Icon(Icons.edit_calendar_outlined),
                            onPressed: _pickDate,
                          ),
                    onTap: _pickDate,
                  ),
                ),

                // Due Time (only when date set)
                if (_dueDate != null) ...[
                  const FieldDivider(),
                  FieldRow(
                    icon: Icons.access_time_outlined,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(l10n.fieldDueTime,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                      subtitle: Text(
                        _dueTime != null
                            ? '${_dueTime!.hour.toString().padLeft(2, '0')}:'
                                '${_dueTime!.minute.toString().padLeft(2, '0')}'
                            : l10n.noDueTime,
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.schedule_outlined),
                        onPressed: _pickTime,
                      ),
                      onTap: _pickTime,
                    ),
                  ),
                ],

                // Recurrence
                if (_dueDate != null) ...[
                  const FieldDivider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      l10n.recurrence,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                  ...[null, 'FREQ=DAILY', 'FREQ=WEEKLY',
                    'FREQ=MONTHLY;BYMONTHDAY=${_dueDate!.day}',
                    'FREQ=YEARLY']
                      .map((rule) => RadioListTile<String?>(
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            title: Text(_recurrenceLabel(l10n, rule)),
                            value: rule,
                            groupValue: _recurrenceRule,
                            onChanged: (v) =>
                                setState(() => _recurrenceRule = v),
                          )),
                ],

                const FieldDivider(),

                // Urgent / Important
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  secondary: Icon(Icons.bolt_outlined, color: cs.error),
                  title: Text(l10n.fieldUrgent),
                  dense: true,
                  value: _isUrgent,
                  onChanged: (val) => setState(() => _isUrgent = val),
                ),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  secondary: Icon(Icons.star_outline, color: cs.primary),
                  title: Text(l10n.fieldImportant),
                  dense: true,
                  value: _isImportant,
                  onChanged: (val) => setState(() => _isImportant = val),
                ),

                const FieldDivider(),

                // Size
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    l10n.fieldSize,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SegmentedButton<SizeCategory>(
                    segments: [
                      ButtonSegment(
                          value: SizeCategory.big, label: Text(l10n.sizeBig)),
                      ButtonSegment(
                          value: SizeCategory.medium,
                          label: Text(l10n.sizeMedium)),
                      ButtonSegment(
                          value: SizeCategory.small,
                          label: Text(l10n.sizeSmall)),
                      ButtonSegment(
                          value: SizeCategory.none,
                          label: Text(l10n.sizeNone)),
                    ],
                    selected: {_sizeCategory},
                    onSelectionChanged: (s) =>
                        setState(() => _sizeCategory = s.first),
                  ),
                ),
                const SizedBox(height: 12),

                const FieldDivider(),

                // Description
                FieldRow(
                  icon: Icons.notes_outlined,
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: l10n.fieldDescription,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const FieldDivider(),

                // Waiting For
                FieldRow(
                  icon: Icons.hourglass_empty_outlined,
                  child: TextFormField(
                    controller: _waitingForController,
                    decoration: InputDecoration(
                      labelText: l10n.fieldWaitingFor,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            const SizedBox(height: 12),

            // Finance link card
            FormCard(
              child: ListTile(
                leading: const Icon(Icons.link_outlined),
                title: Text(
                  l10n.linkToFinance,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                subtitle: (_linkedGoalTitle ?? _linkedDebtTitle) != null
                    ? Text(
                        '${l10n.linkedTo} ${_linkedGoalTitle ?? _linkedDebtTitle}',
                        style: theme.textTheme.bodyMedium,
                      )
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickFinanceLink,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _priorityLabel(AppLocalizations l10n, Priority priority) {
    return switch (priority) {
      Priority.low => l10n.priorityLow,
      Priority.medium => l10n.priorityMedium,
      Priority.high => l10n.priorityHigh,
      Priority.critical => l10n.priorityCritical,
      Priority.urgent => l10n.priorityUrgent,
    };
  }

  String _recurrenceLabel(AppLocalizations l10n, String? rule) {
    if (rule == null) return l10n.noRecurrence;
    if (rule.contains('DAILY')) return l10n.daily;
    if (rule.contains('WEEKLY')) return l10n.weekly;
    if (rule.contains('MONTHLY')) return l10n.monthly;
    if (rule.contains('YEARLY')) return l10n.yearly;
    return rule;
  }
}
