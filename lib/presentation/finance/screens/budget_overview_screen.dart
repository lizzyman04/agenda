import 'package:agenda/application/finance/budget/budget_cubit.dart';
import 'package:agenda/application/finance/budget/budget_state.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/finance/widgets/budget_progress_bar.dart';
import 'package:agenda/presentation/finance/widgets/finance_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    // The sheet owns its own TextEditingController (see _BudgetLimitSheet) and
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
      builder: (_) => _BudgetLimitSheet(
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

/// Bottom-sheet body for setting a category budget limit.
///
/// Owns its own [TextEditingController] so the controller is disposed by the
/// framework in the correct order (after the TextField unmounts). Disposing a
/// controller created in the caller's method scope — right after the sheet's
/// `await` returned — caused a "TextEditingController used after being
/// disposed" error during the dismiss transition, which cascaded into the
/// `InheritedElement._dependents.isEmpty` assertion on the overlay.
///
/// Returns the parsed limit (in cents) via `Navigator.pop`, or `null` when the
/// input is empty/invalid.
class _BudgetLimitSheet extends StatefulWidget {
  const _BudgetLimitSheet({
    required this.categoryName,
    required this.existingLimitCents,
  });

  final String categoryName;
  final int existingLimitCents;

  @override
  State<_BudgetLimitSheet> createState() => _BudgetLimitSheetState();
}

class _BudgetLimitSheetState extends State<_BudgetLimitSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.existingLimitCents > 0
          ? (widget.existingLimitCents / 100)
              .toStringAsFixed(2)
              .replaceAll('.', ',')
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^\d.]'), '');
    final parsed = double.tryParse(raw);
    final limitCents =
        (parsed != null && parsed > 0) ? (parsed * 100).round() : null;
    Navigator.of(context).pop(limitCents);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.categoryName, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
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
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            child: Text(l10n.setBudgetLimit),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
