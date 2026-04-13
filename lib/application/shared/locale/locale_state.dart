import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// State for LocaleCubit — holds the currently active [Locale].
final class LocaleState extends Equatable {
  const LocaleState(this.locale);

  /// The currently active locale.
  final Locale locale;

  @override
  List<Object?> get props => [locale];
}
