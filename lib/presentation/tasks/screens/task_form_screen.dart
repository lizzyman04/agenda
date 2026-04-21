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

// ===== GTD GUIDE — Natural-language decision tree =====
// Deviations from spec:
// - "Outro motivo" always continues to next step (no free-text collection)
// - Recurrence: Habit tasks get low priority but no RRULE (picker deferred)
// - Duplicate detection deferred (needs repository access from modal context)
// - Cancel "save draft" simplified to discard (no draft persistence layer)

typedef _GtdOpt = (IconData, String, void Function());

class _GtdResult {
  const _GtdResult({
    required this.title,
    required this.priority,
    required this.isUrgent,
    required this.isImportant,
    this.dueDate,
    this.waitingFor,
    this.gtdContext,
    this.description,
  });

  final String title;
  final Priority priority;
  final bool isUrgent;
  final bool isImportant;
  final DateTime? dueDate;
  final String? waitingFor;
  final String? gtdContext;
  final String? description;
}

enum _GtdNode {
  q1Title,
  q2Actionable,
  q2bWhyAdd,
  q3Delegate,
  q3bDelegateName,
  q3cFollowUp,
  q4Quick,
  q4bWhyNotNow,
  q5Important,
  q5bWhyKeep,
  q6Deadline,
  q6bNoDeadlineReason,
  q7Impact,
  q7bWhyKeepNoImpact,
  review,
}

class _GtdGuideSheet extends StatefulWidget {
  const _GtdGuideSheet({required this.l10n});
  final AppLocalizations l10n;

  @override
  State<_GtdGuideSheet> createState() => _GtdGuideSheetState();
}

class _GtdGuideSheetState extends State<_GtdGuideSheet> {
  final List<_GtdNode> _history = [_GtdNode.q1Title];

  final _titleCtrl = TextEditingController();
  final _delegateCtrl = TextEditingController();

  DateTime? _dueDate;
  Priority _priority = Priority.medium;
  bool _isUrgent = false;
  bool _isImportant = false;
  String? _waitingFor;
  String? _gtdContext;
  String? _description;

  static const _mainPath = [
    _GtdNode.q1Title,
    _GtdNode.q2Actionable,
    _GtdNode.q3Delegate,
    _GtdNode.q4Quick,
    _GtdNode.q5Important,
    _GtdNode.q6Deadline,
    _GtdNode.q7Impact,
    _GtdNode.review,
  ];

  AppLocalizations get _l => widget.l10n;
  _GtdNode get _current => _history.last;

  void _push(_GtdNode node) => setState(() => _history.add(node));
  void _pop() {
    if (_history.length > 1) setState(() => _history.removeLast());
  }

  int get _mainStepIndex {
    final idx = _history.lastIndexWhere(_mainPath.contains);
    return idx >= 0 ? idx : 0;
  }

  Future<void> _confirmCancel() async {
    if (_titleCtrl.text.trim().isEmpty && _history.length <= 1) {
      Navigator.of(context).pop(null);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l.gtdCancelTitle),
        content: Text(_l.gtdCancelMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_l.gtdCancelContinue),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_l.gtdCancelDiscard),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) Navigator.of(context).pop(null);
  }

  void _endWithSnackbar(String msg) {
    Navigator.of(context).pop(null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _finish() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(_GtdResult(
      title: title,
      priority: _priority,
      isUrgent: _isUrgent,
      isImportant: _isImportant,
      dueDate: _dueDate,
      waitingFor: _waitingFor,
      gtdContext: _gtdContext,
      description: _description,
    ));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _delegateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _confirmCancel(),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollCtrl) => Column(
            children: [
              // Handle bar
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
              // Header: back/close + progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _history.length > 1 ? Icons.arrow_back : Icons.close,
                      ),
                      onPressed: _history.length > 1 ? _pop : _confirmCancel,
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Pergunta ${_mainStepIndex + 1} de ${_mainPath.length}',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (_mainStepIndex + 1) / _mainPath.length,
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
                      onPressed: _confirmCancel,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              // Animated content area
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: anim,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_current),
                    child: SingleChildScrollView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      child: _buildNode(theme, cs),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNode(ThemeData t, ColorScheme cs) => switch (_current) {
    _GtdNode.q1Title => _textNode(
      t, cs,
      question: _l.gtdQ1,
      icon: Icons.edit_note,
      controller: _titleCtrl,
      hint: 'ex: Enviar proposta para o cliente',
      maxLength: 100,
      onNext: () {
        final text = _titleCtrl.text.trim();
        if (text.isEmpty) return;
        _gtdContext ??= _inferContext(text);
        _push(_GtdNode.q2Actionable);
      },
    ),

    _GtdNode.q2Actionable => _optionNode(
      t, cs,
      question: _l.gtdQ2,
      icon: Icons.help_outline,
      subtitle: 'Considere se isso trará valor real para você.',
      options: [
        (Icons.check_circle_outline, _l.gtdAnswerYes, () => _push(_GtdNode.q3Delegate)),
        (Icons.cancel, _l.gtdAnswerNo, () => _push(_GtdNode.q2bWhyAdd)),
      ],
    ),

    _GtdNode.q2bWhyAdd => _optionNode(
      t, cs,
      question: _l.gtdQ2bQuestion,
      icon: Icons.psychology,
      options: [
        (Icons.schedule, _l.gtdQ2bSomedayMaybe, () {
          _priority = Priority.low;
          _gtdContext = 'someday';
          _endWithSnackbar(_l.gtdSomedayMessage);
        }),
        (Icons.lightbulb_outline, _l.gtdQ2bIdea, () {
          _description = _titleCtrl.text.trim();
          _priority = Priority.low;
          _endWithSnackbar(_l.gtdIdeaSavedMessage);
        }),
        (Icons.person_add, _l.gtdQ2bDelegated, () => _push(_GtdNode.q3Delegate)),
        (Icons.add_task, _l.gtdQ2bKeepAnyway, () => _push(_GtdNode.q3Delegate)),
      ],
    ),

    _GtdNode.q3Delegate => _optionNode(
      t, cs,
      question: _l.gtdQ3,
      icon: Icons.group,
      options: [
        (Icons.person, _l.gtdAnswerNo, () => _push(_GtdNode.q4Quick)),
        (Icons.send, _l.gtdAnswerYes, () => _push(_GtdNode.q3bDelegateName)),
      ],
    ),

    _GtdNode.q3bDelegateName => _textNode(
      t, cs,
      question: _l.gtdQ3DelegateTo,
      icon: Icons.person_search,
      controller: _delegateCtrl,
      hint: _l.gtdQ3DelegateHint,
      onNext: () {
        final name = _delegateCtrl.text.trim();
        if (name.isEmpty) return;
        _waitingFor = name;
        _push(_GtdNode.q3cFollowUp);
      },
    ),

    _GtdNode.q3cFollowUp => _optionNode(
      t, cs,
      question: _l.gtdQ3FollowUp,
      icon: Icons.notification_add,
      options: [
        (Icons.alarm_add, _l.gtdAnswerYes, () {
          _dueDate = DateTime.now().add(const Duration(days: 7));
          _push(_GtdNode.review);
        }),
        (Icons.check, _l.gtdAnswerNo, () => _push(_GtdNode.review)),
      ],
    ),

    _GtdNode.q4Quick => _optionNode(
      t, cs,
      question: _l.gtdQ4,
      icon: Icons.timer,
      subtitle: 'A regra dos 10 minutos: se sim, você deveria fazer agora.',
      options: [
        (Icons.east, _l.gtdAnswerNo, () => _push(_GtdNode.q5Important)),
        (Icons.bolt, _l.gtdAnswerYes, () => _push(_GtdNode.q4bWhyNotNow)),
      ],
    ),

    _GtdNode.q4bWhyNotNow => _optionNode(
      t, cs,
      question: _l.gtdQ4bQuestion,
      icon: Icons.hourglass_empty,
      options: [
        (Icons.work, _l.gtdQ4bBusy, () {
          _dueDate = _today();
          _push(_GtdNode.q5Important);
        }),
        (Icons.info_outline, _l.gtdQ4bNeedContext, () => _push(_GtdNode.q5Important)),
        (Icons.schedule, _l.gtdQ4bNotRightTime, () => _push(_GtdNode.q5Important)),
        (Icons.done_all, _l.gtdQ4bDoItNow, () => _endWithSnackbar(_l.gtdDoItNowMessage)),
        (Icons.more_horiz, _l.gtdQ4bOther, () => _push(_GtdNode.q5Important)),
      ],
    ),

    _GtdNode.q5Important => _optionNode(
      t, cs,
      question: _l.gtdQ5,
      icon: Icons.star_outline,
      options: [
        (Icons.check_circle_outline, _l.gtdAnswerYes, () {
          _isImportant = true;
          _push(_GtdNode.q6Deadline);
        }),
        (Icons.remove_circle_outline, _l.gtdAnswerNo, () {
          _isImportant = false;
          _push(_GtdNode.q5bWhyKeep);
        }),
      ],
    ),

    _GtdNode.q5bWhyKeep => _optionNode(
      t, cs,
      question: _l.gtdQ5bQuestion,
      icon: Icons.help,
      options: [
        (Icons.assignment, _l.gtdQ5bObligation, () {
          if (_priority == Priority.medium) _priority = Priority.low;
          _push(_GtdNode.q6Deadline);
        }),
        (Icons.person_pin, _l.gtdQ5bSomeoneAsking, () {
          _isUrgent = true;
          _priority = Priority.high;
          _push(_GtdNode.q6Deadline);
        }),
        (Icons.notifications_none, _l.gtdQ5bReminder, () {
          if (_priority == Priority.medium) _priority = Priority.low;
          _push(_GtdNode.q6Deadline);
        }),
        (Icons.cancel, _l.gtdQ5bCancelTask, () => Navigator.of(context).pop(null)),
        (Icons.more_horiz, _l.gtdQ5bOther, () => _push(_GtdNode.q6Deadline)),
      ],
    ),

    _GtdNode.q6Deadline => _deadlineNode(t, cs),

    _GtdNode.q6bNoDeadlineReason => _optionNode(
      t, cs,
      question: _l.gtdQ6bQuestion,
      icon: Icons.event_busy,
      options: [
        (Icons.repeat, _l.gtdQ6bHabit, () => _push(_GtdNode.q7Impact)),
        (Icons.alarm_off, _l.gtdQ6bNotUrgent, () {
          if (_priority == Priority.medium) _priority = Priority.low;
          _push(_GtdNode.q7Impact);
        }),
        (Icons.hourglass_empty, _l.gtdQ6bWhenever, () {
          if (_priority == Priority.medium) _priority = Priority.low;
          _push(_GtdNode.q7Impact);
        }),
        (Icons.more_horiz, _l.gtdQ6bOther, () => _push(_GtdNode.q7Impact)),
      ],
    ),

    _GtdNode.q7Impact => _impactNode(t, cs),

    _GtdNode.q7bWhyKeepNoImpact => _optionNode(
      t, cs,
      question: _l.gtdQ7bQuestion,
      icon: Icons.help_outline,
      options: [
        (Icons.favorite_border, _l.gtdQ7bPersonalWish, () {
          _priority = Priority.low;
          _gtdContext ??= 'wishlist';
          _push(_GtdNode.review);
        }),
        (Icons.people_outline, _l.gtdQ7bSomeoneExpects, () {
          _waitingFor ??= 'alguém';
          _push(_GtdNode.review);
        }),
        (Icons.cancel, _l.gtdQ7bCancelTask, () => Navigator.of(context).pop(null)),
        (Icons.more_horiz, _l.gtdQ7bOther, () {
          _priority = Priority.low;
          _push(_GtdNode.review);
        }),
      ],
    ),

    _GtdNode.review => _reviewNode(t, cs),
  };

  // ---- Specialised node builders ----

  Widget _deadlineNode(ThemeData t, ColorScheme cs) {
    final now = DateTime.now();
    final opts = <_GtdOpt>[
      (Icons.today, _l.gtdDeadlineToday, () {
        _dueDate = _today();
        _isUrgent = true;
        _push(_GtdNode.q7Impact);
      }),
      (Icons.event, _l.gtdDeadlineTomorrow, () {
        _dueDate = now.add(const Duration(days: 1));
        _isUrgent = true;
        _push(_GtdNode.q7Impact);
      }),
      (Icons.date_range, _l.gtdDeadlineThisWeek, () {
        _dueDate = now.add(const Duration(days: 7));
        _push(_GtdNode.q7Impact);
      }),
      (Icons.calendar_month, _l.gtdDeadlineNext20Days, () {
        _dueDate = now.add(const Duration(days: 20));
        _push(_GtdNode.q7Impact);
      }),
      (Icons.calendar_view_month, _l.gtdDeadlineThisMonth, () {
        _dueDate = DateTime(now.year, now.month + 1, now.day);
        _push(_GtdNode.q7Impact);
      }),
      (Icons.block, _l.gtdDeadlineNoDeadline, () {
        _dueDate = null;
        _push(_GtdNode.q6bNoDeadlineReason);
      }),
      (Icons.edit_calendar, _l.gtdDeadlineCustom, () { _pickCustomDate(); }),
    ];
    return _optionNode(t, cs,
      question: _l.gtdQ6,
      icon: Icons.calendar_today,
      options: opts,
    );
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _dueDate = picked;
        _isUrgent = picked.isBefore(
          DateTime.now().add(const Duration(days: 2)),
        );
      });
      _push(_GtdNode.q7Impact);
    }
  }

  Widget _impactNode(ThemeData t, ColorScheme cs) {
    final opts = <_GtdOpt>[
      (Icons.warning_amber, _l.gtdImpactVeryNegative, () {
        _priority = Priority.urgent;
        _isImportant = true;
        _isUrgent = _dueDate != null;
        _push(_GtdNode.review);
      }),
      (Icons.trending_down, _l.gtdImpactNegative, () {
        _priority = Priority.high;
        _isImportant = true;
        _push(_GtdNode.review);
      }),
      (Icons.remove, _l.gtdImpactModerate, () => _push(_GtdNode.review)),
      (Icons.expand_less, _l.gtdImpactLight, () {
        _priority = Priority.low;
        _push(_GtdNode.review);
      }),
      (Icons.minimize, _l.gtdImpactVeryLight, () {
        _priority = Priority.low;
        _push(_GtdNode.review);
      }),
      (Icons.not_interested, _l.gtdImpactNone,
          () => _push(_GtdNode.q7bWhyKeepNoImpact)),
    ];
    return _optionNode(t, cs,
      question: _l.gtdQ7,
      icon: Icons.show_chart,
      options: opts,
    );
  }

  Widget _reviewNode(ThemeData t, ColorScheme cs) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _iconBox(cs, Icons.checklist, cs.tertiaryContainer, cs.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(child: Text(_l.gtdReviewTitle, style: t.textTheme.titleLarge)),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _reviewRow(t, cs, Icons.title, 'Título', _titleCtrl.text.trim()),
                _divider(cs),
                _reviewRow(t, cs, Icons.calendar_today, _l.gtdReviewDeadlineLabel,
                    _dueDate != null ? fmt.format(_dueDate!) : _l.gtdDeadlineNoDeadline),
                _divider(cs),
                _reviewRow(t, cs, Icons.priority_high, _l.gtdReviewPriorityLabel,
                    _priorityLabel()),
                _divider(cs),
                _reviewRow(t, cs, Icons.star, _l.gtdReviewImportantLabel,
                    _isImportant ? _l.gtdAnswerYes : _l.gtdAnswerNo),
                _divider(cs),
                _reviewRow(t, cs, Icons.bolt, _l.gtdReviewUrgentLabel,
                    _isUrgent ? _l.gtdAnswerYes : _l.gtdAnswerNo),
                if (_waitingFor != null) ...[
                  _divider(cs),
                  _reviewRow(t, cs, Icons.person, _l.gtdReviewDelegatedLabel,
                      _waitingFor!),
                ],
                if (_gtdContext != null) ...[
                  _divider(cs),
                  _reviewRow(t, cs, Icons.tag, 'Contexto', _gtdContext!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _pop,
                child: Text(_l.gtdReviewEdit),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _finish,
                child: Text(_l.gtdReviewSave),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Reusable layout helpers ----

  Widget _optionNode(
    ThemeData t,
    ColorScheme cs, {
    required String question,
    required IconData icon,
    required List<_GtdOpt> options,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _iconBox(cs, icon, cs.primaryContainer, cs.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(child: Text(question, style: t.textTheme.titleLarge)),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              subtitle,
              style: t.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: options.asMap().entries.map((e) {
              final (optIcon, label, callback) = e.value;
              final isFirst = e.key == 0;
              final isLast = e.key == options.length - 1;
              return ListTile(
                leading: Icon(optIcon, color: cs.primary, size: 22),
                title: Text(label, style: t.textTheme.bodyLarge),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: callback,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: isFirst ? const Radius.circular(16) : Radius.zero,
                    bottom: isLast ? const Radius.circular(16) : Radius.zero,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _textNode(
    ThemeData t,
    ColorScheme cs, {
    required String question,
    required IconData icon,
    required TextEditingController controller,
    required VoidCallback onNext,
    String? hint,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _iconBox(cs, icon, cs.primaryContainer, cs.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(child: Text(question, style: t.textTheme.titleLarge)),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: cs.surfaceContainerLow,
          ),
          onSubmitted: (_) => onNext(),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onNext, child: const Text('Próximo →')),
      ],
    );
  }

  Widget _iconBox(ColorScheme cs, IconData icon, Color bg, Color fg) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: fg, size: 24),
      );

  Widget _reviewRow(
    ThemeData t,
    ColorScheme cs,
    IconData icon,
    String label,
    String value,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(label,
                style:
                    t.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                style: t.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _divider(ColorScheme cs) =>
      Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4));

  String _priorityLabel() => switch (_priority) {
    Priority.urgent => 'Urgente',
    Priority.critical => 'Crítica',
    Priority.high => 'Alta',
    Priority.medium => 'Média',
    Priority.low => 'Baixa',
  };

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String? _inferContext(String text) {
    final t = text.toLowerCase();
    if (t.contains('@casa') || t.contains('em casa')) return '@casa';
    if (t.contains('@trabalho') || t.contains('@escritório') ||
        t.contains('no trabalho')) return '@trabalho';
    if (t.contains('@computador') || t.contains('@pc')) return '@computador';
    if (t.contains('@telefone') || t.contains('ligar para')) return '@telefone';
    if (t.contains('@compras') || t.contains('comprar')) return '@compras';
    return null;
  }
}
