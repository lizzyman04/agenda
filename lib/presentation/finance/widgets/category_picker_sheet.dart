import 'package:agenda/domain/finance/category/transaction_category.dart';
import 'package:flutter/material.dart';

/// Bottom-sheet content for picking a [TransactionCategory] from an
/// already-loaded list.
///
/// Deduplicates the near-identical `_pickCategory()` bottom sheet previously
/// re-declared in `transaction_form_screen.dart` and
/// `recurring_payment_form_screen.dart`.
///
/// Pure display widget: it does not fetch categories, does not own a cubit,
/// and never mutates caller state. It resolves its result exclusively via
/// `Navigator.pop` — the caller `await`s the pushed sheet and applies the
/// result itself. This mirrors the controller-ownership rule documented in
/// `presentation/finance/goals/README.md`: sheets own their own state and
/// hand results back through the navigator, they never reach back into the
/// caller.
///
/// Usage:
/// ```dart
/// final picked = await showModalBottomSheet<TransactionCategory>(
///   context: context,
///   isScrollControlled: true,
///   useSafeArea: true,
///   shape: const RoundedRectangleBorder(
///     borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
///   ),
///   builder: (ctx) => CategoryPickerSheet(
///     categories: categories,
///     selectedCategoryId: selectedCategory?.id,
///     locale: Localizations.localeOf(context),
///   ),
/// );
/// ```
class CategoryPickerSheet extends StatelessWidget {
  const CategoryPickerSheet({
    required this.categories,
    required this.selectedCategoryId,
    required this.locale,
    super.key,
  });

  /// The already-loaded list of categories to display. This widget does not
  /// fetch categories itself.
  final List<TransactionCategory> categories;

  /// Id of the currently-selected category, used to render the trailing
  /// check icon. `null` if no category is selected yet.
  final int? selectedCategoryId;

  /// Locale used to resolve `nameEn`/`namePtBr` on each category.
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                final name = locale.languageCode == 'en' && cat.nameEn != null
                    ? cat.nameEn!
                    : cat.namePtBr;
                return ListTile(
                  title: Text(name),
                  trailing: selectedCategoryId == cat.id
                      ? Icon(Icons.check,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(cat),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
