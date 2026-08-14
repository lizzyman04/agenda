import 'dart:async';

import 'package:agenda/config/di/injection.dart';
import 'package:agenda/domain/finance/debt/debt_repository.dart';
import 'package:agenda/domain/finance/goal/goal_repository.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/form/task_form_logic.dart';
import 'package:flutter/material.dart';

/// Chip linking to the goal or debt this task funds, when one is linked.
/// Renders nothing otherwise, so callers can place it unconditionally in a
/// `Column`.
///
/// Stateful because naming the linked entity means reading it out of the
/// finance aggregate: `initState` resolves the goal/debt title through the
/// same finance-link helper the task form already uses.
class TaskDetailFinanceChip extends StatefulWidget {
  const TaskDetailFinanceChip({required this.item, super.key});

  final Item item;

  @override
  State<TaskDetailFinanceChip> createState() => _TaskDetailFinanceChipState();
}

class _TaskDetailFinanceChipState extends State<TaskDetailFinanceChip> {
  /// Resolved title of the linked goal/debt; null until the lookup returns,
  /// and null forever when the linked entity no longer exists.
  String? _linkedTitle;

  @override
  void initState() {
    super.initState();
    final goalId = widget.item.linkedGoalId;
    final debtId = widget.item.linkedDebtId;
    // The chip is placed unconditionally on every task detail screen, so an
    // unlinked task must stay zero-cost: no repository call at all.
    if (goalId == null && debtId == null) return;
    // unawaited — fire-and-forget is intentional in initState.
    unawaited(
      loadFinanceLinks(
        getIt<GoalRepository>(),
        getIt<DebtRepository>(),
        linkedGoalId: goalId,
        linkedDebtId: debtId,
      ).then((s) {
        if (mounted) {
          setState(() => _linkedTitle = s.linkedGoalTitle ?? s.linkedDebtTitle);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.linkedGoalId == null && widget.item.linkedDebtId == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isGoal = widget.item.linkedGoalId != null;
    final kindLabel = isGoal ? l10n.goalsTabLabel : l10n.debtsTabLabel;
    // Deliberate fallback: the kind label plus the raw id is the DEGRADED
    // case, shown only for the first frame before the lookup resolves, or
    // when the linked goal/debt has since been deleted. The resolved title
    // is the normal case.
    final label = _linkedTitle ??
        '$kindLabel #${widget.item.linkedGoalId ?? widget.item.linkedDebtId}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Wrap(
        children: [
          ActionChip(
            avatar: const Icon(Icons.link, size: 16),
            label: Text('${l10n.linkedTo} $label'),
            backgroundColor: cs.secondaryContainer,
            onPressed: () {
              // Navigation to finance detail is deferred to plan 03-05 when
              // deep-link routing is set up.
            },
          ),
        ],
      ),
    );
  }
}
