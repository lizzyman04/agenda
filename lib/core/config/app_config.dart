/// Compile-time application constants.
///
/// Access directly: `AppConfig.schemaVersion` — no DI registration needed.
abstract final class AppConfig {
  /// Application display name.
  static const String appName = 'AGENDA';

  /// Reverse-DNS package identifier.
  static const String packageName = 'com.omeu.space.agenda';

  /// Human-readable version string shown in Settings.
  static const String version = '1.0.0';

  /// Build number for platform stores.
  static const int buildNumber = 1;

  /// Current Isar schema version.
  ///
  /// Bump this constant AND add a corresponding migration block in
  /// MigrationRunner._runMigration every time the Isar schema changes.
  static const int schemaVersion = 1;

  // ---------------------------------------------------------------------------
  // Notification ID namespaces
  // Deterministic derivation: entityId * 10 + notificationType
  // Defined here in Phase 1 so Phase 4 can reference without circular dep.
  // ---------------------------------------------------------------------------

  /// Base multiplier for task notification IDs.
  static const int taskNotificationBase = 10;

  /// Base multiplier for finance notification IDs.
  static const int financeNotificationBase = 20;

  /// Base multiplier for system notification IDs (briefing, motivational).
  static const int systemNotificationBase = 30;
}
