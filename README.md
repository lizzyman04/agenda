<div align="center">

# AGENDA

### *Uma tarefa espera por você!*

**Your personal HQ for tasks and finances — private, offline, always ready.**

<br>

[![Flutter](https://img.shields.io/badge/Flutter-3.41.4-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.1-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![CI](https://github.com/lizzyman04/agenda/actions/workflows/ci.yml/badge.svg)](https://github.com/lizzyman04/agenda/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey?logo=android&logoColor=white)](https://flutter.dev/multi-platform/mobile)
[![Privacy](https://img.shields.io/badge/privacy-100%25%20offline-blueviolet)](#privacy-first)

<br>

> Open AGENDA at any moment — morning, midday, or night —
> and immediately see **what needs doing** and **where your money stands**,
> without ever needing an internet connection.

</div>

---

## Screenshots

<div align="center">

| Tasks | Finances | Dashboard |
|:-----:|:--------:|:---------:|
| *(coming soon)* | *(coming soon)* | *(coming soon)* |

</div>

---

## Features

### Task Management

AGENDA implements three complementary productivity frameworks on top of a full task and project system.

| Framework | Description |
|-----------|-------------|
| **Eisenhower Matrix** | Classify tasks by urgency and importance into four quadrants — focus on what truly matters |
| **1-3-5 Rule** | Plan each day with exactly 1 big task, 3 medium, and 5 small — structured without being rigid |
| **GTD** | Tag tasks as next actions, assign contexts, mark waiting-for — full Getting Things Done workflow |

**Task system capabilities:**

- Projects with subtasks and completion roll-up
- Standalone tasks with title, due date, and time
- Create, edit, and delete with 5-second undo (soft delete)
- Mark tasks complete
- Recurring tasks with configurable intervals (daily, weekly, monthly, custom)
- Search tasks by keyword
- Filter by project, Eisenhower quadrant, GTD context, or due date range
- Day Planner view enforcing 1-3-5 slot constraints

### Financial Tracking *(Phase 3 — planned)*

| Feature | Description |
|---------|-------------|
| **Income and Expenses** | Log every transaction with categories and notes |
| **Budgets** | Set monthly limits per category and track spending in real time |
| **Debts** | Track what you owe and what others owe you |
| **Savings Goals** | Define targets and watch your progress |
| **Reports** | Visual charts and summaries of your financial health |

- Export to CSV for external analysis
- Import from CSV to migrate data

---

## Privacy First

AGENDA is built around a single non-negotiable principle: **your data never leaves your device**.

- No analytics — not even anonymous crash reporting
- No cloud sync — no account required, ever
- No internet permission — the app cannot make network requests
- Data stored exclusively in an on-device Isar database
- 100% functional with airplane mode on

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| **UI** | Flutter 3.41.4 (Android + iOS) |
| **State** | BLoC / Cubit (`flutter_bloc` 9.1.1) |
| **Database** | Isar Community 3.3.2 (embedded, on-device) |
| **Dependency Injection** | GetIt 9.2.1 + Injectable 2.7.1 |
| **Routing** | go_router 17.2.0 |
| **Localization** | flutter_localizations + intl (PT-BR default, EN toggle) |
| **Testing** | bloc_test + mocktail |
| **Linting** | very_good_analysis (strict) |

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.38.1` (tested on `3.41.4`)
- Dart SDK `>=3.7.0`
- Android SDK with a connected device or emulator
- Xcode (for iOS builds)

### Setup

```bash
# Clone the repository
git clone https://github.com/lizzyman04/agenda.git
cd agenda

# Install dependencies
flutter pub get

# Run code generation (Isar schemas + DI graph)
dart run build_runner build --delete-conflicting-outputs

# Generate localizations
flutter gen-l10n

# Run on a connected device
flutter run
```

### Running Tests

```bash
# All tests
flutter test --no-pub

# With coverage
flutter test --no-pub --coverage
```

### Lint

```bash
flutter analyze --no-fatal-infos
```

---

## Project Structure

```
lib/
├── core/               # Constants, extensions, failure hierarchy, result types
├── domain/             # Entities and repository interfaces
├── data/               # Isar models, DAOs, database service
├── infrastructure/     # Repository implementations
├── application/        # BLoC/Cubit state management
├── presentation/       # Screens, widgets, navigation
└── config/             # DI graph, l10n config, router
```

Detailed documentation is available in the [docs/](docs/) directory:

- [Architecture](docs/ARCHITECTURE.md) — layers, data flow, DI graph, state management
- [Getting Started](docs/GETTING-STARTED.md) — full setup guide
- [Development](docs/DEVELOPMENT.md) — adding features, code generation, error handling
- [Testing](docs/TESTING.md) — running tests, BLoC testing patterns, mocktail usage
- [Configuration](docs/CONFIGURATION.md) — SDK requirements, build config, localization setup

---

## Roadmap

| Phase | Milestone | Status |
|-------|-----------|--------|
| 01 | Foundation (scaffold, DB, DI, l10n, CI) | Complete |
| 02 | Task Management | Complete |
| 03 | Financial Tracking | Planned |
| 04 | Notifications and Backup | Planned |
| 05 | App Lock (PIN + Biometrics) | Planned |

---

## Contributing

This is a personal project. Issues and suggestions are welcome via [GitHub Issues](https://github.com/lizzyman04/agenda/issues).

---

## License

MIT © [lizzyman04](https://github.com/lizzyman04)

---

<div align="center">

*Built with Flutter — private by design, powerful by choice.*

[PT-BR version →](README_pt.md)

</div>
