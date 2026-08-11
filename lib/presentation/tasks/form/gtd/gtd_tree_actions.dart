import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_answers.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_models.dart';
import 'package:flutter/widgets.dart';

/// Everything the decision tree needs in order to build a node's options,
/// without knowing anything about widgets or navigation.
///
/// The sheet supplies the callbacks; the tree only ever calls them. This is
/// what lets the tree live in plain functions that a unit test can walk.
class GtdTreeContext {
  const GtdTreeContext({
    required this.l10n,
    required this.answers,
    required this.titleCtrl,
    required this.delegateCtrl,
    required this.push,
    required this.endWithSnackbar,
    required this.pickCustomDate,
    required this.abandon,
  });

  final AppLocalizations l10n;
  final GtdAnswers answers;

  final TextEditingController titleCtrl;
  final TextEditingController delegateCtrl;

  /// Advance to `node`.
  final void Function(GtdNode node) push;

  /// Close the guide, showing `message` — used by the "don't keep this task"
  /// branches that still want to tell the user what happened.
  final void Function(String message) endWithSnackbar;

  /// Open the date picker for a custom deadline.
  final VoidCallback pickCustomDate;

  /// Close the guide outright, discarding the task.
  final VoidCallback abandon;
}
