import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:agenda/presentation/onboarding/widgets/privacy_bullet.dart';
import 'package:flutter/material.dart';

/// The one-screen privacy statement (UX-03, D-12, D-13).
///
/// First launch (`readOnly` false): the root screen until "Começar" is
/// tapped; [onGetStarted] persists the shown flag and the gate then swaps
/// in the shell.
class PrivacyStatementScreen extends StatelessWidget {
  const PrivacyStatementScreen({
    this.readOnly = false,
    this.onGetStarted,
    super.key,
  });

  /// True when opened from Settings > About (D-14).
  final bool readOnly;

  /// Called by the "Começar" button; the button is disabled while it runs.
  final Future<void> Function()? onGetStarted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _StatementContent(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: _GetStartedButton(
                label: l10n.privacyGetStarted,
                onPressed: onGetStarted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Content items 2-10 of the UI-SPEC column, shared by both modes.
class _StatementContent extends StatelessWidget {
  const _StatementContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bullets = [
      (Icons.wifi_off_outlined, l10n.privacyBulletOffline),
      (Icons.visibility_off_outlined, l10n.privacyBulletNoTracking),
      (Icons.cloud_off_outlined, l10n.privacyBulletBackup),
      (Icons.lock_outline, l10n.privacyBulletPin),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        Icon(Icons.shield_outlined, size: 64, color: cs.primary),
        const SizedBox(height: 24),
        Text(l10n.privacyStatement, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          l10n.privacyIntro,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        for (var i = 0; i < bullets.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          PrivacyBullet(icon: bullets[i].$1, text: bullets[i].$2),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Full-width "Começar" button, disabled while [onPressed] runs so the
/// flag is never written twice.
class _GetStartedButton extends StatefulWidget {
  const _GetStartedButton({required this.label, required this.onPressed});

  final String label;
  final Future<void> Function()? onPressed;

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> {
  bool _busy = false;

  Future<void> _press() async {
    setState(() => _busy = true);
    try {
      await widget.onPressed?.call();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: _busy || widget.onPressed == null ? null : _press,
      child: Text(widget.label),
    );
  }
}
