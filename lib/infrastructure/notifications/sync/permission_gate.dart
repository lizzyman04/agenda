import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/domain/notifications/notification_permission_service.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks for the notification permission at most once, in context.
///
/// The prompt is never raised at launch (Pitfall 10): the reconcile runner
/// calls [ensureAsked] only when a data or preference change is about to
/// schedule something. The system dialog result is not needed here; the
/// settings page reads the current permission.
@lazySingleton
class PermissionGate {
  PermissionGate(this._permissions, this._store);

  final NotificationPermissionService _permissions;
  final SharedPreferences _store;

  /// Whether the prompt was already raised.
  bool get asked => _store.getBool(StorageKeys.notifPermissionAsked) ?? false;

  /// Requests the permission unless it was requested before.
  ///
  /// The flag is persisted first, so a crash mid-prompt cannot cause a
  /// second prompt.
  Future<void> ensureAsked() async {
    if (asked) return;
    await _store.setBool(StorageKeys.notifPermissionAsked, true);
    await _permissions.requestNotificationPermission();
  }
}
