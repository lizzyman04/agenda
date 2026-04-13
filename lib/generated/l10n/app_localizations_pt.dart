// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'AGENDA';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get privacyStatement => 'Os seus dados nunca saem deste dispositivo.';

  @override
  String get emptyStateTitle => 'Nenhum item ainda';

  @override
  String get emptyStateAction => 'Toque para adicionar';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appName => 'AGENDA';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get privacyStatement => 'Os seus dados nunca saem deste dispositivo.';

  @override
  String get emptyStateTitle => 'Nenhum item ainda';

  @override
  String get emptyStateAction => 'Toque para adicionar';
}
