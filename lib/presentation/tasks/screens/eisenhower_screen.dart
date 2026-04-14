import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_state.dart';
import 'package:agenda/domain/tasks/eisenhower_quadrant.dart';
import 'package:agenda/domain/tasks/item.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/widgets/quadrant_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Eisenhower Matrix board — renders a 2x2 grid of [QuadrantCard] widgets.
///
/// Reads tasks from [TaskListCubit] and partitions them by
/// [Item.eisenhowerQuadrant].
class EisenhowerScreen extends StatelessWidget {
  const EisenhowerScreen({super.key});

  List<Item> _filterQuadrant(List<Item> items, EisenhowerQuadrant q) =>
      items.where((i) => i.eisenhowerQuadrant == q).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eisenhowerTitle),
      ),
      body: BlocBuilder<TaskListCubit, TaskListState>(
        builder: (context, state) {
          final items = switch (state) {
            TaskListLoaded(:final items) => items,
            TaskListWithPendingUndo(:final items) => items,
            _ => <Item>[],
          };

          final doNow = _filterQuadrant(items, EisenhowerQuadrant.doNow);
          final schedule =
              _filterQuadrant(items, EisenhowerQuadrant.schedule);
          final delegate =
              _filterQuadrant(items, EisenhowerQuadrant.delegate);
          final eliminate =
              _filterQuadrant(items, EisenhowerQuadrant.eliminate);

          return Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: QuadrantCard(
                        label: l10n.eisenhowerDoNow,
                        items: doNow,
                        headerColor: cs.errorContainer,
                      ),
                    ),
                    Expanded(
                      child: QuadrantCard(
                        label: l10n.eisenhowerSchedule,
                        items: schedule,
                        headerColor: cs.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: QuadrantCard(
                        label: l10n.eisenhowerDelegate,
                        items: delegate,
                        headerColor: cs.tertiaryContainer,
                      ),
                    ),
                    Expanded(
                      child: QuadrantCard(
                        label: l10n.eisenhowerEliminate,
                        items: eliminate,
                        headerColor: cs.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
