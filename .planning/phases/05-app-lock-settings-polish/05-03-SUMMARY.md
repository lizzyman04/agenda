---
phase: 05-app-lock-settings-polish
plan: 03
subsystem: security
tags: [app-lock, pin, pbkdf2, crypto, flutter_secure_storage, get_it, injectable, mocktail]

requires:
  - phase: 05-01
    provides: "crypto 3.0.7 and flutter_secure_storage 10.0.0 pinned; confirmed API names table"
  - phase: 05-02
    provides: "LockAttempts (D-07 ladder: registerFailure, remainingBeforeCooldown, isCoolingDown)"
provides:
  - "PinRecord (versioned v1 record), PinHasher + isValidPin + pinLength, PinStore domain contracts"
  - "Pbkdf2PinHasher (PBKDF2-HMAC-SHA256, 16-byte Random.secure salt, 10000 rounds, Isolate.run, constant-time compare)"
  - "SecurePinStore over flutter_secure_storage (record + attempts)"
  - "PinVerifier and the four PinVerifyOutcome variants; persists attempts before answering, fails closed"
  - "InfrastructureModule.secureStorage (FlutterSecureStorage singleton)"
  - "startAppLock(): fresh-install secure-storage wipe, called from main before runApp"
  - "StorageKeys.biometricUnlockEnabled, StorageKeys.secureStorageInitialized, SecureStorageKeys"
  - "Test support: FakeClock, MockPinHasher, MockPinStore, fakePinRecord, registerLockFallbacks; test/config/di/lock_di_test.dart"
affects: [05-04, 05-10, 05-11, 05-12, 05-14, app-lock, settings]

actuals:
  tokens: 9955
  tasks: 3
  commits: 4
plan_head_before: 0989654332d34ef1e8a3c345261f92d97ed691d5
plan_head_after: f07bc0695f43bd8210794251750ff119eb9d607e

tech-stack:
  added: []
  patterns:
    - "One versioned secure-storage record per secret (v1:<iterations>:<salt>:<hash>) so a write cannot tear salt from hash"
    - "Persist-then-answer: a counted failure is awaited into secure storage before the outcome is returned"
    - "Fail closed: any storage Err or missing/malformed record maps to PinCheckFailed"
    - "Startup functions swallow every fault so launch is never blocked (startAppLock mirrors startNotifications)"

key-files:
  created:
    - lib/domain/lock/pin_record.dart
    - lib/domain/lock/pin_hasher.dart
    - lib/domain/lock/pin_store.dart
    - lib/infrastructure/lock/pbkdf2_pin_hasher.dart
    - lib/infrastructure/lock/secure_pin_store.dart
    - lib/core/constants/secure_storage_keys.dart
    - lib/application/lock/pin_verifier.dart
    - lib/application/lock/README.md
    - lib/config/startup/app_lock_startup.dart
    - test/infrastructure/lock/pbkdf2_pin_hasher_test.dart
    - test/infrastructure/lock/secure_pin_store_test.dart
    - test/application/lock/pin_verifier_test.dart
    - test/config/di/lock_di_test.dart
    - test/config/startup/app_lock_startup_test.dart
    - test/support/fake_clock.dart
    - test/support/lock_fakes.dart
  modified:
    - lib/config/di/infrastructure_module.dart
    - lib/config/di/injection.config.dart
    - lib/core/constants/storage_keys.dart
    - lib/main.dart

key-decisions:
  - "One secure-storage key for the whole PIN record (v1:<iterations>:<base64 salt>:<base64 hash>) instead of separate salt/hash/iteration keys from PATTERNS.md: a single write cannot tear salt from hash, and the version tag keeps the format evolvable."
  - "Attempt state stored as '<failures>:<lockouts>:<cooldownUntil UTC ms>'; an absent key is LockAttempts.none, a malformed one is Err (fails closed via PinVerifier)."
  - "FlutterSecureStorage registered without an explicit aOptions argument: AndroidOptions() / AndroidOptions.defaultOptions is the default and the analyzer flags it as redundant; behaviour is identical (resetOnError true, handled by fail-closed)."
  - "PinRecord overrides Equatable stringify to false so toString never prints salt or hash."
  - "A failed reset write after a correct PIN still returns PinVerified (the PIN was proven); a failed attempt write after a wrong PIN returns PinCheckFailed."

patterns-established:
  - "test/support/lock_fakes.dart is the shared home for app-lock mocks; later plans append to it"
  - "test/config/di/lock_di_test.dart is the shared home for phase 5 DI checks"

requirements-completed: [DATA-05]

coverage:
  - id: D1
    description: "PIN stored only as a versioned PBKDF2-HMAC-SHA256 record (16-byte salt, 10000 rounds, 32-byte hash) in flutter_secure_storage; RFC 7914 and project vectors pinned; constant-time compare; hashing in Isolate.run"
    requirement: DATA-05
    verification:
      - kind: unit
        ref: "test/infrastructure/lock/pbkdf2_pin_hasher_test.dart"
        status: pass
      - kind: unit
        ref: "test/infrastructure/lock/secure_pin_store_test.dart#tracer: a PIN written through the store verifies through the hasher"
        status: pass
    human_judgment: false
  - id: D2
    description: "PinVerifier: wrong PIN persisted before answering, cooldown skips hashing/counting, any fault or missing record fails closed, invalid format never touches the store"
    requirement: DATA-05
    verification:
      - kind: unit
        ref: "test/application/lock/pin_verifier_test.dart"
        status: pass
    human_judgment: false
  - id: D3
    description: "Lock services resolve from GetIt as singletons (PinHasher, PinStore, PinVerifier, FlutterSecureStorage)"
    verification:
      - kind: integration
        ref: "test/config/di/lock_di_test.dart"
        status: pass
    human_judgment: false
  - id: D4
    description: "Fresh-install secure-storage wipe in main; never wipes a configured PIN; never throws or blocks launch"
    requirement: DATA-05
    verification:
      - kind: integration
        ref: "test/config/startup/app_lock_startup_test.dart"
        status: pass
    human_judgment: false
  - id: D5
    description: "iOS Keychain-survives-uninstall wipe and 10000-iteration unlock latency on the Infinix X6831"
    verification: []
    human_judgment: true
    rationale: "Real Keychain/Keystore behaviour across uninstall and on-device PBKDF2 latency (RESEARCH A2) can only be observed on a device; scheduled for 05-14 UAT."

duration: 17min
completed: 2026-11-16
status: complete
---

# Phase 5 Plan 03: PIN Security Core Summary

**PBKDF2-HMAC-SHA256 PIN records (16-byte secure salt, 10000 rounds, run in Isolate.run, constant-time compare) stored only in flutter_secure_storage. PinVerifier writes each counted failure to storage before it answers and fails closed on any storage fault. On the first launch of a fresh install, main wipes stale secure-storage entries.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-11-16T18:42:19Z
- **Completed:** 2026-11-16T18:59:44Z
- **Tasks:** 3
- **Files modified:** 20 (16 created, 4 modified)

## Accomplishments
- Tracer slice proven: a PIN written through the real `SecurePinStore` verifies through the real `Pbkdf2PinHasher`. The RFC 7914 `('passwd','salt',1)` vector and the project `('1234', 16 zero bytes, 10000)` vector are pinned.
- `PinVerifier` answers every attempt from persisted state. A Completer-based test proves the rejection future does not complete until `writeAttempts` has finished, so killing the app mid-verify cannot erase a counted failure (T-05-09).
- Fail closed everywhere: a missing or malformed record, an Err from an attempts read or write, or a malformed PIN yields `PinCheckFailed` and never `PinVerified` (T-05-12).
- `startAppLock()` runs in `main` before `runApp`. It deletes stale Keychain/Keystore entries on a fresh install. It never wipes once the marker is set or a PIN is configured, and it swallows every fault (T-05-10).
- DI: `FlutterSecureStorage` (iOS `first_unlock_this_device`), `PinHasher`, `PinStore` and `PinVerifier` all resolve as singletons. `injection.config.dart` was regenerated with build_runner.

## Task Commits

1. **Task 1: Tracer, SecurePinStore + Pbkdf2PinHasher**: `299a81a` (feat)
2. **Task 2: PinVerifier + DI**: RED `0515cc7` (test), GREEN `9d97214` (feat)
3. **Task 3: Fresh-install wipe + storage keys**: `f07bc06` (feat)

**Plan metadata:** recorded in the docs commit that adds this SUMMARY.

Tracer feedback gate: interactive run (`auto_advance: false`), `end-of-phase` mode, automated-only `<verify>`. Before expanding, re-ran `flutter test --no-pub test/infrastructure/lock/pbkdf2_pin_hasher_test.dart test/infrastructure/lock/secure_pin_store_test.dart && flutter analyze lib/domain/lock lib/infrastructure/lock lib/core/constants test/infrastructure/lock` (22/22 green, no issues).

### TDD (Task 2)

- **RED:** `pin_verifier_test.dart` (16 tests) was run against an uncommitted skeleton. The skeleton held the four outcome types and a `PinVerifier` whose `verify` always returned `PinCheckFailed`. 11 target tests failed on behaviour assertions, for example `Expected: PinRejected(4) Actual: PinCheckFailed()`, the ordering test's `Expected: false Actual: true`, and `resetAttempts`'s `No matching calls`. The 5 fail-closed tests passed, as expected against an always-fail-closed stub. **Semantic assessment:** the target tests ran and failed on the planned assertions, with no compile, load or fixture faults, so the RED is valid. Only the test files went into the RED commit. The machine classifier (`check tdd-red-evidence`) was not run, because flutter_test has no TAP/JUnit reporter and the plan is not `type: tdd`.
- **GREEN:** the real `PinVerifier`, the DI getter and the regenerated config. 23/23 tests passed in `test/application/lock` and `test/config/di`.
- **REFACTOR:** none needed.

## Files Created/Modified
- `lib/domain/lock/pin_record.dart`: `PinRecord` with `encode`/`tryDecode` (v1 record, 32-byte hash check, stringify off)
- `lib/domain/lock/pin_hasher.dart`: `pinLength`, `isValidPin` (exactly four ASCII digits), `PinHasher`
- `lib/domain/lock/pin_store.dart`: the `PinStore` contract
- `lib/infrastructure/lock/pbkdf2_pin_hasher.dart`: `pbkdf2HmacSha256`, `constantTimeEquals`, `Pbkdf2PinHasher`
- `lib/infrastructure/lock/secure_pin_store.dart`: `SecurePinStore`, the attempts codec, and failures that carry only `runtimeType`
- `lib/core/constants/secure_storage_keys.dart`: `SecureStorageKeys.pinRecord` and `pinAttempts`
- `lib/application/lock/pin_verifier.dart`: the outcomes and `PinVerifier` (102 lines)
- `lib/application/lock/README.md`: README for the new directory
- `lib/config/di/infrastructure_module.dart`: the `secureStorage` getter
- `lib/config/di/injection.config.dart`: regenerated
- `lib/config/startup/app_lock_startup.dart`: `startAppLock`
- `lib/core/constants/storage_keys.dart`: `biometricUnlockEnabled` and `secureStorageInitialized`; the `pinConfigured` doc now says it is a non-secret flag
- `lib/main.dart`: step 5 is `await startAppLock()`, and `runApp` becomes step 6
- Tests: `pbkdf2_pin_hasher_test` (15), `secure_pin_store_test` (9), `pin_verifier_test` (16), `lock_di_test` (4), `app_lock_startup_test` (6). Support files: `fake_clock.dart` and `lock_fakes.dart`

## Decisions Made
See `key-decisions` in the frontmatter. The main ones:
- The whole PIN record is kept under one key, a discretion choice over the separate keys in PATTERNS.md.
- `aOptions` is not passed, because the analyzer flags the default as redundant.
- Attempt timestamps are stored as UTC milliseconds.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Dropped the explicit `aOptions: AndroidOptions()` argument**
- **Found during:** Task 2
- **Issue:** With `aOptions: AndroidOptions.defaultOptions` (or `AndroidOptions()`), the analyzer reported `avoid_redundant_argument_values`, taking the count to 65. Leaving it in would also have trained the lint against the plan's literal code.
- **Fix:** Removed the argument, since it is the default and behaves the same. The doc comment records that the default `AndroidOptions` (resetOnError true) is in effect.
- **Files modified:** lib/config/di/infrastructure_module.dart
- **Verification:** `flutter analyze --no-fatal-infos --fatal-warnings` reports 64 issues (≤ 65); lock_di_test passes.
- **Committed in:** 9d97214

**2. [Rule 2 - Missing critical] Extra fail-safe tests for startAppLock and the record format**
- **Found during:** Tasks 1 and 3
- **Issue:** The plan's tests did not prove two truths directly: "startup never throws" and "never print PIN material".
- **Fix:** Added two startAppLock tests. One uses a throwing `FlutterSecureStorage` mock and checks that the call completes with the marker unset. The other checks that the call completes with an empty GetIt. Also added tests for `PinRecord.tryDecode` on malformed input, for `toString` never printing salt or hash, and for `isValidPin` (including Arabic-Indic digits).
- **Files modified:** test/config/startup/app_lock_startup_test.dart, test/infrastructure/lock/pbkdf2_pin_hasher_test.dart, lib/domain/lock/pin_record.dart (stringify false)
- **Committed in:** 299a81a, f07bc06

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 missing critical)
**Impact on plan:** No scope creep and no change to any contract in the interfaces block.

## Issues Encountered
- `dart format` on `test/support/` also reformatted the unrelated `test/support/isar_test_harness_test.dart`. That file was restored with `git checkout --` before committing and is not part of this plan.

## Known Stubs
None.

## User Setup Required
None.

## Next Phase Readiness
- 05-04, 05-10, 05-11 and 05-12 can build on `PinVerifier`, `PinStore`, `PinHasher` and `startAppLock`. 05-10 extends `startAppLock` with the boot-time window flag. 05-11 reads `biometricUnlockEnabled` and resolves the D-08 default.
- PIN creation (a later plan) must also reset attempt state (RESEARCH Pitfall 4) and set `pinConfigured`.
- Open item for 05-14 UAT: unlock latency at 10000 iterations on the Infinix X6831 (RESEARCH A2).

## Verification (plan-level)
- `dart run build_runner build --delete-conflicting-outputs`: exit 0
- `flutter test --no-pub test/infrastructure/lock test/application/lock test/config`: pass
- `flutter test --no-pub` (full suite): 980 tests, all passed
- `flutter analyze --no-fatal-infos --fatal-warnings`: exit 0, 64 issues (≤ 65; none in this plan's files)
- `dart run tool/check_architecture.dart`: PASS

---
*Phase: 05-app-lock-settings-polish*
*Completed: 2026-11-16*
