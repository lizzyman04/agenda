import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_answers.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_models.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_tree_actions.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_tree_clarify.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_tree_prioritize.dart';
import 'package:agenda/presentation/tasks/form/gtd/widgets/gtd_cancel_dialog.dart';
import 'package:agenda/presentation/tasks/form/gtd/widgets/gtd_option_node.dart';
import 'package:agenda/presentation/tasks/form/gtd/widgets/gtd_review_node.dart';
import 'package:agenda/presentation/tasks/form/gtd/widgets/gtd_sheet_header.dart';
import 'package:agenda/presentation/tasks/form/gtd/widgets/gtd_sheet_scaffold.dart';
import 'package:agenda/presentation/tasks/form/gtd/widgets/gtd_text_node.dart';
import 'package:flutter/material.dart';

/// Bottom sheet walking the user through GTD clarification.
///
/// Owns the navigation history, the two text controllers, and the accumulated
/// [GtdAnswers]. The questions themselves live in `gtd_tree_clarify.dart` and
/// `gtd_tree_prioritize.dart` as pure functions; rendering lives in
/// `../widgets/`. Returns a [GtdResult] via `Navigator.pop`, or null when the
/// user abandons the flow.
class GtdGuideSheet extends StatefulWidget {
  const GtdGuideSheet({required this.l10n, super.key});

  final AppLocalizations l10n;

  @override
  State<GtdGuideSheet> createState() => _GtdGuideSheetState();
}

class _GtdGuideSheetState extends State<GtdGuideSheet> {
  final List<GtdNode> _history = [GtdNode.q1Title];
  final _titleCtrl = TextEditingController();
  final _delegateCtrl = TextEditingController();
  final _answers = GtdAnswers();

  GtdNode get _current => _history.last;

  void _push(GtdNode node) => setState(() => _history.add(node));

  void _pop() {
    if (_history.length > 1) setState(_history.removeLast);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _delegateCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmCancel() async {
    if (_titleCtrl.text.trim().isEmpty && _history.length <= 1) {
      Navigator.of(context).pop();
      return;
    }
    if (await showGtdCancelDialog(context, widget.l10n) && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _endWithSnackbar(String message) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _finish() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(_answers.toResult(title));
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _answers
        ..dueDate = picked
        ..isUrgent =
            picked.isBefore(DateTime.now().add(const Duration(days: 2)));
    });
    _push(GtdNode.q7Impact);
  }

  GtdTreeContext get _treeContext => GtdTreeContext(
        l10n: widget.l10n,
        answers: _answers,
        titleCtrl: _titleCtrl,
        delegateCtrl: _delegateCtrl,
        push: _push,
        endWithSnackbar: _endWithSnackbar,
        pickCustomDate: _pickCustomDate,
        abandon: () => Navigator.of(context).pop(),
      );

  Widget _buildNode() {
    final ctx = _treeContext;
    final spec = clarifySpec(_current, ctx) ?? prioritizeSpec(_current, ctx);

    return switch (spec) {
      GtdOptionSpec() => GtdOptionNode(spec: spec),
      GtdTextSpec() => GtdTextNode(spec: spec),
      GtdReviewSpec() => GtdReviewNode(
          title: _titleCtrl.text.trim(),
          answers: _answers,
          l10n: widget.l10n,
          onEdit: _pop,
          onSave: _finish,
        ),
      null => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _confirmCancel(),
      child: GtdSheetScaffold(
        nodeKey: ValueKey(_current),
        nodeBuilder: (_) => _buildNode(),
        header: GtdSheetHeader(
          step: gtdStepIndex(_history),
          totalSteps: gtdMainPath.length,
          canGoBack: _history.length > 1,
          onBack: _pop,
          onClose: _confirmCancel,
        ),
      ),
    );
  }
}
