import 'package:agenda/domain/notifications/model/notification_prefs.dart';

/// Persistence for [NotificationPrefs] (NOTF-09, NOTF-10).
///
/// Implementations live in `lib/infrastructure/notifications/prefs/`.
abstract interface class NotificationPrefsRepository {
  /// Reads the stored preferences, filling absent values with the
  /// defaults. Synchronous because the store is already in memory.
  NotificationPrefs load();

  /// Persists [prefs], then emits it on [watch] (persist before emit).
  Future<void> save(NotificationPrefs prefs);

  /// Broadcast stream of saved preferences. Emits after each [save]; never
  /// replays the current value.
  Stream<NotificationPrefs> watch();
}
