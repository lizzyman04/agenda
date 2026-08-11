import 'package:agenda/application/finance/budget/budget_cubit.dart';
import 'package:agenda/application/finance/budget/budget_state.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/widgets/budget/budget_limit_sheet.dart';
import 'package:agenda/presentation/finance/widgets/budget_progress_bar.dart';
import 'package:agenda/presentation/finance/widgets/finance_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays budget progress for all expense categories.
///
/// Each category row shows a [BudgetProgressBar]. Tapping a row opens a
/// BottomSheet to set or update the monthly limit for that category.
class BudgetOverviewScreen extends StatefulWidget {
  const BudgetOverviewScreen({super.key});

  @override
  State<BudgetOverviewScreen> createState() => _BudgetOverviewScreenState();
}

class _BudgetOverviewScreenState extends State<BudgetOverviewScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BudgetCubit>().start();
  }

  Future<void> _openLimitSheet(
    BuildContext context,
    int categoryId,
    String categoryName,
    int existingLimitCents,
  ) async {
    final cubit = context.read<BudgetCubit>();

    // The sheet owns its own TextEditingController (see BudgetLimitSheet) and
    // returns the parsed limit via Navigator.pop. We apply the mutation only
    // after the sheet has fully closed, so no emit interleaves with teardown
    // and no controller is touched after disposal.
    final limitCents = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BudgetLimitSheet(
        categoryName: categoryName,
        existingLimitCents: existingLimitCents,
      ),
    );

    if (limitCents != null) {
      final now = DateTime.now();
      await cubit.setLimit(categoryId, now.month, now.year, limitCents);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const currencySymbol = 'MT';
    final locale = Localizations.localeOf(context);

    return BlocBuilder<BudgetCubit, BudgetState>(
      builder: (context, state) {
        return switch (state) {
          BudgetInitial() || BudgetLoading() =>
            const Center(child: CircularProgressIndicator()),
          BudgetError(:final failure) =>
            Center(child: Text(failure.message)),
          BudgetLoaded(: final categories)
              when categories.isEmpty =>
            FinanceEmptyState(
              icon: Icons.donut_large_outlined,
              heading: l10n.emptyBudgets,
              body: l10n.emptyBudgetsBody,
              ctaLabel: l10n.setBudgetLimit,
              onCta: () {}, // No categories yet — inform user
            ),
          BudgetLoaded(:final budgets, :final categories) => ListView.builder(
              padding:
                  const EdgeInsets.symmetric(vertical: 8),
              itemCount: categories.length,
              itemBuilder: (ctx, i) {
                final cat = categories[i];
                final langCode = locale.languageCode;
                final catName =
                    langCode == 'en' && cat.nameEn != null
                        ? cat.nameEn!
                        : cat.namePtBr;
                final budgetData =
                    budgets[cat.id] ?? (limitCents: 0, spentCents: 0);

                return Card(
                  elevation: 0,
                  color: Theme.of(ctx).colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openLimitSheet(
                      context,
                      cat.id,
                      catName,
                      budgetData.limitCents,
                    ),
                    child: BudgetProgressBar(
                      categoryName: catName,
                      spentCents: budgetData.spentCents,
                      limitCents: budgetData.limitCents,
                      currencySymbol: currencySymbol,
                      locale: locale,
                      noLimitLabel: l10n.noLimitSet,
                    ),
                  ),
                );
              },
            ),
        };
      },
    );
  }
}
