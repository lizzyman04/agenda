import 'package:agenda/application/finance/goal/goal_list_cubit.dart';
import 'package:agenda/application/finance/goal/goal_list_state.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/goals/screens/goal_detail_screen.dart';
import 'package:agenda/presentation/finance/goals/screens/goal_form_screen.dart';
import 'package:agenda/presentation/finance/widgets/finance_empty_state.dart';
import 'package:agenda/presentation/finance/goals/widgets/goal_progress_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the list of active savings goals.
///
/// Empty state prompts the user to create their first goal.
/// FAB and empty state CTA both navigate to [GoalFormScreen].
/// Tapping a card navigates to [GoalDetailScreen].
class GoalListScreen extends StatefulWidget {
  const GoalListScreen({super.key});

  @override
  State<GoalListScreen> createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GoalListCubit>().start();
  }

  void _openForm() {
    // GoalFormScreen creates its own GoalCubit via getIt; the list refreshes
    // through GoalListCubit's watch stream. No provider wrapper needed here.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const GoalFormScreen(),
      ),
    );
  }

  void _openDetail(int goalId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GoalDetailScreen(goalId: goalId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const currencySymbol = 'MT';
    final locale = Localizations.localeOf(context);

    return BlocBuilder<GoalListCubit, GoalListState>(
      builder: (context, state) {
        return switch (state) {
          GoalListInitial() || GoalListLoading() =>
            const Center(child: CircularProgressIndicator()),
          GoalListError(:final failure) =>
            Center(child: Text(failure.message)),
          GoalListLoaded(:final goals) when goals.isEmpty =>
            FinanceEmptyState(
              icon: Icons.savings_outlined,
              heading: l10n.emptyGoals,
              body: l10n.emptyGoalsBody,
              ctaLabel: l10n.addGoal,
              onCta: _openForm,
            ),
          GoalListLoaded(:final goals) => Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemCount: goals.length,
                  itemBuilder: (_, i) {
                    final goal = goals[i];
                    return GoalProgressCard(
                      goal: goal,
                      taggedTransactionsCents: 0, // full in detail screen
                      currencySymbol: currencySymbol,
                      locale: locale,
                      onTap: () => _openDetail(goal.id),
                    );
                  },
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    tooltip: l10n.addGoal,
                    onPressed: _openForm,
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
        };
      },
    );
  }
}
