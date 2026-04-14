import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/screens/gtd_filter_screen.dart';
import 'package:agenda/presentation/tasks/screens/task_form_screen.dart';
import 'package:agenda/presentation/tasks/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Task list screen — the primary entry point for task management.
///
/// Uses [BlocConsumer] to both rebuild the list and respond to
/// [TaskListWithPendingUndo] state by showing a 5-second undo [SnackBar].
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TaskListCubit>().start();
  }

  void _navigateToCreate() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<TaskListCubit>(),
          child: const TaskFormScreen(),
        ),
      ),
    );
  }

  void _navigateToEdit(Item item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<TaskListCubit>(),
          child: TaskFormScreen(item: item),
        ),
      ),
    );
  }

  void _navigateToGtdFilter() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<TaskListCubit>(),
          child: const GtdFilterScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tasksScreenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: l10n.gtdFilterTitle,
            onPressed: _navigateToGtdFilter,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBar(
              hintText: l10n.searchTasks,
              leading: const Icon(Icons.search),
              onChanged: (query) =>
                  context.read<TaskListCubit>().search(query),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreate,
        tooltip: l10n.addTask,
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<TaskListCubit, TaskListState>(
        listener: (context, state) {
          if (state is TaskListWithPendingUndo) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: AppConstants.undoSnackbarDuration,
                content: Text(l10n.taskDeleted),
                action: SnackBarAction(
                  label: l10n.undo,
                  onPressed: () => context
                      .read<TaskListCubit>()
                      .restoreItem(state.deletedItemId),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            TaskListInitial() || TaskListLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            TaskListError(:final failure) => Center(
                child: Text(failure.message),
              ),
            TaskListLoaded(:final items) when items.isEmpty =>
              _EmptyState(l10n: l10n),
            TaskListLoaded(:final items) => _TaskList(
                items: items,
                onEdit: _navigateToEdit,
              ),
            TaskListWithPendingUndo(:final items) => _TaskList(
                items: items,
                onEdit: _navigateToEdit,
              ),
          };
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_box_outline_blank, size: 64),
          const SizedBox(height: 16),
          Text(
            l10n.noTasks,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.items,
    required this.onEdit,
  });

  final List<Item> items;
  final void Function(Item item) onEdit;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return TaskCard(
          item: item,
          onComplete: () =>
              context.read<TaskListCubit>().completeItem(item),
          onDelete: () =>
              context.read<TaskListCubit>().softDelete(item.id),
          onTap: () => onEdit(item),
        );
      },
    );
  }
}
