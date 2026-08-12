import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows the failure snackbar after a task save returns `false`.
///
/// Extracted from `TaskFormScreen._handleSaveResult` so the screen widget can
/// stay under the architecture line-count limit.
///
/// The cubit returning `false` means it emitted a [TaskListError] for *this*
/// save, so the current state carries the relevant failure message; the
/// localised fallback only applies if the state moved on in between.
void showTaskSaveFailure(BuildContext context) {
  final state = context.read<TaskListCubit>().state;
  final message =
      state is TaskListError
          ? state.failure.message
          : AppLocalizations.of(context).errorSaveFailed;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
