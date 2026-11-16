# API Coverage — local_auth 3.0.1 and flutter_secure_storage 10.0.0

> Full coverage by default. Opt-outs are explicit, reasoned decisions.
> Both are on-device platform plugins (no network). Plans 05-01 (API smoke), 05-03 (secure storage), 05-11 and 05-12 (local_auth).

| capability | decision | reason |
|---|---|---|
| local_auth.authenticate.biometricOnly | INTEGRATE | |
| local_auth.authenticate.deviceCredential | INTEGRATE | |
| local_auth.authenticate.sensitiveTransaction | INTEGRATE | |
| local_auth.authenticate.authMessages.android | INTEGRATE | |
| local_auth.canCheckBiometrics | INTEGRATE | |
| local_auth.getAvailableBiometrics | INTEGRATE | |
| local_auth.isDeviceSupported | INTEGRATE | |
| local_auth.LocalAuthException.codes | INTEGRATE | |
| local_auth.authenticate.persistAcrossBackgrounding | OPT-OUT | not needed: an interrupted prompt is dropped and the lock screen re-prompts on demand (set false explicitly) |
| local_auth.stopAuthentication | OPT-OUT | not needed: prompts are modal and end on their own; nothing in the lock flow cancels one programmatically |
| local_auth.authenticate.authMessages.ios | OPT-OUT | not needed yet: localizedReason is the visible iOS text and the default IOSAuthMessages suffice; iOS is code-only on this host (user decision 4) |
| local_auth.authenticate.authMessages.windows | OPT-OUT | explicitly out of scope: mobile only (CLAUDE.md platform constraint) |
| flutter_secure_storage.write | INTEGRATE | |
| flutter_secure_storage.read | INTEGRATE | |
| flutter_secure_storage.delete | INTEGRATE | |
| flutter_secure_storage.deleteAll | INTEGRATE | |
| flutter_secure_storage.AndroidOptions | INTEGRATE | |
| flutter_secure_storage.IOSOptions.accessibility | INTEGRATE | |
| flutter_secure_storage.readAll | OPT-OUT | not needed: the two key names are fixed (SecureStorageKeys) |
| flutter_secure_storage.containsKey | OPT-OUT | not needed: read returning null already distinguishes an absent key |
| flutter_secure_storage.protectedDataListeners | OPT-OUT | not needed: first_unlock_this_device keeps the record readable after the first unlock since boot |
| flutter_secure_storage.IOSOptions.synchronizable | OPT-OUT | explicitly out of scope: privacy-first, no data may leave the device (no iCloud Keychain sync) |
| flutter_secure_storage.desktopAndWebOptions | OPT-OUT | explicitly out of scope: mobile only (CLAUDE.md platform constraint) |
