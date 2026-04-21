<!-- GSD:GENERATED -->
<!-- generated-by: gsd-doc-writer -->

# Getting Started

Everything you need to go from a fresh machine to a running AGENDA app on a device or emulator.

---

## Prerequisites

Install and verify each tool before continuing.

### Flutter SDK

| Requirement | Version |
|-------------|---------|
| Flutter | `>=3.38.1` (CI pins `3.41.4` stable) |
| Dart | `>=3.7.0 <4.0.0` (bundled with Flutter) |

Install Flutter by following the [official Flutter install guide](https://docs.flutter.dev/get-started/install) for your OS. After installation:

```bash
flutter --version
# Flutter 3.41.4 • channel stable
dart --version
# Dart SDK version: 3.x.x
```

Switch to the pinned version used in CI:

```bash
flutter upgrade
# or use FVM (Flutter Version Manager) if you manage multiple projects:
fvm install 3.41.4
fvm use 3.41.4
```

### Android (required for Android target)

- **Android Studio** `2024.x` or later — includes Android SDK and emulator
- **Android SDK** with `compileSdkVersion` delegated to the Flutter Gradle plugin (see `android/app/build.gradle.kts`)
- **Java 17** — `compileOptions` and `kotlinOptions` in `build.gradle.kts` target `JavaVersion.VERSION_17`
- A physical Android device (USB debugging enabled) or an AVD emulator (API 21+)

Verify:

```bash
flutter doctor --android-licenses   # accept all licenses
flutter doctor                      # should show Android toolchain as OK
```

### iOS (macOS only, required for iOS target)

- **Xcode** `16` or later (from the Mac App Store)
- **CocoaPods** — required for iOS plugin linking

```bash
sudo gem install cocoapods
# or: brew install cocoapods
```

Verify:

```bash
xcode-select --install              # installs command-line tools if missing
flutter doctor                      # should show Xcode as OK
```

---

## Installation Steps

### 1. Clone the repository

```bash
git clone https://github.com/lizzyman04/agenda.git
cd agenda
```

### 2. Install Dart dependencies

```bash
flutter pub get
```

This fetches all packages declared in `pubspec.yaml`, including `isar_community`, `flutter_bloc`, `go_router`, and all dev dependencies needed for code generation.

### 3. Run code generation

AGENDA uses two code generation pipelines that must both complete before `flutter run`.

**Step 3a — Isar schema + injectable DI graph**

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates:
- `lib/data/tasks/item_model.g.dart` — Isar `CollectionSchema` for `ItemModel`
- `lib/config/di/injection.config.dart` — GetIt service locator graph

**Step 3b — Localization files**

```bash
flutter gen-l10n
```

This reads `l10n.yaml` and the ARB files in `lib/config/l10n/` (PT-BR default, EN) and generates `lib/generated/l10n/app_localizations.dart`. The app will not compile without this file.

> Both generation commands are also run automatically in CI (see `.github/workflows/ci.yml`).

### 4. Verify the setup

```bash
flutter analyze --no-fatal-infos --fatal-warnings
flutter test --no-pub
```

All tests should pass and the analyzer should report no issues.

---

## First Run

### On an Android emulator or device

```bash
flutter run
```

Flutter will detect connected devices automatically. If multiple are available, you will be prompted to choose.

To target a specific device:

```bash
flutter devices                     # list available devices
flutter run -d <device-id>
```

### On an iOS simulator (macOS only)

```bash
open -a Simulator                   # start iOS Simulator
flutter run -d <simulator-id>
```

### First launch experience

On first launch, AGENDA:

1. Opens the Isar database in the app documents directory (handled by `IsarService.open`)
2. Runs `MigrationRunner` to apply any pending schema migrations
3. Initialises the GetIt dependency graph (all cubits, repositories, and preferences)
4. Presents the task list in PT-BR (default locale); tap the language toggle to switch to English

No internet connection is required at any point. The app is fully functional offline from the first launch.

---

## Common Setup Issues

### `build_runner` fails with "conflicting outputs"

Run with the `--delete-conflicting-outputs` flag to overwrite stale generated files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

If the error persists, delete the generated files manually and re-run:

```bash
find lib -name "*.g.dart" -delete
dart run build_runner build --delete-conflicting-outputs
```

### App fails to compile with "app_localizations.dart not found"

`flutter gen-l10n` was not run. Execute it before building:

```bash
flutter gen-l10n
```

The `lib/generated/` directory is excluded from version control (listed in `analysis_options.yaml`) and must be regenerated locally.

### `flutter doctor` reports Android licenses not accepted

```bash
flutter doctor --android-licenses
# press 'y' to accept each license
```

### iOS build fails with "CocoaPods not found" or pod install errors

```bash
sudo gem install cocoapods
cd ios && pod install && cd ..
flutter run -d <ios-device>
```

### Wrong Java version for Android builds

The `android/app/build.gradle.kts` targets Java 17. Verify your active JDK:

```bash
java -version
# openjdk version "17.x.x"
```

If using Android Studio, set the JDK in **Settings > Build, Execution, Deployment > Build Tools > Gradle > Gradle JDK**.

---

## Next Steps

| Document | What it covers |
|----------|---------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layer structure, data flow, key abstractions, and directory layout |
| [CONFIGURATION.md](CONFIGURATION.md) | SDK constraints, build settings, localization config, and lint rules |
