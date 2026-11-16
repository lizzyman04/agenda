import 'dart:async';

import 'package:agenda/application/shared/locale/locale_cubit.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The endonym for [locale]; identical in both UI languages.
String _languageName(AppLocalizations l10n, Locale locale) =>
    locale.languageCode == 'en' ? l10n.languageNameEn : l10n.languageNamePtBr;

/// Settings > General > Idioma (D-11, UX-01).
///
/// The subtitle shows the current language; tapping opens the dialog.
class LanguageTile extends StatelessWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = context.watch<LocaleCubit>().state.locale;
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.languageLabel),
      subtitle: Text(_languageName(l10n, locale)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => unawaited(showLanguageDialog(context)),
    );
  }
}

/// Shows exactly two options, PT-BR and English, with no system option
/// (D-11). Selecting one applies it at once and closes the dialog; there is
/// no confirm button.
Future<void> showLanguageDialog(BuildContext context) {
  final cubit = context.read<LocaleCubit>();
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext);
      void select(Locale? locale) {
        if (locale == null) return;
        unawaited(cubit.setLocale(locale));
        Navigator.of(dialogContext).pop();
      }

      return AlertDialog(
        title: Text(l10n.settingsLanguageDialogTitle),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        content: SingleChildScrollView(
          child: RadioGroup<Locale>(
            groupValue: cubit.state.locale,
            onChanged: select,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final locale in LocaleCubit.supportedLocales)
                  RadioListTile<Locale>(
                    value: locale,
                    title: Text(_languageName(l10n, locale)),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancelButton),
          ),
        ],
      );
    },
  );
}
