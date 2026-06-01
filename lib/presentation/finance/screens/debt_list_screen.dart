import 'package:agenda/application/finance/debt/debt_cubit.dart';
import 'package:agenda/application/finance/debt/debt_state.dart';
import 'package:agenda/core/utils/amount_formatter.dart';
import 'package:agenda/domain/finance/debt.dart';
import 'package:agenda/domain/finance/debt_direction.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/screens/debt_form_screen.dart';
import 'package:agenda/presentation/finance/widgets/finance_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<DebtCubit>(),
          child: DebtFormScreen(debt: debt),
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
                    return _DebtCard(
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

class _DebtCard extends StatelessWidget {
  const _DebtCard({
    required this.debt,
    required this.currencySymbol,
    required this.locale,
    required this.onTap,
    required this.onTogglePaid,
    required this.onDelete,
  });

  final Debt debt;
  final String currencySymbol;
  final Locale locale;
  final VoidCallback onTap;
  final VoidCallback onTogglePaid;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final directionLabel = debt.direction == DebtDirection.toPay
        ? l10n.toPay
        : l10n.toReceive;

    return Dismissible(
      key: Key('debt-${debt.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  debt.title,
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  '${debt.counterparty} · '
                  '${DateFormat('dd/MM/yyyy').format(debt.dueDate)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatAmount(debt.amountCents, currencySymbol, locale),
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: debt.direction == DebtDirection.toPay
                            ? cs.errorContainer
                            : cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        directionLabel,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                dense: true,
                title: Text(
                  debt.isPaid ? 'Pago' : 'Pendente',
                  style: theme.textTheme.bodySmall,
                ),
                value: debt.isPaid,
                onChanged: (_) => onTogglePaid(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
