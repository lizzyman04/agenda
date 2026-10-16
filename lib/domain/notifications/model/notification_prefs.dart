import 'package:agenda/core/constants/app_constants.dart';
import 'package:agenda/domain/notifications/model/notification_kind.dart';
import 'package:agenda/domain/notifications/model/quote_frequency.dart';
import 'package:equatable/equatable.dart';

/// The user's notification preferences (NOTF-09, NOTF-10).
final class NotificationPrefs extends Equatable {
  const NotificationPrefs({
    required this.enabled,
    required this.quietHoursEnabled,
    required this.quietStartMinutes,
    required this.quietEndMinutes,
    required this.briefingMinutes,
    required this.quoteFrequency,
    required this.quoteMinutes,
    required this.quoteSeed,
  });

  /// Defaults: every kind on except quotes, quiet hours 22:00-07:00.
  factory NotificationPrefs.defaults() => const NotificationPrefs(
    enabled: {NotificationKind.motivationalQuote: false},
    quietHoursEnabled: true,
    quietStartMinutes: AppConstants.quietHoursStartHour * 60,
    quietEndMinutes: AppConstants.quietHoursEndHour * 60,
    briefingMinutes: AppConstants.defaultBriefingMinutes,
    quoteFrequency: QuoteFrequency.daily,
    quoteMinutes: AppConstants.defaultQuoteMinutes,
    quoteSeed: 0,
  );

  /// Per-kind toggles. An absent entry means the kind default.
  final Map<NotificationKind, bool> enabled;
  final bool quietHoursEnabled;
  final int quietStartMinutes;
  final int quietEndMinutes;
  final int briefingMinutes;
  final QuoteFrequency quoteFrequency;
  final int quoteMinutes;

  /// Makes the quote shuffle deterministic.
  final int quoteSeed;

  /// Absent entries are on, except quotes which are opt-in (D-07).
  bool isEnabled(NotificationKind kind) =>
      enabled[kind] ?? kind != NotificationKind.motivationalQuote;

  NotificationPrefs copyWith({
    Map<NotificationKind, bool>? enabled,
    bool? quietHoursEnabled,
    int? quietStartMinutes,
    int? quietEndMinutes,
    int? briefingMinutes,
    QuoteFrequency? quoteFrequency,
    int? quoteMinutes,
    int? quoteSeed,
  }) => NotificationPrefs(
    enabled: Map.unmodifiable(enabled ?? this.enabled),
    quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    quietStartMinutes: quietStartMinutes ?? this.quietStartMinutes,
    quietEndMinutes: quietEndMinutes ?? this.quietEndMinutes,
    briefingMinutes: briefingMinutes ?? this.briefingMinutes,
    quoteFrequency: quoteFrequency ?? this.quoteFrequency,
    quoteMinutes: quoteMinutes ?? this.quoteMinutes,
    quoteSeed: quoteSeed ?? this.quoteSeed,
  );

  /// A copy with one kind switched on or off.
  NotificationPrefs withEnabled(
    NotificationKind kind, {
    required bool value,
  }) => copyWith(enabled: {...enabled, kind: value});

  @override
  List<Object?> get props => [
    for (final kind in NotificationKind.values) isEnabled(kind),
    quietHoursEnabled,
    quietStartMinutes,
    quietEndMinutes,
    briefingMinutes,
    quoteFrequency,
    quoteMinutes,
    quoteSeed,
  ];
}
