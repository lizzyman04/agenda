import 'package:agenda/application/finance/transaction/transaction_cubit.dart';
import 'package:agenda/application/finance/transaction/transaction_state.dart';
import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:agenda/domain/finance/transaction/transaction.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/screens/transaction_form_screen.dart';
import 'package:agenda/presentation/finance/transaction_form_logic.dart';
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
    // TransactionCubit is provided above MaterialApp, so the pushed route
    // inherits it directly — no per-route BlocProvider.value needed.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionFormScreen(transaction: transaction),
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
        // persist defaults to `action != null` since Flutter 3.38, which
        // suppresses auto-dismiss entirely. The undo window must expire on
        // its own, so opt back out explicitly.
        persist: false,
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
          TransactionLoaded(:final transactions, :final categories) =>
            _buildList(context, transactions, categories, locale, l10n),
        };
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Transaction> transactions,
    List<TransactionCategory> categories,
    Locale locale,
    AppLocalizations l10n,
  ) {
    // Use MT as dev default; production reads from SharedPreferences
    const currencySymbol = 'MT';
    // Built once per state, not once per itemBuilder call.
    final categoryById = {for (final c in categories) c.id: c};
    final preferEnglish = locale.languageCode == 'en';

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 88),
          itemCount: transactions.length,
          itemBuilder: (ctx, i) {
            final tx = transactions[i];
            return TransactionCard(
              transaction: tx,
              // '#<id>' is the genuine no-such-category fallback — the same
              // one spending_pie_chart.dart and spending_bar_chart.dart use
              // for an orphaned categoryId. It is not the removed stub.
              categoryName: resolveCategoryDisplay(
                categoryById[tx.categoryId],
                preferEnglish: preferEnglish,
                fallback: '#${tx.categoryId}',
              ),
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
    );
  }
}
