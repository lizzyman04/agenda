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
  const ProjectScreen({super.key, required this.projectId});

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
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.subtaskTitleHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final title = controller.text.trim();
                  if (title.isNotEmpty) {
                    context.read<ProjectCubit>().addSubtask(
                          projectId: widget.projectId,
                          title: title,
                        );
                  }
                  Navigator.of(sheetContext).pop();
                },
                child: Text(l10n.addSubtask),
              ),
            ],
          ),
        );
      },
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
