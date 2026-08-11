import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_answers.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_models.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_tree_actions.dart';
import 'package:flutter/material.dart';

/// The two GTD questions whose options are computed rather than fixed:
/// the deadline choice (relative dates off today) and the impact scale.
///
/// Split out of the prioritise half because both build their option lists at
/// call time from the current date and answers.

GtdOptionSpec deadlineSpec(GtdTreeContext ctx) {
  final l = ctx.l10n;
  final a = ctx.answers;
  final now = DateTime.now();

  return GtdOptionSpec(
    question: l.gtdQ6,
    icon: Icons.calendar_today,
    options: [
      (Icons.today, l.gtdDeadlineToday, () {
        a
          ..dueDate = GtdAnswers.today()
          ..isUrgent = true;
        ctx.push(GtdNode.q7Impact);
      }),
      (Icons.event, l.gtdDeadlineTomorrow, () {
        a
          ..dueDate = now.add(const Duration(days: 1))
          ..isUrgent = true;
        ctx.push(GtdNode.q7Impact);
      }),
      (Icons.date_range, l.gtdDeadlineThisWeek, () {
        a.dueDate = now.add(const Duration(days: 7));
        ctx.push(GtdNode.q7Impact);
      }),
      (Icons.calendar_month, l.gtdDeadlineNext20Days, () {
        a.dueDate = now.add(const Duration(days: 20));
        ctx.push(GtdNode.q7Impact);
      }),
      (Icons.calendar_view_month, l.gtdDeadlineThisMonth, () {
        a.dueDate = DateTime(now.year, now.month + 1, now.day);
        ctx.push(GtdNode.q7Impact);
      }),
      (Icons.block, l.gtdDeadlineNoDeadline, () {
        a.dueDate = null;
        ctx.push(GtdNode.q6bNoDeadlineReason);
      }),
      (Icons.edit_calendar, l.gtdDeadlineCustom, ctx.pickCustomDate),
    ],
  );
}

GtdOptionSpec impactSpec(GtdTreeContext ctx) {
  final l = ctx.l10n;
  final a = ctx.answers;

  return GtdOptionSpec(
    question: l.gtdQ7,
    icon: Icons.show_chart,
    options: [
      (Icons.warning_amber, l.gtdImpactVeryNegative, () {
        a
          ..priority = Priority.urgent
          ..isImportant = true
          ..isUrgent = a.dueDate != null;
        ctx.push(GtdNode.review);
      }),
      (Icons.trending_down, l.gtdImpactNegative, () {
        a
          ..priority = Priority.high
          ..isImportant = true;
        ctx.push(GtdNode.review);
      }),
      (Icons.remove, l.gtdImpactModerate, () => ctx.push(GtdNode.review)),
      (Icons.expand_less, l.gtdImpactLight, () {
        a.priority = Priority.low;
        ctx.push(GtdNode.review);
      }),
      (Icons.minimize, l.gtdImpactVeryLight, () {
        a.priority = Priority.low;
        ctx.push(GtdNode.review);
      }),
      (
        Icons.not_interested,
        l.gtdImpactNone,
        () => ctx.push(GtdNode.q7bWhyKeepNoImpact)
      ),
    ],
  );
}
