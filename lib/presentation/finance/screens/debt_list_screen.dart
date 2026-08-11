import 'package:agenda/application/finance/debt/debt_cubit.dart';
import 'package:agenda/application/finance/debt/debt_state.dart';
import 'package:agenda/domain/finance/debt.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/screens/debt_form_screen.dart';
import 'package:agenda/presentation/finance/widgets/debt/debt_card.dart';
import 'package:agenda/presentation/finance/widgets/finance_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the list of debts (to pay and to receive).
///
/// Each debt shows a [SwitchListTile] to toggle paid status.
/// Supports swipe-to-delete and FAB to add new debts.
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
                      onDelete: () =>
                          ctx.read<DebtCubit>().softDelete(debt.id),
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
