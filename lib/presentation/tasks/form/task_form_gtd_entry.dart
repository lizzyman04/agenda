import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/tasks/form/gtd/gtd_models.dart';
import 'package:agenda/presentation/tasks/form/gtd/screens/gtd_guide_sheet.dart';
import 'package:flutter/material.dart';

/// Presents the GTD guide sheet and returns the user's answers, or `null` if
/// the sheet was dismissed.
///
/// Extracted from `TaskFormScreen._openGtdGuide` so the screen widget can stay
/// under the architecture line-count limit. Returns the raw [GtdResult] rather
/// than applying it — the screen still owns its controllers and model, per the
/// pop-not-mutate convention in this slice's README.
Future<GtdResult?> showGtdGuide(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<GtdResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => GtdGuideSheet(l10n: l10n),
  );
}
