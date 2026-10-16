import 'dart:async';

import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/notifications/rules/tap_target.dart';
import 'package:agenda/domain/tasks/item_repository.dart';
import 'package:agenda/presentation/finance/goals/screens/goal_detail_screen.dart';
import 'package:agenda/presentation/shell/shell_navigation.dart';
import 'package:agenda/presentation/tasks/screens/task_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const int _tasksTab = 0;
const int _financeTab = 4;
const int _budgetsSubTab = 2;
const int _goalsSubTab = 3;
const int _debtsSubTab = 4;
const int _paymentsSubTab = 5;

/// Moves the app to the screen a notification [target] points at.
///
/// The target comes from an untrusted payload, so an entity id is only used
/// to load the entity: a missing or soft-deleted task or goal degrades to
/// the matching tab and nothing is pushed.
Future<void> openTapTarget(
  BuildContext context,
  TapTarget target, {
  required ItemRepository items,
  required GoalRepository goals,
}) async {
  final navigator = Navigator.of(context);
  switch (target) {
    case AppOnly():
      return;
    case OpenBriefing():
      _showTab(navigator, _tasksTab);
    case OpenBudgets():
      _showTab(navigator, _financeTab, subTab: _budgetsSubTab);
    case OpenDebts():
      _showTab(navigator, _financeTab, subTab: _debtsSubTab);
    case OpenPayments():
      _showTab(navigator, _financeTab, subTab: _paymentsSubTab);
    case OpenTask(:final taskId):
      final cubit = context.read<TaskListCubit>();
      final result = await items.getItem(taskId);
      if (!context.mounted) return;
      _showTab(navigator, _tasksTab);
      if (result case Success(:final value) when value.deletedAt == null) {
        unawaited(
          navigator.push(
            MaterialPageRoute<void>(
              builder:
                  (_) => BlocProvider.value(
                    value: cubit,
                    child: TaskDetailScreen(item: value),
                  ),
            ),
          ),
        );
      }
    case OpenGoal(:final goalId):
      final result = await goals.getGoal(goalId);
      if (!context.mounted) return;
      _showTab(navigator, _financeTab, subTab: _goalsSubTab);
      if (result case Success(:final value) when value.deletedAt == null) {
        unawaited(
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => GoalDetailScreen(goalId: goalId),
            ),
          ),
        );
      }
  }
}

void _showTab(NavigatorState navigator, int tab, {int? subTab}) {
  navigator.popUntil((route) => route.isFirst);
  appTabIndex.value = tab;
  financeSubTabRequest.value = subTab;
}
