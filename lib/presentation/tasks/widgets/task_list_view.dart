import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Empty-state placeholder shown when the task list has no items.
class TaskListEmptyState extends StatelessWidget {
  const TaskListEmptyState({required this.l10n, super.key});
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

/// AppBar search field for filtering the task list.
class TaskSearchBar extends StatelessWidget implements PreferredSizeWidget {
  const TaskSearchBar({
    required this.hintText,
    required this.onChanged,
    super.key,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SearchBar(
        hintText: hintText,
        leading: const Icon(Icons.search),
        onChanged: onChanged,
      ),
    );
  }
}

/// Renders the list of [Item]s as [TaskCard]s, wired to [TaskListCubit].
class TaskListView extends StatelessWidget {
  const TaskListView({
    required this.items,
    required this.onEdit,
    super.key,
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
