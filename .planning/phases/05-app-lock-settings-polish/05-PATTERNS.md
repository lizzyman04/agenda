# Phase 5: App Lock + Settings + Polish - Pattern Map

**Mapped:** 2026-11-16
**Files analyzed:** ~40 (new + modified)
**Analogs found:** 36 / 40

Hard constraints (tool/check_architecture.dart): max 150 lines/file, max 10 files/dir, README.md in every new `lib/presentation/**` and `lib/application/**` dir.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `lib/core/constants/storage_keys.dart` (MOD: biometricUnlockEnabled, secureStorageInitialized) | config | - | itself | exact |
| `lib/core/constants/secure_storage_keys.dart` | config | - | `lib/core/constants/storage_keys.dart` | exact |
| `lib/domain/lock/{pin_hasher,pin_store,device_auth_gateway,secure_window_gateway,excursion_guard}.dart` | domain interface | request-response | `lib/domain/notifications/notification_permission_service.dart` | exact |
| `lib/domain/lock/lock_attempts.dart`, `lock_policy.dart` | pure model/fn | transform | `lib/domain/notifications/model/*` (pure Dart) | role-match |
| `lib/infrastructure/lock/secure_window_channel.dart` | gateway | request-response (MethodChannel) | `lib/infrastructure/notifications/gateway/notification_permission_service_impl.dart` | exact |
| `lib/infrastructure/lock/local_auth_gateway.dart` | gateway | request-response (plugin) | `lib/infrastructure/backup/file_picker_backup_file_gateway.dart` | exact |
| `lib/infrastructure/lock/secure_pin_store.dart` | repository | CRUD (secure storage) | `lib/infrastructure/backup/file_picker_backup_file_gateway.dart` (plugin wrap) | role-match |
| `lib/infrastructure/lock/pbkdf2_pin_hasher.dart` | utility | transform | RESEARCH.md Code Examples (PBKDF2) | none |
| `lib/infrastructure/lock/excursion_guard_impl.dart` | service | event-driven | `@LazySingleton(as:)` pattern from gateways | role-match |
| `lib/infrastructure/lock/app_lock_bootstrap.dart` (or `lib/config/startup/`) | startup | batch | `lib/config/startup/notification_startup.dart` | role-match |
| `lib/application/lock/app_lock_cubit.dart` + `_state.dart` | cubit | event-driven, sync-seeded | `lib/application/shared/locale/locale_cubit.dart` | exact (seeding) |
| `lib/application/lock/pin_setup_cubit.dart` + state | cubit | request-response | `lib/application/notifications/notification_settings_cubit.dart` | role-match |
| `lib/application/settings/security_settings_cubit.dart` + state | cubit | CRUD prefs | `notification_settings_cubit.dart` / `_state.dart` | exact |
| `lib/application/{lock,settings}/README.md` | doc | - | `lib/application/notifications/README.md` | exact |
| `lib/presentation/lock/**` (LockGate, LockScreen, PinSetupScreen, PrivacyOverlay, PinKeypad, PinDots) | widget/screen | event-driven | `notification_settings_screen.dart` (observer) + `notification_lifecycle_observer.dart` | role-match |
| `lib/presentation/settings/screens/settings_screen.dart` + widgets | screen | request-response | `lib/presentation/notifications/screens/notification_settings_screen.dart` | exact |
| `lib/presentation/onboarding/{onboarding_gate,privacy_statement_screen,privacy_bullet}.dart` | screen | sync prefs read | `locale_cubit.dart` (sync prefs) + `finance_empty_state.dart` (layout) | role-match |
| `lib/presentation/shared/widgets/app_empty_state.dart` | widget | - | `lib/presentation/finance/widgets/finance_empty_state.dart` | exact |
| `lib/app.dart` (MOD) | composition root | - | itself | exact |
| `lib/presentation/tasks/screens/task_list_screen.dart` (MOD line 93) | screen | - | itself | exact |
| `lib/presentation/tasks/widgets/task_list_settings_menu.dart` (DELETE) + its test + READMEs | - | - | - | - |
| `lib/infrastructure/backup/file_picker_backup_file_gateway.dart` (MOD: inject ExcursionGuard) | gateway | - | itself | exact |
| `lib/infrastructure/notifications/gateway/notification_permission_service_impl.dart` (MOD: inject ExcursionGuard) | gateway | - | itself | exact |
| `lib/config/l10n/app_{en,pt,pt_BR}.arb` (MOD) | l10n | - | itself | exact |
| `android/.../MainActivity.kt` (MOD: `agenda/app_privacy`) | native channel | request-response | same file, `agenda/system_settings` block | exact |
| `android/app/src/main/res/values/styles.xml`, `AndroidManifest.xml`, `ios/Runner/*` | config | - | itself | exact |
| `test/application/lock/*_cubit_test.dart`, `test/application/settings/*` | test | - | `test/application/notifications/notification_settings_cubit_test.dart` | exact |
| `test/infrastructure/lock/secure_window_channel_test.dart` | test | - | `test/infrastructure/notifications/system_settings_channel_test.dart` | exact |
| `test/presentation/**` lock/settings/onboarding widget tests; `test/widget_test.dart` (MOD seed flag) | test | - | `test/widget_test.dart` | role-match |

## Pattern Assignments

### `lib/application/lock/app_lock_cubit.dart` (cubit, sync-seeded)
**Analog:** `lib/application/shared/locale/locale_cubit.dart` lines 15-49
```dart
@injectable   // AppLockCubit: use @lazySingleton (one app-wide instance)
class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit(this._prefs)
      : super(LocaleState(_resolveInitialLocale(_prefs)));
  final SharedPreferences _prefs;
  static Locale _resolveInitialLocale(SharedPreferences prefs) {
    final stored = prefs.getString(StorageKeys.locale);
    ...
  }
  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;
    await _prefs.setString(StorageKeys.locale, locale.languageCode);  // persist first
    emit(LocaleState(locale));                                         // then emit
  }
}
```
Apply: `locked = prefs.getBool(StorageKeys.pinConfigured) ?? false` in the initializer so frame 1 is locked. Clock param via `@ignoreParam`.

### `lib/application/settings/security_settings_cubit.dart` + state, `pin_setup_cubit.dart`
**Analog:** `lib/application/notifications/notification_settings_cubit.dart` lines 1-50, `notification_settings_state.dart` lines 1-60
- State: `sealed class XState extends Equatable`, `final class XInitial`, `final class XLoaded` with `copyWith` and documented fields.
- Cubit: `@injectable`, constructor-injected domain interfaces, `start()` async loader with `if (isClosed) return;` before emit, "persist first, then emit" doc rule.

### `lib/presentation/settings/screens/settings_screen.dart` and lock/biometric refresh on resume
**Analog:** `lib/presentation/notifications/screens/notification_settings_screen.dart` lines 11-60
```dart
class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  late final NotificationSettingsCubit _cubit;
  void initState() { super.initState(); _cubit = getIt<NotificationSettingsCubit>();
    unawaited(_cubit.start()); WidgetsBinding.instance.addObserver(this); }
  void dispose() { WidgetsBinding.instance.removeObserver(this);
    unawaited(_cubit.close()); super.dispose(); }
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_cubit.refreshPermissions());
  }
  build: Scaffold(appBar: AppBar(title: Text(l10n.notifSettingsTitle)),
    body: BlocBuilder<..>(bloc: _cubit, builder: (c, s) => switch (s) {
      NotificationSettingsInitial() => const Center(child: CircularProgressIndicator()), ...
```
SecuritySettingsCubit refreshes biometric availability on `resumed` the same way. Language row uses `context.read<LocaleCubit>()` directly (no new state). Notifications/Data rows push `NotificationSettingsScreen()` / `BackupScreen()` unchanged.

### `lib/presentation/lock/widgets/lock_gate.dart` (lifecycle observer)
**Analog:** `lib/config/startup/notification_lifecycle_observer.dart` (whole file, 27 lines) — `final class ... with WidgetsBindingObserver`, override `didChangeAppLifecycleState`, try/`on Object` around hooks. LockGate forwards `inactive`/`hidden`/`paused`/`resumed` to `AppLockCubit`; overlay must paint on `inactive` (RESEARCH Pattern 3). Wrap the lock layer in its own `Navigator` (RESEARCH Pattern 1).

### `lib/app.dart` (MOD)
Existing structure: `MultiBlocProvider` above `MaterialApp` (comment lines 24-30 explains why). Add `BlocProvider<AppLockCubit>(create: (_) => getIt<AppLockCubit>())` next to `LocaleCubit`. Add `builder: (context, child) => LockGate(child: child!)` to `MaterialApp`; replace `home:` content `AppShell` with `OnboardingGate(child: AppShell())` keeping the `TaskListCubit`/`DayPlannerCubit` providers.

### `lib/infrastructure/lock/secure_window_channel.dart`
**Analog:** `notification_permission_service_impl.dart` lines 1-28
```dart
/// Platform channel ...; the Kotlin and Swift handlers must use the same names (pinned by ..._test).
const String systemSettingsChannelName = 'agenda/system_settings';
const String openNotificationSettingsMethod = 'openNotificationSettings';
@LazySingleton(as: NotificationPermissionService)
class NotificationPermissionServiceImpl implements NotificationPermissionService {
  static const MethodChannel _settingsChannel = MethodChannel(systemSettingsChannelName);
```
Mirror: `appPrivacyChannelName = 'agenda/app_privacy'`, `setSecureMethod = 'setSecure'`, `@LazySingleton(as: SecureWindowGateway)`, never throw (safe default).

### `lib/infrastructure/lock/local_auth_gateway.dart`, `secure_pin_store.dart`
**Analog:** `lib/infrastructure/backup/file_picker_backup_file_gateway.dart` lines 12-35 — doc comment "the only class that touches <plugin>", `@LazySingleton(as: Interface)`, `try { ... } on Object catch (e) { ... }` mapping to a domain result (`Success`/failure from `lib/core/failures/result.dart`); never log secrets. Map `LocalAuthException.code` to `DeviceAuthResult`.

### Domain interfaces (`lib/domain/lock/*.dart`)
**Analog:** `lib/domain/notifications/notification_permission_service.dart`
```dart
enum NotificationPermission { granted, denied }
/// Implementations live in `lib/infrastructure/notifications/gateway/`.
/// Every method resolves to a safe default instead of throwing.
abstract interface class NotificationPermissionService {
  Future<NotificationPermission> notificationPermission();
```
Use `abstract interface class`, enums alongside (e.g. `BiometricAvailability`), pure Dart (no Flutter imports).

### `lib/core/constants/secure_storage_keys.dart`
**Analog:** `lib/core/constants/storage_keys.dart` — `abstract final class StorageKeys { /// doc  static const String x = 'x'; }`. New class `SecureStorageKeys` with `pinHash, pinSalt, pinIterations, pinFailures, pinLockouts, pinCooldownUntil`. Add `biometricUnlockEnabled`, `secureStorageInitialized` to StorageKeys.

### `lib/presentation/shared/widgets/app_empty_state.dart`
**Analog:** `lib/presentation/finance/widgets/finance_empty_state.dart` (whole file) — copy exactly (icon 72 `cs.onSurfaceVariant`, 16/8/24 gaps, padding 32, `FilledButton`), make `ctaLabel`/`onCta` nullable and skip CTA when null. FinanceEmptyState may delegate.

### `lib/presentation/onboarding/screens/privacy_statement_screen.dart` / `onboarding_gate.dart`
Gate reads `getIt<SharedPreferences>().getBool(StorageKeys.privacyStatementShown)` synchronously (same as LocaleCubit seed); write flag, then `setState` transition. Layout follows `finance_empty_state.dart` Column style. Language switch calls `LocaleCubit.setLocale`. `readOnly: true` variant from Settings > About.

### `lib/presentation/tasks/screens/task_list_screen.dart` (MOD, lines 87-94)
```dart
actions: [
  IconButton(icon: const Icon(Icons.filter_list), tooltip: l10n.gtdFilterTitle, onPressed: _navigateToGtdFilter),
  const TaskListSettingsMenu(),   // -> IconButton(Icons.settings_outlined, tooltip: l10n.settingsTitle, push SettingsScreen)
],
```

### `android/app/src/main/kotlin/com/omeu/space/agenda/MainActivity.kt` (MOD)
Existing block in `configureFlutterEngine`:
```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "agenda/system_settings")
    .setMethodCallHandler { call, result ->
        when (call.method) {
            "openNotificationSettings" -> result.success(openNotificationSettings())
            else -> result.notImplemented()
        }
    }
```
Add a second `MethodChannel(..., "agenda/app_privacy")` with `"setSecure"` -> validate `call.arguments as? Boolean` (else `result.error`), `window.addFlags/clearFlags(WindowManager.LayoutParams.FLAG_SECURE)` on UI thread. Already `FlutterFragmentActivity`.

### Tests
- Cubit: `test/application/notifications/notification_settings_cubit_test.dart` lines 1-50 — mocktail `class MockX extends Mock implements Interface {}`, `late` fields, `setUp` with `when(...).thenAnswer`, `tearDown` closes cubit. Fakes for lock go in `test/support/lock_fakes.dart`, clock in `test/support/fake_clock.dart`.
- Channel: `test/infrastructure/notifications/system_settings_channel_test.dart` lines 20-45 — `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, ...)`, record `calls`, reset in tearDown. Note line ~31 constructs `NotificationPermissionServiceImpl(FlutterLocalNotificationsPlugin())` — must add the ExcursionGuard arg.
- `test/widget_test.dart`: seed `SharedPreferences.setMockInitialValues({'privacy_statement_shown': true})` and `FlutterSecureStorage.setMockInitialValues({})`.

## Shared Patterns

- **DI:** `@injectable` cubits / `@LazySingleton(as: Interface)` impls; regenerate `lib/config/di/injection.config.dart` with build_runner (never hand-merge). SharedPreferences is `@preResolve` in `lib/config/di/core_module.dart` lines 24-26; register `FlutterSecureStorage`/`LocalAuthentication` as module getters there or in `infrastructure_module.dart`.
- **Persist then emit**, `if (isClosed) return;` after awaits (notification_settings_cubit.dart).
- **Never throw from gateways**; `on Object catch` -> safe default; no secret/PII logging.
- **l10n:** `AppLocalizations.of(context)`; add all ARB keys to all three ARB files in the first plan.
- **Excursion guard:** wrap `FilePicker.saveFile/pickFiles` (file_picker_backup_file_gateway.dart:29,49) and permission/settings calls (notification_permission_service_impl.dart:64-115).
- **README per dir** following `lib/application/notifications/README.md` (Responsibility + Files table with line counts).

## No Analog Found

| File | Reason |
|---|---|
| `lib/infrastructure/lock/pbkdf2_pin_hasher.dart` | No crypto in codebase; use RESEARCH.md "PBKDF2-HMAC-SHA256" example |
| `lib/presentation/lock/keypad/pin_keypad.dart`, `pin_dots.dart` | No custom keypad widgets; follow UI-SPEC |
| `ios/Runner/SceneDelegate.swift` cover view | No iOS native lock code; use RESEARCH.md iOS example |
| `lib/domain/lock/lock_policy.dart` / `lock_attempts.dart` | Pure ladder logic new; follow RESEARCH Patterns 6 |

## Metadata
**Search scope:** lib/, test/, android/app/src/main (git-tracked only)
**Files scanned:** ~15
