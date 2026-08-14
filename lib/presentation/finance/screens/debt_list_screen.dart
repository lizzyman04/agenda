import 'dart:async';

import 'package:agenda/application/finance/debt/debt_cubit.dart';
import 'package:agenda/application/finance/debt/debt_state.dart';
import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/finance/debt/debt.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/screens/debt_form_screen.dart';
import 'package:agenda/presentation/finance/widgets/debt/debt_card.dart';
import 'package:agenda/presentation/finance/widgets/finance_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the list of debts (to pay and to receive).
///
/// Each debt shows a [SwitchListTile] to toggle paid status.
/// Swipe-to-delete triggers a soft delete with a 5-second undo snackbar.
/// FAB adds new debts.
class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DebtCubit>().start();
  }

  void _openForm({Debt? debt}) {
    // DebtCubit is provided above MaterialApp, so the pushed route inherits it.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DebtFormScreen(debt: debt),
      ),
    );
  }

  void _handleDelete(BuildContext context, Debt debt) {
    // Capture both before anything can unmount this context. The SnackBar
    // action closure below outlives the row it was fired from, and reading
    // a cubit off a dead context inside that closure is a live crash.
    final cubit = context.read<DebtCubit>();
    final messenger = ScaffoldMessenger.of(context);
    // Fire-and-forget: the SnackBar must appear on this frame, not after
    // the write settles. The cubit reloads the list on its own.
    unawaited(cubit.softDelete(debt.id));
    // ScaffoldMessenger queues SnackBars FIFO. Without an explicit hide, a
    // second swipe inside the undo window waits behind the first instead of
    // replacing it, and the visible SnackBar keeps the FIRST delete's action
    // closure — Desfazer then restores the wrong debt and the queued
    // SnackBar pops up after it. Distinct from the auto-dismiss fix below
    // (that governs WHEN a SnackBar leaves, not WHICH one). Keep both.
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).debtDeleted),
          duration: AppConstants.undoSnackbarDuration,
          // persist defaults to `action != null` since Flutter 3.38, which
          // suppresses auto-dismiss entirely. The undo window must expire on
          // its own, so opt back out explicitly.
          persist: false,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: AppLocalizations.of(context).undo,
            onPressed: () => cubit.restoreDebt(debt.id),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const currencySymbol = 'MT';
    final locale = Localizations.localeOf(context);

    return BlocBuilder<DebtCubit, DebtState>(
      builder: (context, state) {
        return switch (state) {
          DebtInitial() || DebtLoading() =>
            const Center(child: CircularProgressIndicator()),
          DebtError(:final failure) =>
            Center(child: Text(failure.message)),
          DebtLoaded(:final debts) when debts.isEmpty =>
            FinanceEmptyState(
              icon: Icons.handshake_outlined,
              heading: l10n.emptyDebts,
              body: l10n.emptyDebtsBody,
              ctaLabel: l10n.addDebt,
              onCta: _openForm,
            ),
          DebtLoaded(:final debts) => Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemCount: debts.length,
                  itemBuilder: (ctx, i) {
                    final debt = debts[i];
                    return DebtCard(
                      debt: debt,
                      currencySymbol: currencySymbol,
                      locale: locale,
                      onTap: () => _openForm(debt: debt),
                      onTogglePaid: () =>
                          ctx.read<DebtCubit>().togglePaid(debt.id),
                      onDelete: () => _handleDelete(ctx, debt),
                    );
                  },
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    tooltip: l10n.addDebt,
                    onPressed: _openForm,
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
        };
      },
    );
  }
}
