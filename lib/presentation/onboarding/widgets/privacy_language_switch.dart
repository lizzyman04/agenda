import 'package:agenda/application/shared/locale/locale_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Português / English switch at the top of the first-launch privacy
/// statement (D-12, D-11). A change calls [LocaleCubit.setLocale], which
/// re-renders the statement in the chosen language instantly.
///
/// The labels are endonyms and stay the same in both locales, so they are
/// constants here rather than ARB strings: `languageNamePtBr` reads
/// "Português (Brasil)", which the UI-SPEC segment label does not use.
class PrivacyLanguageSwitch extends StatelessWidget {
  const PrivacyLanguageSwitch({super.key});

  static const String _portugueseLabel = 'Português';
  static const String _englishLabel = 'English';

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleCubit>().state.locale;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: SegmentedButton<Locale>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: Locale('pt', 'BR'),
              label: Text(_portugueseLabel),
            ),
            ButtonSegment(value: Locale('en'), label: Text(_englishLabel)),
          ],
          selected: {locale},
          onSelectionChanged: (selection) =>
              context.read<LocaleCubit>().setLocale(selection.first),
        ),
      ),
    );
  }
}
