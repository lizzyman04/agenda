/// flutter_secure_storage key strings (Keychain on iOS, Keystore-backed
/// storage on Android).
///
/// Only PIN material and attempt state live here (D-05). Non-secret flags
/// stay in SharedPreferences under `StorageKeys`.
abstract final class SecureStorageKeys {
  /// The versioned PIN record, `v1:<iterations>:<salt>:<hash>` (D-05).
  static const String pinRecord = 'pin_record';

  /// Failed-attempt state, `<failures>:<lockouts>:<cooldownUntil ms UTC>`,
  /// persisted so killing the app cannot reset it (D-07).
  static const String pinAttempts = 'pin_attempts';
}
