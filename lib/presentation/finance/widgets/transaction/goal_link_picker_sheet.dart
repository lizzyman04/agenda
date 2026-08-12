import 'package:agenda/domain/finance/goal/savings_goal.dart';
import 'package:flutter/material.dart';

/// Bottom-sheet content for linking (or clearing the link to) a
/// [SavingsGoal] on an expense transaction.
///
/// Stateless: it holds no field state and resolves its result exclusively
/// via `Navigator.pop(int?)` — `null` means "no link", a goal's id means
/// that goal was picked. The caller applies the popped value via `setState`
/// only after the sheet has closed, following the pop-not-mutate convention
/// documented in `presentation/finance/goals/README.md`.
class GoalLinkPickerSheet extends StatelessWidget {
  const GoalLinkPickerSheet({
    required this.activeGoals,
    required this.selectedGoalId,
    super.key,
  });

  /// The already-loaded list of active goals. This widget does not fetch
  /// goals itself.
  final List<SavingsGoal> activeGoals;

  /// Id of the currently-linked goal, used to render the trailing check
  /// icon. `null` if no goal is linked yet.
  final int? selectedGoalId;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.7,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // None option to clear link
          ListTile(
            leading: const Icon(Icons.link_off),
            title: const Text('Sem vínculo'),
            trailing: selectedGoalId == null
                ? Icon(Icons.check,
                    color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () => Navigator.of(context).pop(),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              itemCount: activeGoals.length,
              itemBuilder: (_, i) {
                final goal = activeGoals[i];
                return ListTile(
                  leading: const Icon(Icons.savings_outlined),
                  title: Text(goal.title),
                  trailing: selectedGoalId == goal.id
                      ? Icon(Icons.check,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop<int?>(goal.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
