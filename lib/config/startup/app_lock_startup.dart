import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:agenda/domain/lock/secure_window_gateway.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prepares app-lock storage and the native window shield during `main()`,
/// before `runApp` (DATA-05, D-04).
///
/// On iOS the Keychain survives an uninstall while SharedPreferences does
/// not (RESEARCH Pitfall 4), so a reinstall could inherit an old PIN record
/// or a running cooldown. The first launch of a fresh install, recognised by
/// the absence of both [StorageKeys.secureStorageInitialized] and
/// [StorageKeys.pinConfigured], therefore deletes every secure entry before
/// setting the marker (T-05-10).
///
/// When the marker is absent but a PIN is already configured (an earlier
/// wipe failed and a PIN was created since), nothing is wiped; only the
/// marker is set. A Keystore or Keychain fault never blocks launch: it is
/// swallowed, the marker stays unset and the wipe retries next launch.
///
/// Whenever a PIN is configured, every process start also turns on the
/// native shield through [SecureWindowGateway] (FLAG_SECURE on Android, the
/// App Switcher cover on iOS), so the window is secure from the first frame
/// (T-05-29). With no PIN configured the shield is never set. A channel
/// fault never blocks launch either.
Future<void> startAppLock() async {
  try {
    final prefs = getIt<SharedPreferences>();
    final pinConfigured = prefs.getBool(StorageKeys.pinConfigured) ?? false;
    await _wipeOnFreshInstall(prefs, pinConfigured: pinConfigured);
    if (pinConfigured) {
      await getIt<SecureWindowGateway>().setSecure(enabled: true);
    }
  } on Object {
    // Intentionally ignored: launch must never wait on secure storage or
    // the platform channel.
  }
}

Future<void> _wipeOnFreshInstall(
  SharedPreferences prefs, {
  required bool pinConfigured,
}) async {
  try {
    if (prefs.getBool(StorageKeys.secureStorageInitialized) ?? false) return;
    if (!pinConfigured) await getIt<FlutterSecureStorage>().deleteAll();
    await prefs.setBool(StorageKeys.secureStorageInitialized, true);
  } on Object {
    // Swallowed: the marker stays unset and the wipe retries next launch.
    // A wipe fault must not keep the shield off when a PIN is configured.
  }
}
