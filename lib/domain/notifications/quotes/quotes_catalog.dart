import 'package:agenda/domain/notifications/quotes/quotes_en.dart';
import 'package:agenda/domain/notifications/quotes/quotes_pt.dart';

/// The bundled quote list for [localeCode]: English for `'en'`, Brazilian
/// Portuguese for any other code (the app default).
List<String> quotesFor(String localeCode) =>
    localeCode == 'en' ? quotesEn : quotesPt;
