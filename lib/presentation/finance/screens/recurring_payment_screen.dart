import 'package:agenda/application/finance/recurring/recurring_payment_cubit.dart';
import 'package:agenda/application/finance/recurring/recurring_payment_state.dart';
import 'package:agenda/core/utils/amount_formatter.dart';
import 'package:agenda/domain/finance/recurring_cycle.dart';
import 'package:agenda/domain/finance/recurring_payment.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/screens/recurring_payment_form_screen.dart';
import 'package:agenda/presentation/finance/widgets/finance_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Displays the list of active recurring payments.
///
/// Each payment shows title, amount, cycle, next due date, and an isActive
/// SwitchListTile. FAB navigates to [RecurringPaymentFormScreen].
class RecurringPaymentScreen extends StatefulWidget {
  const RecurringPaymentScreen({super.key});

  @override
  State<RecurringPaymentScreen> createState() =>
      _RecurringPaymentScreenState();
}

class _RecurringPaymentScreenState
    extends State<RecurringPaymentScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RecurringPaymentCubit>().start();
  }

  void _openForm({RecurringPayment? payment}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<RecurringPaymentCubit>(),
          child: RecurringPaymentFormScreen(payment: payment),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const currencySymbol = 'MT';
    final locale = Localizations.localeOf(context);

    return BlocBuilder<RecurringPaymentCubit, RecurringPaymentState>(
      builder: (context, state) {
        return switch (state) {
          RecurringPaymentInitial() || RecurringPaymentLoading() =>
            const Center(child: CircularProgressIndicator()),
          RecurringPaymentError(:final failure) =>
            Center(child: Text(failure.message)),
          RecurringPaymentLoaded(:final payments) when payments.isEmpty =>
            FinanceEmptyState(
              icon: Icons.repeat_outlined,
              heading: l10n.emptyRecurring,
              body: l10n.emptyRecurringBody,
              ctaLabel: l10n.addRecurring,
              onCta: _openForm,
            ),
          RecurringPaymentLoaded(:final payments) => Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemCount: payments.length,
                  itemBuilder: (ctx, i) {
                    final payment = payments[i];
                    return _RecurringPaymentCard(
                      payment: payment,
                      currencySymbol: currencySymbol,
                      locale: locale,
                      onTap: () => _openForm(payment: payment),
                      onToggleActive: () => ctx
                          .read<RecurringPaymentCubit>()
                          .updatePayment(
                              payment.copyWith(isActive: !payment.isActive)),
                    );
                  },
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    tooltip: l10n.addRecurring,
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

class _RecurringPaymentCard extends StatelessWidget {
  const _RecurringPaymentCard({
    required this.payment,
    required this.currencySymbol,
    required this.locale,
    required this.onTap,
    required this.onToggleActive,
  });

  final RecurringPayment payment;
  final String currencySymbol;
  final Locale locale;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;

  String _cycleLabel(RecurringCycle cycle) => switch (cycle) {
        RecurringCycle.daily => 'Diário',
        RecurringCycle.weekly => 'Semanal',
        RecurringCycle.biweekly => 'Quinzenal',
        RecurringCycle.monthly => 'Mensal',
        RecurringCycle.quarterly => 'Trimestral',
        RecurringCycle.yearly => 'Anual',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
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
              leading: const Icon(Icons.repeat),
              title: Text(
                payment.title,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                '${_cycleLabel(payment.cycle)} · '
                'Próximo: ${DateFormat('dd/MM/yyyy').format(payment.nextDueDate)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              trailing: Text(
                formatAmount(payment.amountCents, currencySymbol, locale),
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            SwitchListTile(
              dense: true,
              title: Text(
                payment.isActive ? 'Ativo' : 'Pausado',
                style: theme.textTheme.bodySmall,
              ),
              value: payment.isActive,
              onChanged: (_) => onToggleActive(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16),
            ),
          ],
        ),
      ),
    );
  }
}
