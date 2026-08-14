import 'package:agenda/application/finance/recurring/recurring_payment_cubit.dart';
import 'package:agenda/application/finance/recurring/recurring_payment_state.dart';
import 'package:agenda/domain/finance/recurring/recurring_payment.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/screens/recurring_payment_form_screen.dart';
import 'package:agenda/presentation/finance/widgets/finance_empty_state.dart';
import 'package:agenda/presentation/finance/widgets/recurring/recurring_payment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the list of recurring payments, paused ones included.
///
/// Each payment shows title, amount, cycle, next due date, and an isActive
/// SwitchListTile. FAB navigates to [RecurringPaymentFormScreen].
///
/// Paused payments are listed here rather than hidden because this screen
/// renders the only control that can resume one (CR-02).
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
    // RecurringPaymentCubit is provided above MaterialApp; route inherits it.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecurringPaymentFormScreen(payment: payment),
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
                    return RecurringPaymentCard(
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
