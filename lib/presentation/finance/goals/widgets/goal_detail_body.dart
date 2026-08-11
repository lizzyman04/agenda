import 'package:agenda/domain/finance/savings_goal.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/goals/widgets/contribution_history_list.dart';
import 'package:agenda/presentation/finance/goals/widgets/goal_progress_card.dart';
import 'package:flutter/material.dart';

/// Loaded-state body of the goal detail screen.
///
/// Composes the progress header, the add-contribution action, and the
/// contribution history. Stateless and cubit-free — the screen owns the
/// GoalCubit and passes [onAddContribution] down, so this widget stays
/// renderable in isolation and in widget tests.
class GoalDetailBody extends StatelessWidget {
  const GoalDetailBody({
    required this.goal,
    required this.taggedTransactionsCents,
    required this.onAddContribution,
    super.key,
  });

  final SavingsGoal goal;
  final int taggedTransactionsCents;
  final VoidCallback onAddContribution;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    const currencySymbol = 'MT';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GoalProgressCard(
          goal: goal,
          taggedTransactionsCents: taggedTransactionsCents,
          currencySymbol: currencySymbol,
          locale: locale,
          onTap: () {}, // already on detail screen
        ),
        const SizedBox(height: 16),
        FilledButton.tonal(
          onPressed: onAddContribution,
          child: Text(l10n.addContribution),
        ),
        const SizedBox(height: 16),
        ContributionHistoryList(
          contributions: goal.contributions,
          currencySymbol: currencySymbol,
          locale: locale,
        ),
      ],
    );
  }
}
