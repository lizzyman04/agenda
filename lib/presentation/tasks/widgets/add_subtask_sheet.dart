import 'package:agenda/application/tasks/project/project_cubit.dart';
import 'package:agenda/application/tasks/project/project_state.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Add-subtask sheet — StatefulWidget owning/disposing its controller (WR-03)
// ---------------------------------------------------------------------------

/// Bottom sheet for adding a subtask to a project.
///
/// Owns and disposes its own [TextEditingController] — see WR-03: this is
/// the correct controller-lifecycle pattern the rest of the codebase is
/// being retrofitted to match. Do not alter where the controller is
/// created or disposed.
class AddSubtaskSheet extends StatefulWidget {
  const AddSubtaskSheet({
    required this.projectId,
    required this.cubit,
    super.key,
  });

  final int projectId;
  final ProjectCubit cubit;

  @override
  State<AddSubtaskSheet> createState() => AddSubtaskSheetState();
}

class AddSubtaskSheetState extends State<AddSubtaskSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    await widget.cubit.addSubtask(projectId: widget.projectId, title: title);
    if (!mounted) return;
    final state = widget.cubit.state;
    if (state is ProjectError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.failure.message)),
      );
      return; // keep sheet open so user can retry
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.subtaskTitleHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _submit,
            child: Text(l10n.addSubtask),
          ),
        ],
      ),
    );
  }
}
