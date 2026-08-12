import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/domain/finance/debt_repository.dart';
import 'package:agenda/domain/finance/goal_repository.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_models.dart';
import 'package:agenda/presentation/tasks/form/gtd/screens/gtd_guide_sheet.dart';
import 'package:agenda/presentation/tasks/form/task_form_fields_model.dart';
import 'package:agenda/presentation/tasks/form/task_form_logic.dart';
import 'package:agenda/presentation/tasks/form/widgets/task_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  late TaskFormFieldsModel _f;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _gtdContextController = TextEditingController(text: item?.gtdContext ?? '');
    _waitingForController = TextEditingController(text: item?.waitingFor ?? '');
    _f = TaskFormFieldsModel.fromItem(item);
    loadFinanceLinks(
      getIt<GoalRepository>(),
      getIt<DebtRepository>(),
      linkedGoalId: _f.linkedGoalId,
      linkedDebtId: _f.linkedDebtId,
    ).then((s) {
      if (mounted) setState(() => _f.applySnapshot(s));
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _gtdContextController.dispose();
    _waitingForController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final item = buildFormItem(
      isEditing: _isEditing,
      original: widget.item,
      fields: _f,
      title: _titleController.text.trim(),
      description:
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
      gtdContext:
          _gtdContextController.text.trim().isEmpty
              ? null
              : _gtdContextController.text.trim(),
      waitingFor:
          _waitingForController.text.trim().isEmpty
              ? null
              : _waitingForController.text.trim(),
      now: DateTime.now(),
    );
    final cubit = context.read<TaskListCubit>();
    final ok =
        _isEditing
            ? await cubit.updateItem(item)
            : await cubit.createItem(item);
    if (!mounted) return;
    _handleSaveResult(ok);
  }

  void _handleSaveResult(bool ok) {
    if (!ok) {
      // The cubit returned false → it emitted a TaskListError for THIS
      // save, so the current state carries the relevant failure message.
      final state = context.read<TaskListCubit>().state;
      final message =
          state is TaskListError
              ? state.failure.message
              : AppLocalizations.of(context).errorSaveFailed;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
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
    final v = applyGtdResult(
      result,
      currentDescription: _descriptionController.text,
    );
    setState(() {
      if (v.title.isNotEmpty) _titleController.text = v.title;
      if (v.description != null) _descriptionController.text = v.description!;
      if (v.waitingFor != null) _waitingForController.text = v.waitingFor!;
      if (v.gtdContext != null) _gtdContextController.text = v.gtdContext!;
      _f.applyGtd(v);
    });
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
          _isEditing ? l10n.taskFormTitleEdit : l10n.taskFormTitleCreate,
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(onPressed: _save, child: Text(l10n.saveButton)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: TaskFormFields(
          l10n: l10n,
          theme: theme,
          cs: cs,
          model: _f,
          onModelChanged: (mutate) => setState(() => mutate(_f)),
          titleController: _titleController,
          descriptionController: _descriptionController,
          waitingForController: _waitingForController,
          isEditing: _isEditing,
          onOpenGtdGuide: _openGtdGuide,
        ),
      ),
    );
  }
}
