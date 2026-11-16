import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Full-bleed cover painted while the app is not in the foreground with a
/// PIN enabled, so the app switcher snapshot shows no tasks or finances
/// (D-04, UI-SPEC "Privacy overlay").
///
/// No motion: it appears and disappears in the same frame.
class PrivacyOverlay extends StatelessWidget {
  const PrivacyOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // Above the app Navigator there is no Material; the transparent one
    // gives the text the theme's default style.
    return ColoredBox(
      color: cs.surface,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 64, color: cs.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).appName,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
