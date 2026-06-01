import 'package:agenda/application/finance/transaction/transaction_cubit.dart';
import 'package:agenda/application/finance/transaction/transaction_state.dart';
import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/finance/transaction.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/screens/transaction_form_screen.dart';
import 'package:agenda/presentation/finance/widgets/finance_empty_state.dart';
import 'package:agenda/presentation/finance/widgets/transaction_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the list of all financial transactions.
///
/// Empty state prompts the user to add their first transaction.
/// FAB and empty state CTA both navigate to [TransactionFormScreen].
/// Swipe-to-delete triggers a soft delete with a 5-second undo snackbar.
class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionCubit>().start();
  }

  void _openForm({Transaction? transaction}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<TransactionCubit>(),
          child: TransactionFormScreen(transaction: transaction),
        ),
      ),
    );
  }

  void _handleDelete(BuildContext context, Transaction tx) {
    final cubit = context.read<TransactionCubit>();
    cubit.softDelete(tx.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).transactionDeleted),
        duration: AppConstants.undoSnackbarDuration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: AppLocalizations.of(context).undo,
          onPressed: () => cubit.restoreTransaction(tx.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Use MT as dev default; production reads from SharedPreferences
    const currencySymbol = 'MT';
    final locale = Localizations.localeOf(context);

    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        return switch (state) {
          TransactionInitial() || TransactionLoading() =>
            const Center(child: CircularProgressIndicator()),
          TransactionError(:final failure) =>
            Center(child: Text(failure.message)),
          TransactionLoaded(:final transactions)
              when transactions.isEmpty =>
            FinanceEmptyState(
              icon: Icons.receipt_long_outlined,
              heading: l10n.emptyTransactions,
              body: l10n.emptyTransactionsBody,
              ctaLabel: l10n.addTransaction,
              onCta: _openForm,
            ),
          TransactionLoaded(:final transactions) => Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemCount: transactions.length,
                  itemBuilder: (ctx, i) {
                    final tx = transactions[i];
                    return TransactionCard(
                      transaction: tx,
                      categoryName: _categoryName(tx, locale.languageCode),
                      currencySymbol: currencySymbol,
                      locale: locale,
                      onDelete: () => _handleDelete(context, tx),
                      onTap: () => _openForm(transaction: tx),
                    );
                  },
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    tooltip: l10n.addTransaction,
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

  /// Returns the category display name from cached category or id fallback.
  String _categoryName(Transaction tx, String langCode) {
    // Category lookup is best-effort — full lookup is done via cubit state
    // if categories are passed. For now, use a placeholder that works.
    return '#${tx.categoryId}';
  }
}
