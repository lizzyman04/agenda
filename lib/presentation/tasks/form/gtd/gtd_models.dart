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
