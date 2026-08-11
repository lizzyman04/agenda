import 'package:agenda/application/finance/goal/goal_cubit.dart';
import 'package:agenda/application/finance/goal/goal_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/domain/finance/savings_goal_contribution.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/goals/screens/goal_form_screen.dart';
import 'package:agenda/presentation/finance/goals/widgets/add_contribution_sheet.dart';
import 'package:agenda/presentation/finance/goals/widgets/delete_goal_dialog.dart';
import 'package:agenda/presentation/finance/goals/widgets/goal_detail_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Detail screen for a single savings goal.
///
/// Owns the [GoalCubit] for one goal and wires the AppBar actions. All body
/// rendering lives in [GoalDetailBody]; the sheet and dialog are separate
/// presentation-only widgets under `../widgets/`.
class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({required this.goalId, super.key});

  final int goalId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GoalCubit>()..loadGoal(goalId),
      child: _GoalDetailView(goalId: goalId),
    );
  }
}

class _GoalDetailView extends StatelessWidget {
  const _GoalDetailView({required this.goalId});

  final int goalId;

  /// Opens the contribution sheet and applies the result after it closes.
  ///
  /// The sheet owns its own controllers and returns the contribution via
  /// `Navigator.pop`; the mutation runs only once the sheet has fully closed,
  /// so no emit interleaves with teardown and no controller is touched after
  /// disposal.
  Future<void> _addContribution(BuildContext context) async {
    final cubit = context.read<GoalCubit>();

    final contribution = await showModalBottomSheet<SavingsGoalContribution>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddContributionSheet(),
    );

    if (contribution != null) {
      await cubit.addContribution(goalId, contribution);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<GoalCubit>();
    final navigator = Navigator.of(context);

    if (await showDeleteGoalDialog(context)) {
      await cubit.softDeleteGoal(goalId);
      navigator.pop();
    }
  }

  void _openEditForm(BuildContext context) {
    final state = context.read<GoalCubit>().state;
    if (state is! GoalLoaded) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GoalFormScreen(goal: state.goal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.goalsTabLabel),
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.editButton,
            onPressed: () => _openEditForm(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.deleteGoal,
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: BlocBuilder<GoalCubit, GoalState>(
        builder: (context, state) => switch (state) {
          GoalInitial() || GoalLoading() =>
            const Center(child: CircularProgressIndicator()),
          GoalError(:final failure) => Center(child: Text(failure.message)),
          GoalLoaded(:final goal, :final taggedTransactionsCents) =>
            GoalDetailBody(
              goal: goal,
              taggedTransactionsCents: taggedTransactionsCents,
              onAddContribution: () => _addContribution(context),
            ),
        },
      ),
    );
  }
}
