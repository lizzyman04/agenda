import 'dart:async';

import 'package:agenda/application/tasks/task_list/task_list_cubit.dart';
import 'package:agenda/application/tasks/task_list/task_list_filter.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:agenda/domain/tasks/item_repository.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/widgets/gtd_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// Screen that shows distinct GTD context tags and lets the user filter
/// the task list by one context (TASK-09).
///
/// Fetches distinct gtdContext values from [ItemRepository], displays them
/// as [GtdChip] widgets, and applies the selected context to [TaskListCubit]
/// when the user taps "Aplicar" / "Apply".
class GtdFilterScreen extends StatefulWidget {
  const GtdFilterScreen({super.key, this.usedAsTab = false});

  /// When true, the screen is embedded as a nav tab — skip Navigator.pop().
  final bool usedAsTab;

  @override
  State<GtdFilterScreen> createState() => _GtdFilterScreenState();
}

class _GtdFilterScreenState extends State<GtdFilterScreen> {
  List<String> _contexts = [];
  String? _selectedContext;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // unawaited — fire-and-forget is intentional in initState
    unawaited(_loadContexts());
  }

  Future<void> _loadContexts() async {
    final repo = GetIt.instance<ItemRepository>();
    final result = await repo.getDistinctGtdContexts();
    if (!mounted) return;
    if (result is Success<List<String>>) {
      setState(() {
        _contexts = result.value;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _apply() async {
    await context.read<TaskListCubit>().applyFilter(
          TaskListFilter(gtdContext: _selectedContext),
        );
    if (!mounted) return;
    if (widget.usedAsTab) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).filterApplied),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _clear() async {
    await context.read<TaskListCubit>().applyFilter(TaskListFilter.empty);
    if (mounted && !widget.usedAsTab) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gtdFilterTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _contexts.isEmpty
                      ? Center(child: Text(l10n.noGtdContexts))
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _contexts
                                .map(
                                  (ctx) => GtdChip(
                                    label: ctx,
                                    isSelected: _selectedContext == ctx,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedContext =
                                            selected ? ctx : null;
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clear,
                          child: Text(l10n.clearFilter),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _apply,
                          child: Text(l10n.applyFilter),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
