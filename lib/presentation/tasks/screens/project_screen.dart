import 'package:agenda/application/tasks/project/project_cubit.dart';
import 'package:agenda/application/tasks/project/project_state.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Project screen — displays a project's subtasks with a completion
/// progress bar and a FAB to add new subtasks.
///
/// [projectId] is passed from the router path parameter.
class ProjectScreen extends StatefulWidget {
  const ProjectScreen({required this.projectId, super.key});

  final int projectId;

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProjectCubit>().loadProject(widget.projectId);
  }

  void _showAddSubtaskSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddSubtaskSheet(
        projectId: widget.projectId,
        cubit: context.read<ProjectCubit>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ProjectCubit, ProjectState>(
          builder: (context, state) {
            return Text(
              state is ProjectLoaded ? state.project.title : l10n.projectScreenTitle,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubtaskSheet(context),
        tooltip: l10n.addSubtask,
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<ProjectCubit, ProjectState>(
        builder: (context, state) {
          return switch (state) {
            ProjectInitial() || ProjectLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            ProjectError(:final failure) => Center(
                child: Text(failure.message),
              ),
            ProjectLoaded(
              :final subtasks,
              :final completedCount,
              :final totalCount,
              :final completionRatio,
            ) =>
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: completionRatio),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      l10n.subtasksProgress(completedCount, totalCount),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: subtasks.length,
                      itemBuilder: (context, index) {
                        final subtask = subtasks[index];
                        return TaskCard(
                          item: subtask,
                          onComplete: () => context
                              .read<ProjectCubit>()
                              .completeSubtask(subtask),
                          onDelete: () => context
                              .read<ProjectCubit>()
                              .deleteSubtask(subtask.id),
                          onTap: () {},
                        );
                      },
                    ),
                  ),
                ],
              ),
          };
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add-subtask sheet — StatefulWidget owning/disposing its controller (WR-03)
// ---------------------------------------------------------------------------

class _AddSubtaskSheet extends StatefulWidget {
  const _AddSubtaskSheet({required this.projectId, required this.cubit});

  final int projectId;
  final ProjectCubit cubit;

  @override
  State<_AddSubtaskSheet> createState() => _AddSubtaskSheetState();
}

class _AddSubtaskSheetState extends State<_AddSubtaskSheet> {
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
