import 'package:agenda/domain/finance/debt/debt.dart' hide clearField;
import 'package:agenda/domain/finance/goal/savings_goal.dart' hide clearField;
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Result of picking (or clearing) a finance link in [FinanceLinkSheet].
class FinanceLinkSelection {
  const FinanceLinkSelection({
    this.goalId,
    this.goalTitle,
    this.debtId,
    this.debtTitle,
  });

  /// No goal or debt linked.
  static const cleared = FinanceLinkSelection();

  final int? goalId;
  final String? goalTitle;
  final int? debtId;
  final String? debtTitle;
}

/// Bottom sheet listing active goals/debts plus a "no link" option.
///
/// Stateless: it holds no field state and returns the pick via
/// `Navigator.pop` rather than mutating the caller directly, following the
/// convention documented in `finance/goals/README.md`.
class FinanceLinkSheet extends StatelessWidget {
  const FinanceLinkSheet({
    required this.l10n,
    required this.activeGoals,
    required this.activeDebts,
    required this.linkedGoalId,
    required this.linkedDebtId,
    super.key,
  });

  final AppLocalizations l10n;
  final List<SavingsGoal> activeGoals;
  final List<Debt> activeDebts;
  final int? linkedGoalId;
  final int? linkedDebtId;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              l10n.linkToFinance,
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              children: [
                ListTile(
                  leading: const Icon(Icons.link_off),
                  title: const Text('Sem vínculo'),
                  onTap: () =>
                      Navigator.of(ctx).pop(FinanceLinkSelection.cleared),
                ),
                if (activeGoals.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      l10n.goalsTabLabel,
                      style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  ...activeGoals.map(
                    (g) => ListTile(
                      leading: const Icon(Icons.savings_outlined),
                      title: Text(g.title),
                      trailing: linkedGoalId == g.id
                          ? Icon(Icons.check,
                              color: Theme.of(ctx).colorScheme.primary)
                          : null,
                      onTap: () => Navigator.of(ctx).pop(
                        FinanceLinkSelection(goalId: g.id, goalTitle: g.title),
                      ),
                    ),
                  ),
                ],
                if (activeDebts.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      l10n.debtsTabLabel,
                      style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  ...activeDebts.map(
                    (d) => ListTile(
                      leading: const Icon(Icons.handshake_outlined),
                      title: Text(d.title),
                      subtitle: Text(d.counterparty),
                      trailing: linkedDebtId == d.id
                          ? Icon(Icons.check,
                              color: Theme.of(ctx).colorScheme.primary)
                          : null,
                      onTap: () => Navigator.of(ctx).pop(
                        FinanceLinkSelection(debtId: d.id, debtTitle: d.title),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
