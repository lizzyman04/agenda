import 'dart:async';

import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/form/screens/task_form_screen.dart';
import 'package:agenda/presentation/tasks/widgets/detail/task_detail_action_bar.dart';
import 'package:agenda/presentation/tasks/widgets/detail/task_detail_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({required this.item, super.key});

  final Item item;

  Future<void> _confirmDelete(
      BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text(l10n.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      unawaited(context.read<TaskListCubit>().softDelete(item.id));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppConstants.undoSnackbarDuration,
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.taskDeleted),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () =>
                unawaited(context.read<TaskListCubit>().restoreItem(item.id)),
          ),
        ),
      );
    }
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<TaskListCubit>(),
          child: TaskFormScreen(item: item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l10n.taskDetailTitle),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: TaskDetailBody(item: item),
      bottomNavigationBar: SafeArea(
        child: TaskDetailActionBar(
          onDelete: () => _confirmDelete(context, l10n),
          onEdit: () => _navigateToEdit(context),
        ),
      ),
    );
  }
}
