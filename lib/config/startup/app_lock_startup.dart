import 'package:agenda/config/di/injection.dart';
import 'package:agenda/core/constants/storage_keys.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prepares app-lock storage during `main()` (DATA-05).
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
Future<void> startAppLock() async {
  try {
    final prefs = getIt<SharedPreferences>();
    if (prefs.getBool(StorageKeys.secureStorageInitialized) ?? false) return;
    if (!(prefs.getBool(StorageKeys.pinConfigured) ?? false)) {
      await getIt<FlutterSecureStorage>().deleteAll();
    }
    await prefs.setBool(StorageKeys.secureStorageInitialized, true);
  } on Object {
    // Intentionally ignored: launch must never wait on secure storage.
  }
}
