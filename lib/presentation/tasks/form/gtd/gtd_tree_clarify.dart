import 'package:agenda/domain/tasks/priority.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_answers.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_models.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_tree_actions.dart';
import 'package:flutter/material.dart';

/// The *clarify* half of the GTD tree: is this actionable, can it be
/// delegated, is it a two-minute job (q1 through q4b).
///
/// Returns null for nodes owned by the *prioritise* half.
GtdNodeSpec? clarifySpec(GtdNode node, GtdTreeContext ctx) {
  final l = ctx.l10n;
  final a = ctx.answers;

  return switch (node) {
    GtdNode.q1Title => GtdTextSpec(
        question: l.gtdQ1,
        icon: Icons.edit_note,
        controller: ctx.titleCtrl,
        hint: 'ex: Enviar proposta para o cliente',
        maxLength: 100,
        onNext: () {
          final text = ctx.titleCtrl.text.trim();
          if (text.isEmpty) return;
          a.gtdContext ??= GtdAnswers.inferContext(text);
          ctx.push(GtdNode.q2Actionable);
        },
      ),
    GtdNode.q2Actionable => GtdOptionSpec(
        question: l.gtdQ2,
        icon: Icons.help_outline,
        subtitle: 'Considere se isso trará valor real para você.',
        options: [
          (
            Icons.check_circle_outline,
            l.gtdAnswerYes,
            () => ctx.push(GtdNode.q3Delegate)
          ),
          (Icons.cancel, l.gtdAnswerNo, () => ctx.push(GtdNode.q2bWhyAdd)),
        ],
      ),
    GtdNode.q2bWhyAdd => GtdOptionSpec(
        question: l.gtdQ2bQuestion,
        icon: Icons.psychology,
        options: [
          (Icons.schedule, l.gtdQ2bSomedayMaybe, () {
            a
              ..priority = Priority.low
              ..gtdContext = 'someday';
            ctx.endWithSnackbar(l.gtdSomedayMessage);
          }),
          (Icons.lightbulb_outline, l.gtdQ2bIdea, () {
            a
              ..description = ctx.titleCtrl.text.trim()
              ..priority = Priority.low;
            ctx.endWithSnackbar(l.gtdIdeaSavedMessage);
          }),
          (
            Icons.person_add,
            l.gtdQ2bDelegated,
            () => ctx.push(GtdNode.q3Delegate)
          ),
          (
            Icons.add_task,
            l.gtdQ2bKeepAnyway,
            () => ctx.push(GtdNode.q3Delegate)
          ),
        ],
      ),
    GtdNode.q3Delegate => GtdOptionSpec(
        question: l.gtdQ3,
        icon: Icons.group,
        options: [
          (Icons.person, l.gtdAnswerNo, () => ctx.push(GtdNode.q4Quick)),
          (Icons.send, l.gtdAnswerYes, () => ctx.push(GtdNode.q3bDelegateName)),
        ],
      ),
    GtdNode.q3bDelegateName => GtdTextSpec(
        question: l.gtdQ3DelegateTo,
        icon: Icons.person_search,
        controller: ctx.delegateCtrl,
        hint: l.gtdQ3DelegateHint,
        onNext: () {
          final name = ctx.delegateCtrl.text.trim();
          if (name.isEmpty) return;
          a.waitingFor = name;
          ctx.push(GtdNode.q3cFollowUp);
        },
      ),
    GtdNode.q3cFollowUp => GtdOptionSpec(
        question: l.gtdQ3FollowUp,
        icon: Icons.notification_add,
        options: [
          (Icons.alarm_add, l.gtdAnswerYes, () {
            a.dueDate = DateTime.now().add(const Duration(days: 7));
            ctx.push(GtdNode.review);
          }),
          (Icons.check, l.gtdAnswerNo, () => ctx.push(GtdNode.review)),
        ],
      ),
    GtdNode.q4Quick => GtdOptionSpec(
        question: l.gtdQ4,
        icon: Icons.timer,
        subtitle: 'A regra dos 10 minutos: se sim, você deveria fazer agora.',
        options: [
          (Icons.east, l.gtdAnswerNo, () => ctx.push(GtdNode.q5Important)),
          (Icons.bolt, l.gtdAnswerYes, () => ctx.push(GtdNode.q4bWhyNotNow)),
        ],
      ),
    GtdNode.q4bWhyNotNow => GtdOptionSpec(
        question: l.gtdQ4bQuestion,
        icon: Icons.hourglass_empty,
        options: [
          (Icons.work, l.gtdQ4bBusy, () {
            a.dueDate = GtdAnswers.today();
            ctx.push(GtdNode.q5Important);
          }),
          (
            Icons.info_outline,
            l.gtdQ4bNeedContext,
            () => ctx.push(GtdNode.q5Important)
          ),
          (
            Icons.schedule,
            l.gtdQ4bNotRightTime,
            () => ctx.push(GtdNode.q5Important)
          ),
          (
            Icons.done_all,
            l.gtdQ4bDoItNow,
            () => ctx.endWithSnackbar(l.gtdDoItNowMessage)
          ),
          (
            Icons.more_horiz,
            l.gtdQ4bOther,
            () => ctx.push(GtdNode.q5Important)
          ),
        ],
      ),
    _ => null,
  };
}
