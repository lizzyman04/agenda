import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/domain/tasks/size_category.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Task form — Quick Add by default, with Advanced options expandable section
/// and an optional GTD Guide conversational flow.
///
/// Pass [item] = null for create mode; non-null for edit mode.
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.item});

  final Item? item;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
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

    _itemType =
        item?.type == ItemType.project ? ItemType.project : ItemType.task;
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
        type: _itemType,
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
        updatedAt: now,
      );
      await context.read<TaskListCubit>().updateItem(saved);
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
        createdAt: now,
        updatedAt: now,
      );
      await context.read<TaskListCubit>().createItem(saved);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _openGtdGuide() async {
    final l10n = AppLocalizations.of(context);
    final result = await showModalBottomSheet<_GtdResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GtdGuideSheet(l10n: l10n),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (result.title.isNotEmpty) _titleController.text = result.title;
      _priority = result.priority;
      _isUrgent = result.isUrgent;
      _isImportant = result.isImportant;
      _dueDate = result.dueDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.taskFormTitleEdit : l10n.taskFormTitleCreate,
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(l10n.saveButton),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title — required
            TextFormField(
              controller: _titleController,
              autofocus: !_isEditing,
              decoration: InputDecoration(
                labelText: l10n.fieldTitle,
                hintText: l10n.gtdQ1,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.fieldTitleRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Type toggle
            SegmentedButton<ItemType>(
              segments: [
                ButtonSegment(
                  value: ItemType.task,
                  label: Text(l10n.typeTask),
                  icon: const Icon(Icons.task_alt),
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
            const SizedBox(height: 12),

            // GTD Guide button (create mode only)
            if (!_isEditing)
              OutlinedButton.icon(
                onPressed: _openGtdGuide,
                icon: const Icon(Icons.psychology_outlined),
                label: Text(l10n.gtdGuide),
              ),

            const SizedBox(height: 4),

            // Advanced options (expandable)
            ExpansionTile(
              title: Text(l10n.advancedOptions),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                // Priority
                DropdownButtonFormField<Priority>(
                  value: _priority,
                  decoration: InputDecoration(
                    labelText: l10n.fieldPriority,
                    border: const OutlineInputBorder(),
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
                const SizedBox(height: 12),

                // Due Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.fieldDueDate),
                  subtitle: Text(
                    _dueDate != null
                        ? dateFormat.format(_dueDate!)
                        : l10n.noDueDate,
                  ),
                  trailing: TextButton(
                    onPressed: _pickDate,
                    child: const Icon(Icons.calendar_today),
                  ),
                ),

                // Due Time
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.fieldDueTime),
                  subtitle: Text(
                    _dueTime != null
                        ? '${_dueTime!.hour.toString().padLeft(2, '0')}:'
                            '${_dueTime!.minute.toString().padLeft(2, '0')}'
                        : l10n.noDueTime,
                  ),
                  trailing: TextButton(
                    onPressed: _dueDate != null ? _pickTime : null,
                    child: const Icon(Icons.access_time),
                  ),
                ),

                // Recurrence (only when dueDate set)
                if (_dueDate != null) ...[
                  Text(
                    l10n.recurrence,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  RadioListTile<String?>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.noRecurrence),
                    value: null,
                    groupValue: _recurrenceRule,
                    onChanged: (v) => setState(() => _recurrenceRule = v),
                  ),
                  RadioListTile<String?>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.daily),
                    value: 'FREQ=DAILY',
                    groupValue: _recurrenceRule,
                    onChanged: (v) => setState(() => _recurrenceRule = v),
                  ),
                  RadioListTile<String?>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.weekly),
                    value: 'FREQ=WEEKLY',
                    groupValue: _recurrenceRule,
                    onChanged: (v) => setState(() => _recurrenceRule = v),
                  ),
                  RadioListTile<String?>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.monthly),
                    value: 'FREQ=MONTHLY;BYMONTHDAY=${_dueDate!.day}',
                    groupValue: _recurrenceRule,
                    onChanged: (v) => setState(() => _recurrenceRule = v),
                  ),
                  RadioListTile<String?>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.yearly),
                    value: 'FREQ=YEARLY',
                    groupValue: _recurrenceRule,
                    onChanged: (v) => setState(() => _recurrenceRule = v),
                  ),
                ],

                // Urgent / Important
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.fieldUrgent),
                  value: _isUrgent,
                  onChanged: (val) => setState(() => _isUrgent = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.fieldImportant),
                  value: _isImportant,
                  onChanged: (val) => setState(() => _isImportant = val),
                ),

                // Size
                Text(
                  l10n.fieldSize,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SegmentedButton<SizeCategory>(
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
                        value: SizeCategory.none, label: Text(l10n.sizeNone)),
                  ],
                  selected: {_sizeCategory},
                  onSelectionChanged: (s) =>
                      setState(() => _sizeCategory = s.first),
                ),
                const SizedBox(height: 12),

                // Next Action
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.fieldNextAction),
                  value: _isNextAction,
                  onChanged: (val) =>
                      setState(() => _isNextAction = val ?? false),
                ),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.fieldDescription,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                // GTD Context
                TextFormField(
                  controller: _gtdContextController,
                  decoration: InputDecoration(
                    labelText: l10n.fieldGtdContext,
                    hintText: '@casa',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Waiting For
                TextFormField(
                  controller: _waitingForController,
                  decoration: InputDecoration(
                    labelText: l10n.fieldWaitingFor,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
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
}

// ---------------------------------------------------------------------------
// GTD Guide
// ---------------------------------------------------------------------------

class _GtdResult {
  const _GtdResult({
    required this.title,
    required this.priority,
    required this.isUrgent,
    required this.isImportant,
    this.dueDate,
  });

  final String title;
  final Priority priority;
  final bool isUrgent;
  final bool isImportant;
  final DateTime? dueDate;
}

class _GtdGuideSheet extends StatefulWidget {
  const _GtdGuideSheet({required this.l10n});
  final AppLocalizations l10n;

  @override
  State<_GtdGuideSheet> createState() => _GtdGuideSheetState();
}

class _GtdGuideSheetState extends State<_GtdGuideSheet> {
  int _step = 0;
  final _titleCtrl = TextEditingController();
  bool _isImportant = false;
  DateTime? _dueDate;

  AppLocalizations get l10n => widget.l10n;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _endWithMessage(String message) {
    Navigator.of(context).pop(null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  void _finish(int impactLevel) {
    final priority = switch (impactLevel) {
      0 => Priority.urgent,
      1 => Priority.critical,
      2 => Priority.high,
      3 => Priority.medium,
      _ => Priority.low,
    };
    Navigator.of(context).pop(
      _GtdResult(
        title: _titleCtrl.text.trim(),
        priority: priority,
        isUrgent: impactLevel <= 1,
        isImportant: _isImportant,
        dueDate: _dueDate,
      ),
    );
  }

  DateTime _deadlineDate(int option) {
    final now = DateTime.now();
    return switch (option) {
      0 => now,
      1 => now.add(const Duration(days: 7)),
      2 => DateTime(now.year, now.month + 1, now.day),
      _ => now,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStep(),
        ],
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _questionStep(
          question: l10n.gtdQ1,
          child: Column(
            children: [
              TextField(
                controller: _titleCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onSubmitted: (_) => setState(() => _step = 1),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (_titleCtrl.text.trim().isNotEmpty) {
                    setState(() => _step = 1);
                  }
                },
                child: const Text('→'),
              ),
            ],
          ),
        ),
      1 => _yesNoStep(
          question: l10n.gtdQ2,
          onYes: () => setState(() => _step = 2),
          onNo: () => _endWithMessage(l10n.gtdDiscardMessage),
        ),
      2 => _yesNoStep(
          question: l10n.gtdQ3,
          onYes: () => _endWithMessage(l10n.gtdDelegateMessage),
          onNo: () => setState(() => _step = 3),
        ),
      3 => _yesNoStep(
          question: l10n.gtdQ4,
          onYes: () => _endWithMessage(l10n.gtdDoItNowMessage),
          onNo: () => setState(() => _step = 4),
        ),
      4 => _yesNoStep(
          question: l10n.gtdQ5,
          onYes: () => setState(() {
            _isImportant = true;
            _step = 5;
          }),
          onNo: () => setState(() {
            _isImportant = false;
            _step = 5;
          }),
        ),
      5 => _questionStep(
          question: l10n.gtdQ6,
          child: Column(
            children: [
              ...List.generate(3, (i) {
                final labels = [
                  l10n.gtdDeadlineToday,
                  l10n.gtdDeadlineThisWeek,
                  l10n.gtdDeadlineThisMonth,
                ];
                return ListTile(
                  title: Text(labels[i]),
                  onTap: () => setState(() {
                    _dueDate = _deadlineDate(i);
                    _step = 6;
                  }),
                );
              }),
              ListTile(
                title: Text(l10n.gtdDeadlineCustom),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null && mounted) {
                    setState(() {
                      _dueDate = picked;
                      _step = 6;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      _ => _questionStep(
          question: l10n.gtdQ7,
          child: Column(
            children: [
              l10n.gtdImpactCritical,
              l10n.gtdImpactHigh,
              l10n.gtdImpactMedium,
              l10n.gtdImpactLow,
              l10n.gtdImpactNone,
            ]
                .asMap()
                .entries
                .map(
                  (e) => ListTile(
                    title: Text(e.value),
                    onTap: () => _finish(e.key),
                  ),
                )
                .toList(),
          ),
        ),
    };
  }

  Widget _questionStep({required String question, required Widget child}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(question, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _yesNoStep({
    required String question,
    required VoidCallback onYes,
    required VoidCallback onNo,
  }) {
    return _questionStep(
      question: question,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onNo,
              child: Text(l10n.gtdAnswerNo),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onYes,
              child: Text(l10n.gtdAnswerYes),
            ),
          ),
        ],
      ),
    );
  }
}
