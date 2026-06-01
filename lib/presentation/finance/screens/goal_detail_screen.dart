import 'dart:async';

import 'package:agenda/application/finance/goal/goal_cubit.dart';
import 'package:agenda/application/finance/goal/goal_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/utils/amount_formatter.dart';
import 'package:agenda/domain/finance/savings_goal_contribution.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/screens/goal_form_screen.dart';
import 'package:agenda/presentation/finance/widgets/goal_progress_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Detail screen for a single savings goal.
///
/// Shows progress, contribution history, and allows adding new contributions.
/// Provides edit and delete actions in the AppBar.
class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({required this.goalId, super.key});

  final int goalId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GoalCubit>()..loadGoal(goalId),
      child: _GoalDetailView(goalId: goalId),
    );
  }
}

class _GoalDetailView extends StatelessWidget {
  const _GoalDetailView({required this.goalId});
  final int goalId;

  Future<void> _addContribution(BuildContext context) async {
    final cubit = context.read<GoalCubit>();
    final l10n = AppLocalizations.of(context);
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var selectedDate = DateTime.now();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.addContribution,
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.fieldAmount,
                      hintText: '0,00',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(
                        DateFormat('dd/MM/yyyy').format(selectedDate)),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.fieldNote,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () {
                      final raw = amountCtrl.text
                          .replaceAll(',', '.')
                          .replaceAll(RegExp(r'[^\d.]'), '');
                      final parsed = double.tryParse(raw);
                      if (parsed != null && parsed > 0) {
                        final contribution = SavingsGoalContribution(
                          amountCents: (parsed * 100).round(),
                          date: selectedDate,
                          note: noteCtrl.text.trim().isNotEmpty
                              ? noteCtrl.text.trim()
                              : null,
                        );
                        unawaited(
                            cubit.addContribution(goalId, contribution));
                      }
                      Navigator.of(ctx).pop();
                    },
                    child: Text(l10n.addContribution),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
    amountCtrl.dispose();
    noteCtrl.dispose();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir objetivo?'),
        content: const Text(
            'O progresso e contribuições serão perdidos. Deseja continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<GoalCubit>().softDeleteGoal(goalId);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const currencySymbol = 'MT';
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.goalsTabLabel),
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.editButton,
            onPressed: () {
              final state = context.read<GoalCubit>().state;
              if (state is GoalLoaded) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GoalFormScreen(goal: state.goal),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.deleteGoal,
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: BlocBuilder<GoalCubit, GoalState>(
        builder: (context, state) {
          return switch (state) {
            GoalInitial() || GoalLoading() =>
              const Center(child: CircularProgressIndicator()),
            GoalError(:final failure) =>
              Center(child: Text(failure.message)),
            GoalLoaded(:final goal, :final taggedTransactionsCents) =>
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Progress header card
                  GoalProgressCard(
                    goal: goal,
                    taggedTransactionsCents: taggedTransactionsCents,
                    currencySymbol: currencySymbol,
                    locale: locale,
                    onTap: () {}, // already on detail screen
                  ),
                  const SizedBox(height: 16),

                  // Add contribution button
                  FilledButton.tonal(
                    onPressed: () => _addContribution(context),
                    child: Text(l10n.addContribution),
                  ),
                  const SizedBox(height: 16),

                  // Contribution history
                  if (goal.contributions.isNotEmpty) ...[
                    Text(
                      'Histórico de contribuições',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...goal.contributions.reversed.map(
                      (c) => Card(
                        elevation: 0,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading:
                              const Icon(Icons.add_circle_outline),
                          title: Text(
                            formatAmount(
                                c.amountCents, currencySymbol, locale),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            DateFormat('dd/MM/yyyy').format(c.date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: c.note != null
                              ? Text(
                                  c.note!,
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          };
        },
      ),
    );
  }
}
