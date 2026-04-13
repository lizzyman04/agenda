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

  /// Quiet hours start hour 0-23 (NOTF-10).
  static const String quietHoursStart = 'quiet_hours_start';

  /// Quiet hours end hour 0-23 (NOTF-10).
  static const String quietHoursEnd = 'quiet_hours_end';
}
