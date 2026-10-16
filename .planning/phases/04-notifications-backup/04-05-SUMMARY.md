---
phase: 04-notifications-backup
plan: 05
subsystem: platform-config
tags: [pubspec, android-manifest, gradle-desugaring, auto-backup, flutter_local_notifications, csv, file_picker, timezone]

requires:
  - phase: 04-notifications-backup
    provides: "04-01 package-legitimacy gate approved by the human"
provides:
  - "Five Phase 4 dependencies enabled at exact pins and resolved by flutter pub get"
  - "Android permissions, non-exported plugin receivers, core library desugaring, Auto Backup exclusion"
  - "iOS UNUserNotificationCenter delegate"
  - "Confirmed API names table for csv 8.0.0, file_picker 11.0.2, flutter_local_notifications 21.0.0, flutter_timezone 5.0.2"
affects: [04-08, 04-10, 04-11, 04-16]

plan_head_before: 732bad8b0a281da97606bfa34a1b3170ddf641c1
actuals:
  tokens: 3400
  tasks: 2
  commits: 2

tech-stack:
  added: [csv 8.0.0, file_picker 11.0.2, flutter_local_notifications 21.0.0, flutter_timezone 5.0.2, timezone 0.11.0]
  patterns:
    - "Platform configuration is locked by a source-text contract test (manifest_contract_test.dart)"
    - "Dependency API names are locked by a compile-only smoke test (dependency_smoke_test.dart)"

key-files:
  created:
    - android/app/src/main/res/xml/backup_rules.xml
    - android/app/src/main/res/xml/data_extraction_rules.xml
    - test/infrastructure/notifications/manifest_contract_test.dart
    - test/infrastructure/notifications/dependency_smoke_test.dart
  modified:
    - pubspec.yaml
    - android/app/build.gradle.kts
    - android/app/src/main/AndroidManifest.xml
    - ios/Runner/AppDelegate.swift

key-decisions:
  - "SCHEDULE_EXACT_ALARM declared, USE_EXACT_ALARM deliberately absent (the contract test asserts the absence)"
  - "Both plugin receivers android:exported=false; test fails if either loses it"
  - "allowBackup=false plus rule files excluding all five domains in backup_rules and in both data-extraction sections (D-13)"

requirements-completed: [NOTF-11, DATA-03, DATA-04]

coverage:
  - id: D1
    description: "Five dependencies pinned and resolving"
    requirement: "DATA-03"
    verification:
      - kind: unit
        ref: "test/infrastructure/notifications/manifest_contract_test.dart#pubspec.yaml Phase 4 packages are exact, uncommented pins"
        status: pass
    human_judgment: false
  - id: D2
    description: "Manifest permissions, non-exported receivers, boot actions, backup exclusion, desugaring"
    requirement: "NOTF-11"
    verification:
      - kind: unit
        ref: "test/infrastructure/notifications/manifest_contract_test.dart"
        status: pass
    human_judgment: false
  - id: D3
    description: "Real package API names compile; timezone data loads offline"
    requirement: "DATA-04"
    verification:
      - kind: unit
        ref: "test/infrastructure/notifications/dependency_smoke_test.dart"
        status: pass
    human_judgment: false
  - id: D4
    description: "Android Gradle merge and desugaring accepted by a real build; iOS Runner compiles with the delegate"
    verification: []
    human_judgment: true
    rationale: "flutter build apk did not finish on this host (see Issues) and there is no Xcode on Linux; only the source text is locked by tests"

duration: 15min
completed: 2026-10-16
status: complete
---

# Phase 4 Plan 05: Dependencies and platform configuration Summary

**Five Phase 4 packages pinned and resolving, Android permissions/receivers/desugaring/backup-exclusion and the iOS notification delegate in place, with a contract test and a compile-spike that records the real 21.0.0 / 11.0.2 / 8.0.0 / 5.0.2 API names.**

## Performance

- **Duration:** 15 min (2026-10-16T06:21:38Z to 06:36:25Z, of which about 10 min was a `flutter build apk` attempt that was killed by the timeout)
- **Tasks:** 2 of 2
- **Files:** 8 (4 created, 4 modified)

## Accomplishments

- `pubspec.yaml`: csv, file_picker, flutter_local_notifications, flutter_timezone, timezone enabled at exact pins in alphabetical position; `flutter pub get` exits 0.
- `AndroidManifest.xml`: POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, SCHEDULE_EXACT_ALARM, VIBRATE; ScheduledNotificationReceiver and ScheduledNotificationBootReceiver (both `exported="false"`; boot receiver listens for BOOT_COMPLETED, MY_PACKAGE_REPLACED, QUICKBOOT_POWERON and the HTC variant).
- Auto Backup closed off (D-13): `allowBackup="false"`, `fullBackupContent` and `dataExtractionRules` pointing at XML files that exclude root, file, database, sharedpref and external.
- `build.gradle.kts`: `isCoreLibraryDesugaringEnabled = true` and `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`. MainActivity is untouched and still a `FlutterFragmentActivity`.
- `AppDelegate.swift`: `import UserNotifications` and `UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate` behind `#available(iOS 10.0, *)`.
- 17 tests (12 contract, 5 smoke), all passing.

## Confirmed API names

Read from the installed pub-cache sources and compiled by `dependency_smoke_test.dart`. Plans 04-08, 04-10, 04-11 and 04-16 cite this table.

| Package | Confirmed name / shape | Note |
|---------|------------------------|------|
| csv 8.0.0 | `import 'package:csv/csv.dart';` top-level `final Csv csv = Csv();` with `csv.encode(List<List<dynamic>>) -> String` and `csv.decode(String) -> List<List<dynamic>>` | Default `lineDelimiter` is `'\r\n'`, `autoDetect` (delimiter) is **true**, `dynamicTyping` false (fields stay Strings), `skipEmptyLines` true. Also `csv.decodeWithHeaders(String) -> List<CsvRow>`, `Csv(fieldDelimiter:, lineDelimiter:, quoteMode:, addBom:, autoDetect:, ...)`, `excel` instance (`;`, BOM). The class is `Csv`; `CsvCodec` is a deprecated typedef. Round trip of `1.234,56` and `a, "quoted" note` verified. |
| file_picker 11.0.2 | `FilePicker.saveFile({dialogTitle, fileName, initialDirectory, type = FileType.any, allowedExtensions, Uint8List? bytes, lockParentWindow = false}) -> Future<String?>` | Static; there is no `FilePicker.platform`. On mobile, `bytes` + `fileName` write the file and return the saved path. |
| file_picker 11.0.2 | `FilePicker.pickFiles({dialogTitle, initialDirectory, type, allowedExtensions, onFileLoading, compressionQuality = 0, allowMultiple = false, withData = false, withReadStream = false, lockParentWindow, readSequential, cancelUploadOnWindowBlur}) -> Future<FilePickerResult?>` | Static. Also `getDirectoryPath`, `clearTemporaryFiles`. |
| flutter_local_notifications 21.0.0 | `FlutterLocalNotificationsPlugin().initialize({required InitializationSettings settings, onDidReceiveNotificationResponse, onDidReceiveBackgroundNotificationResponse}) -> Future<bool?>` | **`settings:` is a named parameter in 21.x**, not positional. |
| flutter_local_notifications 21.0.0 | `show({required int id, String? title, String? body, NotificationDetails? notificationDetails, String? payload})` | All named. |
| flutter_local_notifications 21.0.0 | `cancel({required int id, String? tag})`, `cancelAll()`, `cancelAllPendingNotifications()` | `id:` is named. |
| flutter_local_notifications 21.0.0 | `zonedSchedule({required int id, required TZDateTime scheduledDate, required NotificationDetails notificationDetails, required AndroidScheduleMode androidScheduleMode, String? title, String? body, String? payload, DateTimeComponents? matchDateTimeComponents})` | No `uiLocalNotificationDateInterpretation` parameter in 21.x. |
| flutter_local_notifications 21.0.0 | `AndroidScheduleMode`: `alarmClock, exact, exactAllowWhileIdle, inexact, inexactAllowWhileIdle` | |
| flutter_local_notifications 21.0.0 | `InitializationSettings({android, iOS, macOS, linux, windows})`, `AndroidInitializationSettings(String defaultIcon)` positional, `DarwinInitializationSettings({requestAlertPermission, requestSoundPermission, requestBadgePermission, ...})` (all default **true**) | Set the three request flags false to defer the iOS prompt. |
| flutter_local_notifications 21.0.0 | `NotificationDetails({android, iOS, ...})`, `AndroidNotificationDetails(channelId, channelName, {channelDescription, importance, visibility, ...})` | Two positional args then named. `Importance.high`, `NotificationVisibility.{private, public, secret}`. |
| flutter_local_notifications 21.0.0 | `resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()` exposes `requestNotificationsPermission()`, `requestExactAlarmsPermission()`, `canScheduleExactNotifications()`, `areNotificationsEnabled()` (each `Future<bool?>`) | iOS: `IOSFlutterLocalNotificationsPlugin.requestPermissions({sound, alert, badge, provisional, critical, providesAppNotificationSettings})` defaults false. |
| flutter_timezone 5.0.2 | `FlutterTimezone.getLocalTimezone([String? locale]) -> Future<TimezoneInfo>` (static); `TimezoneInfo.identifier` is the IANA string; `localizedName` is a nullable record | The return type is `TimezoneInfo`, **not** `String` as in 4.x and earlier. Also `getAvailableTimezones()`. |
| timezone 0.11.0 | `import 'package:timezone/data/latest.dart'` -> `initializeTimeZones()`; `tz.getLocation('Africa/Maputo')`, `tz.TZDateTime(location, y, m, d, h)`, `.timeZoneOffset` | Africa/Maputo is +2 h, proven with no network. |

No name in the research text turned out to differ from the real API in a way that required adapting the test, but two points are worth the later plans' attention: `initialize` takes `settings:` by name, and `getLocalTimezone` returns `TimezoneInfo`.

## Task Commits

1. **Task 1 (tracer): dependencies, Android config, contract test** - `daf8cba` (feat)
2. **Task 2: iOS delegate, smoke test, contract extension** - `9711e74` (feat)

The tracer feedback gate: `workflow.human_verify_mode` is `end-of-phase` and the tracer's `<verify>` is automated-only, so it was re-run (pub get + contract test + analyze) before Task 2 and passed.

## Deviations from Plan

None - plan executed exactly as written. (`file_picker` was placed after `equatable` rather than literally "before flutter" so the block stays alphabetical.)

## Issues Encountered

- **`flutter build apk --debug` did not complete.** It ran for 637 s and was killed by the 600 s tool timeout (exit 143) while still inside `assembleDebug`. It was not a licence rejection message. `flutter doctor` reports "Some Android licenses not accepted", which may also be a factor. The plan says to record this and leave the build to device UAT rather than change SDK state, so the build was not retried and no SDK state was changed. Manifest merge and desugaring acceptance are therefore **unverified by a real Gradle build**.
- Analyzer: 63 issues at the end (budget 65). Two of the issues the new files introduced were fixed. Remaining `sort_pub_dependencies` infos (`fl_chart`, `test: any`) predate this plan.

## Verification

| Check | Result |
|-------|--------|
| `flutter pub get` | exit 0 |
| `flutter test --no-pub test/infrastructure/notifications` | 17/17 pass |
| `flutter analyze --no-fatal-infos --fatal-warnings` | exit 0, 63 issues |
| `dart run tool/check_architecture.dart` | PASS |
| CI offline grep `^\s+(http:\|dio:\|firebase_\|sentry_flutter\|connectivity_plus)` on pubspec.yaml | no match |

The full `flutter test` suite was not re-run; this plan adds only new test files and non-Dart config.

## Human verification outstanding

1. Build and launch on the Android device (`flutter build apk --debug` / `flutter run`) after accepting licences; expect a successful manifest merge and desugaring, and the task list unchanged.
2. Build the Runner target on a Mac for simulator or device; expect the `UserNotifications` import and delegate assignment to compile.

## Threat Flags

None. `timezone`'s transitive `http` dependency is unused: only `package:timezone/data/latest.dart` is imported, and the smoke test proves the data loads with no network.

## Known Stubs

None.

## Next Phase Readiness

Wave 2 plans no longer need to touch pubspec.yaml, Gradle, the manifest or the AppDelegate. Plans 04-08, 04-10, 04-11 and 04-16 should cite the Confirmed API names table above.

## Self-Check: PASSED

Files verified on disk; commits `daf8cba` and `9711e74` present.
