import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_models.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_tree_actions.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_tree_scheduling.dart';
import 'package:flutter/material.dart';

/// The *prioritise* half of the GTD tree: importance, deadline, and impact
/// (q5 through review).
///
/// Returns null for nodes owned by the *clarify* half.
GtdNodeSpec? prioritizeSpec(GtdNode node, GtdTreeContext ctx) {
  final l = ctx.l10n;
  final a = ctx.answers;

  return switch (node) {
    GtdNode.q5Important => GtdOptionSpec(
        question: l.gtdQ5,
        icon: Icons.star_outline,
        options: [
          (Icons.check_circle_outline, l.gtdAnswerYes, () {
            a.isImportant = true;
            ctx.push(GtdNode.q6Deadline);
          }),
          (Icons.remove_circle_outline, l.gtdAnswerNo, () {
            a.isImportant = false;
            ctx.push(GtdNode.q5bWhyKeep);
          }),
        ],
      ),
    GtdNode.q5bWhyKeep => GtdOptionSpec(
        question: l.gtdQ5bQuestion,
        icon: Icons.help,
        options: [
          (Icons.assignment, l.gtdQ5bObligation, () {
            a.demoteIfUnset();
            ctx.push(GtdNode.q6Deadline);
          }),
          (Icons.person_pin, l.gtdQ5bSomeoneAsking, () {
            a
              ..isUrgent = true
              ..priority = Priority.high;
            ctx.push(GtdNode.q6Deadline);
          }),
          (Icons.notifications_none, l.gtdQ5bReminder, () {
            a.demoteIfUnset();
            ctx.push(GtdNode.q6Deadline);
          }),
          (Icons.cancel, l.gtdQ5bCancelTask, ctx.abandon),
          (
            Icons.more_horiz,
            l.gtdQ5bOther,
            () => ctx.push(GtdNode.q6Deadline)
          ),
        ],
      ),
    GtdNode.q6Deadline => deadlineSpec(ctx),
    GtdNode.q6bNoDeadlineReason => GtdOptionSpec(
        question: l.gtdQ6bQuestion,
        icon: Icons.event_busy,
        options: [
          (Icons.repeat, l.gtdQ6bHabit, () => ctx.push(GtdNode.q7Impact)),
          (Icons.alarm_off, l.gtdQ6bNotUrgent, () {
            a.demoteIfUnset();
            ctx.push(GtdNode.q7Impact);
          }),
          (Icons.hourglass_empty, l.gtdQ6bWhenever, () {
            a.demoteIfUnset();
            ctx.push(GtdNode.q7Impact);
          }),
          (Icons.more_horiz, l.gtdQ6bOther, () => ctx.push(GtdNode.q7Impact)),
        ],
      ),
    GtdNode.q7Impact => impactSpec(ctx),
    GtdNode.q7bWhyKeepNoImpact => GtdOptionSpec(
        question: l.gtdQ7bQuestion,
        icon: Icons.help_outline,
        options: [
          (Icons.favorite_border, l.gtdQ7bPersonalWish, () {
            a
              ..priority = Priority.low
              ..gtdContext ??= 'wishlist';
            ctx.push(GtdNode.review);
          }),
          (Icons.people_outline, l.gtdQ7bSomeoneExpects, () {
            a.waitingFor ??= 'alguém';
            ctx.push(GtdNode.review);
          }),
          (Icons.cancel, l.gtdQ7bCancelTask, ctx.abandon),
          (Icons.more_horiz, l.gtdQ7bOther, () {
            a.priority = Priority.low;
            ctx.push(GtdNode.review);
          }),
        ],
      ),
    GtdNode.review => const GtdReviewSpec(),
    _ => null,
  };
}
