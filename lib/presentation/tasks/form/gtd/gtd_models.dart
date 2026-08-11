import 'package:agenda/domain/tasks/priority.dart';
import 'package:flutter/widgets.dart';

/// One selectable option in the GTD guide: icon, label, and the action that
/// advances the tree.
typedef GtdOpt = (IconData, String, void Function());

/// The task fields the GTD guide produces once the user reaches the review
/// step. Returned from the guide sheet via `Navigator.pop`; the form applies
/// it to its own controllers.
class GtdResult {
  const GtdResult({
    required this.title,
    required this.priority,
    required this.isUrgent,
    required this.isImportant,
    this.dueDate,
    this.waitingFor,
    this.gtdContext,
    this.description,
  });

  final String title;
  final Priority priority;
  final bool isUrgent;
  final bool isImportant;
  final DateTime? dueDate;
  final String? waitingFor;
  final String? gtdContext;
  final String? description;
}

/// Nodes of the GTD clarification decision tree, in the order a user
/// encounters them. `q*b` nodes are the follow-up branches taken when the
/// preceding answer was negative.
enum GtdNode {
  q1Title,
  q2Actionable,
  q2bWhyAdd,
  q3Delegate,
  q3bDelegateName,
  q3cFollowUp,
  q4Quick,
  q4bWhyNotNow,
  q5Important,
  q5bWhyKeep,
  q6Deadline,
  q6bNoDeadlineReason,
  q7Impact,
  q7bWhyKeepNoImpact,
  review,
}

/// What a node should render, as data rather than widgets.
///
/// Keeping the decision tree free of widgets means it can be unit-tested by
/// walking nodes and asserting on options, with no pumping required.
sealed class GtdNodeSpec {
  const GtdNodeSpec();
}

/// A question answered by picking one of [options].
class GtdOptionSpec extends GtdNodeSpec {
  const GtdOptionSpec({
    required this.question,
    required this.icon,
    required this.options,
    this.subtitle,
  });

  final String question;
  final IconData icon;
  final List<GtdOpt> options;
  final String? subtitle;
}

/// A question answered by typing free text.
class GtdTextSpec extends GtdNodeSpec {
  const GtdTextSpec({
    required this.question,
    required this.icon,
    required this.controller,
    required this.onNext,
    this.hint,
    this.maxLength,
  });

  final String question;
  final IconData icon;
  final TextEditingController controller;
  final VoidCallback onNext;
  final String? hint;
  final int? maxLength;
}

/// The terminal summary step.
class GtdReviewSpec extends GtdNodeSpec {
  const GtdReviewSpec();
}

/// The eight questions on the tree's happy path.
///
/// Progress is measured against this list only, so the follow-up `q*b`
/// branches never make the progress bar jump backwards.
const gtdMainPath = <GtdNode>[
  GtdNode.q1Title,
  GtdNode.q2Actionable,
  GtdNode.q3Delegate,
  GtdNode.q4Quick,
  GtdNode.q5Important,
  GtdNode.q6Deadline,
  GtdNode.q7Impact,
  GtdNode.review,
];

/// Index into [gtdMainPath] of the furthest main-path node in [history].
int gtdStepIndex(List<GtdNode> history) {
  final idx = history.lastIndexWhere(gtdMainPath.contains);
  return idx >= 0 ? idx : 0;
}
