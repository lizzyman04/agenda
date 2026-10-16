/// SharedPreferences key strings.
///
/// Centralised here so typos in key names are caught at compile time.
abstract final class StorageKeys {
  /// Isar schema version integer — read by MigrationRunner before Isar opens.
  static const String schemaVersion = 'schema_version';

  /// IETF language tag of the active locale ('en' or 'pt').
  /// Written by LocaleCubit; read on cold start before runApp.
  static const String locale = 'locale';

  /// Whether the first-launch privacy statement has been shown (UX-03).
  static const String privacyStatementShown = 'privacy_statement_shown';

  /// Whether app lock PIN is configured (DATA-05).
  static const String pinConfigured = 'pin_configured';

  /// App lock timeout in seconds (0 = lock immediately on background).
  static const String lockTimeoutSeconds = 'lock_timeout_seconds';

  /// Quiet hours enabled flag (NOTF-10).
  static const String quietHoursEnabled = 'quiet_hours_enabled';

  /// Quiet hours start, minutes since midnight 0-1439 (NOTF-10, D-08).
  static const String quietHoursStart = 'quiet_hours_start';

  /// Quiet hours end, minutes since midnight 0-1439 (NOTF-10, D-08).
  static const String quietHoursEnd = 'quiet_hours_end';

  /// Prefix of the per-kind enabled flags (NOTF-09).
  ///
  /// The full key is this prefix plus the kind's two-letter code, for
  /// example `notif_enabled_tk`.
  static const String notifEnabledPrefix = 'notif_enabled_';

  /// Morning briefing time, minutes since midnight 0-1439 (D-03).
  static const String notifBriefingMinutes = 'notif_briefing_minutes';

  /// Quote frequency name, 'daily' or 'weekly' (D-07).
  static const String notifQuoteFrequency = 'notif_quote_frequency';

  /// Quote time, minutes since midnight 0-1439 (D-07).
  static const String notifQuoteMinutes = 'notif_quote_minutes';

  /// Positive random seed that keeps the quote order stable (D-07).
  static const String notifQuoteSeed = 'notif_quote_seed';

  /// Whether the notification permission prompt was already shown.
  static const String notifPermissionAsked = 'notif_permission_asked';

  /// De-duplicated list of fired alert keys, such as goal-week markers
  /// (string list).
  static const String notifAlertState = 'notif_alert_state';
}
