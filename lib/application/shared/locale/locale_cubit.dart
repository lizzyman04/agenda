import 'package:agenda/application/shared/locale/locale_state.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the active [Locale] and persists it to [SharedPreferences].
///
/// On construction, reads the stored locale from [SharedPreferences].
/// Defaults to [Locale('pt', 'BR')] (PT-BR) when no preference is stored
/// (D-21).
///
/// Consumed by AgendaApp to drive MaterialApp.locale.
@injectable
class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit(this._prefs)
      : super(
          LocaleState(
            _resolveInitialLocale(_prefs),
          ),
        );

  final SharedPreferences _prefs;

  /// Supported locales — must match l10n.yaml preferred-supported-locales.
  static const List<Locale> supportedLocales = [
    Locale('pt', 'BR'),
    Locale('en'),
  ];

  /// Default locale is PT-BR (D-21).
  static const Locale defaultLocale = Locale('pt', 'BR');

  static Locale _resolveInitialLocale(SharedPreferences prefs) {
    final stored = prefs.getString(StorageKeys.locale);
    if (stored == null) return defaultLocale;
    // Stored as IETF tag: 'pt' for PT-BR, 'en' for English.
    return stored == 'en' ? const Locale('en') : const Locale('pt', 'BR');
  }

  /// Switches the active locale and persists the choice.
  ///
  /// [locale] must be one of [supportedLocales] — no-op otherwise.
  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;
    await _prefs.setString(StorageKeys.locale, locale.languageCode);
    emit(LocaleState(locale));
  }
}
