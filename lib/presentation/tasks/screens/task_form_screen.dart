import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/domain/tasks/size_category.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Task form screen — used for both create and edit flows.
///
/// Pass [item] = null for create mode; non-null for edit mode.
/// Calls [TaskListCubit.createItem] or [TaskListCubit.updateItem] on save.
/// Title is required — validated before submission (T-02-07).
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.item});

  /// Null = create mode; non-null = edit mode.
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
  late final TextEditingController _amountController;
  late final TextEditingController _currencyController;

  late ItemType _itemType;
  late Priority _priority;
  late SizeCategory _sizeCategory;
  late bool _isUrgent;
  late bool _isImportant;
  late bool _isNextAction;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;

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
    _amountController = TextEditingController(
      text: item?.amount != null ? item!.amount.toString() : '',
    );
    _currencyController =
        TextEditingController(text: item?.currencyCode ?? '');

    _itemType = item?.type == ItemType.project ? ItemType.project : ItemType.task;
    _priority = item?.priority ?? Priority.medium;
    _sizeCategory = item?.sizeCategory ?? SizeCategory.none;
    _isUrgent = item?.isUrgent ?? false;
    _isImportant = item?.isImportant ?? false;
    _isNextAction = item?.isNextAction ?? false;

    _dueDate = item?.dueDate;
    if (item?.dueTimeMinutes != null) {
      final minutes = item!.dueTimeMinutes!;
      _dueTime = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _gtdContextController.dispose();
    _waitingForController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
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
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickTime() async {
    if (_dueDate == null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final dueTimeMinutes = _dueTime != null
        ? _dueTime!.hour * 60 + _dueTime!.minute
        : null;
    final amount = _amountController.text.isNotEmpty
        ? double.tryParse(_amountController.text)
        : null;

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
        amount: amount,
        currencyCode: _currencyController.text.trim().isNotEmpty
            ? _currencyController.text.trim()
            : null,
        updatedAt: now,
      );
      context.read<TaskListCubit>().updateItem(saved);
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
        amount: amount,
        currencyCode: _currencyController.text.trim().isNotEmpty
            ? _currencyController.text.trim()
            : null,
        createdAt: now,
        updatedAt: now,
      );
      context.read<TaskListCubit>().createItem(saved);
    }

    Navigator.of(context).pop();
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
            // 1. Title (required)
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.fieldTitle,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.fieldTitleRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 2. Description (optional)
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.fieldDescription,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // 3. Type — SegmentedButton (project | task)
            Text(
              l10n.typeTask,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
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
              onSelectionChanged: (selection) {
                setState(() => _itemType = selection.first);
              },
            ),
            const SizedBox(height: 16),

            // 4. Priority
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
            const SizedBox(height: 16),

            // 5. Due Date
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

            // 6. Due Time (only enabled if dueDate is set)
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

            // 7. Urgent
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.fieldUrgent),
              value: _isUrgent,
              onChanged: (val) => setState(() => _isUrgent = val),
            ),

            // 8. Important
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.fieldImportant),
              value: _isImportant,
              onChanged: (val) => setState(() => _isImportant = val),
            ),

            // 9. Size — SegmentedButton
            const SizedBox(height: 8),
            Text(
              l10n.fieldSize,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SegmentedButton<SizeCategory>(
              segments: [
                ButtonSegment(
                  value: SizeCategory.big,
                  label: Text(l10n.sizeBig),
                ),
                ButtonSegment(
                  value: SizeCategory.medium,
                  label: Text(l10n.sizeMedium),
                ),
                ButtonSegment(
                  value: SizeCategory.small,
                  label: Text(l10n.sizeSmall),
                ),
                ButtonSegment(
                  value: SizeCategory.none,
                  label: Text(l10n.sizeNone),
                ),
              ],
              selected: {_sizeCategory},
              onSelectionChanged: (selection) {
                setState(() => _sizeCategory = selection.first);
              },
            ),
            const SizedBox(height: 8),

            // 10. Next Action
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.fieldNextAction),
              value: _isNextAction,
              onChanged: (val) =>
                  setState(() => _isNextAction = val ?? false),
            ),

            // 11. GTD Context
            TextFormField(
              controller: _gtdContextController,
              decoration: InputDecoration(
                labelText: l10n.fieldGtdContext,
                hintText: '@home',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 12. Waiting For
            TextFormField(
              controller: _waitingForController,
              decoration: InputDecoration(
                labelText: l10n.fieldWaitingFor,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 13. Amount
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: l10n.fieldAmount,
                border: const OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            // 14. Currency
            TextFormField(
              controller: _currencyController,
              decoration: InputDecoration(
                labelText: l10n.fieldCurrency,
                hintText: 'MZN',
                border: const OutlineInputBorder(),
              ),
              maxLength: 3,
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
