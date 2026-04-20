import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/domain/tasks/item_type.dart';
import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/domain/tasks/size_category.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
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
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _GtdGuideSheet(l10n: l10n),
    );
    if (result == null || !mounted) return;
    setState(() {
      // Use next action as title (more specific), original title as context
      if (result.nextAction.isNotEmpty) {
        _titleController.text = result.nextAction;
        if (_descriptionController.text.isEmpty && result.title.isNotEmpty) {
          _descriptionController.text = result.title;
        }
      } else if (result.title.isNotEmpty) {
        _titleController.text = result.title;
      }
      _priority = result.priority;
      _isUrgent = result.isUrgent;
      _isImportant = result.isImportant;
      _isNextAction = result.nextAction.isNotEmpty;
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
            _FormCard(
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
            _FormCard(
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
              _GtdGuideCard(
                onTap: _openGtdGuide,
                colorScheme: cs,
                theme: theme,
                label: l10n.gtdGuide,
              ),
              const SizedBox(height: 12),
            ],

            // Advanced options
            _AdvancedOptionsCard(
              expanded: _advancedExpanded,
              onToggle: () =>
                  setState(() => _advancedExpanded = !_advancedExpanded),
              label: l10n.advancedOptions,
              theme: theme,
              cs: cs,
              children: [
                // Priority
                _FieldRow(
                  icon: Icons.flag_outlined,
                  child: DropdownButtonFormField<Priority>(
                    value: _priority,
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
                const _FieldDivider(),

                // Due Date
                _FieldRow(
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
                  const _FieldDivider(),
                  _FieldRow(
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
                  const _FieldDivider(),
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

                const _FieldDivider(),

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

                const _FieldDivider(),

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

                const _FieldDivider(),

                // Description
                _FieldRow(
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
                const _FieldDivider(),

                // Waiting For
                _FieldRow(
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

// ---------------------------------------------------------------------------
// Small layout helpers
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        crossAxisAlignment: CrossAxisAlignment.center,
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

class _GtdGuideCard extends StatelessWidget {
  const _GtdGuideCard({
    required this.onTap,
    required this.colorScheme,
    required this.theme,
    required this.label,
  });

  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.psychology,
                    color: colorScheme.onPrimary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '8 questions to clarify & prioritize',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: colorScheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvancedOptionsCard extends StatelessWidget {
  const _AdvancedOptionsCard({
    required this.expanded,
    required this.onToggle,
    required this.label,
    required this.theme,
    required this.cs,
    required this.children,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final String label;
  final ThemeData theme;
  final ColorScheme cs;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.tune_outlined, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: expanded
                ? Column(children: children)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GTD Guide
// ---------------------------------------------------------------------------

class _GtdResult {
  const _GtdResult({
    required this.title,
    required this.nextAction,
    required this.priority,
    required this.isUrgent,
    required this.isImportant,
    this.dueDate,
    this.waitingFor,
    this.gtdContext,
  });

  final String title;
  final String nextAction;
  final Priority priority;
  final bool isUrgent;
  final bool isImportant;
  final DateTime? dueDate;
  final String? waitingFor;
  final String? gtdContext;
}

class _GtdGuideSheet extends StatefulWidget {
  const _GtdGuideSheet({required this.l10n});
  final AppLocalizations l10n;

  @override
  State<_GtdGuideSheet> createState() => _GtdGuideSheetState();
}

class _GtdGuideSheetState extends State<_GtdGuideSheet> {
  int _step = 0;
  static const int _totalSteps = 8;

  final _titleCtrl = TextEditingController();
  final _nextActionCtrl = TextEditingController();
  final _contextCtrl = TextEditingController();

  DateTime? _dueDate;
  Priority _priority = Priority.medium;
  bool _isUrgent = false;
  bool _isImportant = false;
  String? _waitingFor;

  AppLocalizations get l10n => widget.l10n;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _nextActionCtrl.dispose();
    _contextCtrl.dispose();
    super.dispose();
  }

  void _endWithMessage(String message) {
    Navigator.of(context).pop(null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _finish() {
    Navigator.of(context).pop(
      _GtdResult(
        title: _titleCtrl.text.trim(),
        nextAction: _nextActionCtrl.text.trim(),
        priority: _priority,
        isUrgent: _isUrgent,
        isImportant: _isImportant,
        dueDate: _dueDate,
        waitingFor: _waitingFor,
        gtdContext:
            _contextCtrl.text.trim().isNotEmpty ? _contextCtrl.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _step--),
                      visualDensity: VisualDensity.compact,
                    )
                  else
                    const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Step ${_step + 1} of $_totalSteps',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_step + 1) / _totalSteps,
                            minHeight: 6,
                            backgroundColor: cs.surfaceContainerHighest,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(null),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: _buildStep(theme, cs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme, ColorScheme cs) {
    return switch (_step) {
      // Q1: What needs to be done?
      0 => _TextStep(
          question: l10n.gtdQ1,
          controller: _titleCtrl,
          hint: null,
          theme: theme,
          cs: cs,
          onNext: () {
            if (_titleCtrl.text.trim().isNotEmpty) {
              setState(() => _step = 1);
            }
          },
        ),

      // Q2: Is it actionable?
      1 => _YesNoStep(
          question: l10n.gtdQ2,
          subtitle: 'If not, it goes to Someday/Maybe or Trash.',
          theme: theme,
          cs: cs,
          onYes: () => setState(() => _step = 2),
          onNo: () => _endWithMessage(l10n.gtdDiscardMessage),
        ),

      // Q3: What's the very next physical action?
      2 => _TextStep(
          question: l10n.gtdQ3,
          controller: _nextActionCtrl,
          hint: l10n.gtdQ3Hint,
          theme: theme,
          cs: cs,
          onNext: () => setState(() => _step = 3),
          canSkip: true,
          onSkip: () => setState(() => _step = 3),
          skipLabel: l10n.gtdSkip,
        ),

      // Q4: Can it be done in under 2 minutes?
      3 => _YesNoStep(
          question: l10n.gtdQ4,
          subtitle: 'The 2-minute rule: if yes, do it immediately.',
          theme: theme,
          cs: cs,
          onYes: () => _endWithMessage(l10n.gtdDoItNowMessage),
          onNo: () => setState(() => _step = 4),
        ),

      // Q5: Should this be delegated?
      4 => _YesNoStep(
          question: l10n.gtdQ5,
          subtitle: 'If yes, who should own this?',
          theme: theme,
          cs: cs,
          onYes: () {
            _waitingFor = 'delegated';
            _endWithMessage(l10n.gtdDelegateMessage);
          },
          onNo: () => setState(() => _step = 5),
        ),

      // Q6: Deadline
      5 => _DeadlineStep(
          question: l10n.gtdQ6,
          theme: theme,
          cs: cs,
          options: [
            (l10n.gtdDeadlineToday, 0),
            (l10n.gtdDeadlineTomorrow, 1),
            (l10n.gtdDeadlineThisWeek, 2),
            (l10n.gtdDeadlineThisMonth, 3),
          ],
          noDeadlineLabel: l10n.gtdDeadlineNoDeadline,
          customLabel: l10n.gtdDeadlineCustom,
          onSelected: (date) {
            _dueDate = date;
            setState(() => _step = 6);
          },
        ),

      // Q7: Importance / priority
      6 => _ImportanceStep(
          question: l10n.gtdQ7,
          theme: theme,
          cs: cs,
          options: [
            (l10n.gtdImpactCritical, Priority.urgent, true, true),
            (l10n.gtdImpactHigh, Priority.high, false, true),
            (l10n.gtdImpactMedium, Priority.medium, false, false),
            (l10n.gtdImpactLow, Priority.low, false, false),
          ],
          onSelected: (priority, isUrgent, isImportant) {
            _priority = priority;
            _isUrgent = isUrgent;
            _isImportant = isImportant;
            setState(() => _step = 7);
          },
        ),

      // Q8: Context
      _ => _TextStep(
          question: l10n.gtdQ8,
          controller: _contextCtrl,
          hint: l10n.gtdQ8Hint,
          theme: theme,
          cs: cs,
          onNext: _finish,
          nextLabel: 'Done',
          canSkip: true,
          onSkip: _finish,
          skipLabel: l10n.gtdSkip,
        ),
    };
  }
}

// ---------------------------------------------------------------------------
// GTD Step widgets
// ---------------------------------------------------------------------------

class _TextStep extends StatelessWidget {
  const _TextStep({
    required this.question,
    required this.controller,
    required this.hint,
    required this.theme,
    required this.cs,
    required this.onNext,
    this.nextLabel,
    this.canSkip = false,
    this.onSkip,
    this.skipLabel,
  });

  final String question;
  final TextEditingController controller;
  final String? hint;
  final ThemeData theme;
  final ColorScheme cs;
  final VoidCallback onNext;
  final String? nextLabel;
  final bool canSkip;
  final VoidCallback? onSkip;
  final String? skipLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(question, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: cs.surfaceContainerLow,
          ),
          onSubmitted: (_) => onNext(),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onNext,
          child: Text(nextLabel ?? '→'),
        ),
        if (canSkip && onSkip != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: onSkip,
            child: Text(skipLabel ?? 'Skip'),
          ),
        ],
      ],
    );
  }
}

class _YesNoStep extends StatelessWidget {
  const _YesNoStep({
    required this.question,
    required this.theme,
    required this.cs,
    required this.onYes,
    required this.onNo,
    this.subtitle,
  });

  final String question;
  final String? subtitle;
  final ThemeData theme;
  final ColorScheme cs;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(question, style: theme.textTheme.headlineSmall),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onNo,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('No'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onYes,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Yes'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeadlineStep extends StatelessWidget {
  const _DeadlineStep({
    required this.question,
    required this.theme,
    required this.cs,
    required this.options,
    required this.noDeadlineLabel,
    required this.customLabel,
    required this.onSelected,
  });

  final String question;
  final ThemeData theme;
  final ColorScheme cs;
  final List<(String, int)> options;
  final String noDeadlineLabel;
  final String customLabel;
  final void Function(DateTime?) onSelected;

  DateTime _deadlineDate(int option) {
    final now = DateTime.now();
    return switch (option) {
      0 => now,
      1 => now.add(const Duration(days: 1)),
      2 => now.add(const Duration(days: 7)),
      3 => DateTime(now.year, now.month + 1, now.day),
      _ => now,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(question, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ...options.map(
                (opt) => ListTile(
                  title: Text(opt.$1),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onSelected(_deadlineDate(opt.$2)),
                ),
              ),
              ListTile(
                title: Text(noDeadlineLabel),
                trailing: const Icon(Icons.block_outlined),
                onTap: () => onSelected(null),
              ),
              ListTile(
                title: Text(customLabel),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null && context.mounted) {
                    onSelected(picked);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImportanceStep extends StatelessWidget {
  const _ImportanceStep({
    required this.question,
    required this.theme,
    required this.cs,
    required this.options,
    required this.onSelected,
  });

  final String question;
  final ThemeData theme;
  final ColorScheme cs;
  final List<(String, Priority, bool, bool)> options;
  final void Function(Priority, bool isUrgent, bool isImportant) onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(question, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: options.map((opt) {
              final (label, priority, isUrgent, isImportant) = opt;
              return ListTile(
                title: Text(label),
                leading: _priorityDot(priority, cs),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onSelected(priority, isUrgent, isImportant),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _priorityDot(Priority p, ColorScheme cs) {
    final color = switch (p) {
      Priority.urgent || Priority.critical => cs.error,
      Priority.high => Colors.orange,
      Priority.medium => cs.primary,
      Priority.low => cs.outline,
    };
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
