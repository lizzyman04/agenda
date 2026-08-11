<div align="center">

<h1>AGENDA</h1>

**Your personal HQ for tasks and finances — private, offline, always ready.**

[![CI](https://github.com/lizzyman04/agenda/actions/workflows/ci.yml/badge.svg)](https://github.com/lizzyman04/agenda/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.41.4-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.1-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-3DDC84?logo=android&logoColor=white)](https://flutter.dev/multi-platform/mobile)
[![Privacy](https://img.shields.io/badge/privacy-100%25%20offline-7C4DFF)](#privacy-first)
[![Tests](https://img.shields.io/badge/tests-211%20passing-success)](#testing)
[![Style](https://img.shields.io/badge/style-very__good__analysis-B22ADC)](https://pub.dev/packages/very_good_analysis)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

[Website](https://lizzyman04.com/agenda) ·
[Documentation](docs/) ·
[Architecture](docs/ARCHITECTURE.md) ·
[Contributing](CONTRIBUTING.md) ·
[Code of Conduct](CODE_OF_CONDUCT.md)

</div>

---

> Open AGENDA at any moment — morning, midday, or night — and immediately see
> **what needs doing** and **where your money stands**, without ever needing an
> internet connection.

## Table of Contents

- [Why AGENDA](#why-agenda)
- [Privacy First](#privacy-first)
- [Features](#features)
- [Screenshots](#screenshots)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Testing](#testing)
- [Project Structure](#project-structure)
- [Architecture Rules](#architecture-rules)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)

## Why AGENDA

Most productivity apps ask you to choose: a task manager *or* a budget tracker,
and nearly all of them want your data on someone else's server.

AGENDA is one app for both, and it never phones home. Your tasks and your money
live in a single on-device database, structured around productivity frameworks
that actually have a track record — Eisenhower, 1-3-5, and GTD — rather than
yet another flat checklist.

## Privacy First

Built around a single non-negotiable principle: **your data never leaves your
device.**

| Guarantee | What it means in practice |
|-----------|---------------------------|
| No analytics | Not even anonymous usage or crash reporting |
| No cloud sync | No account, no sign-up, no server — ever |
| No network permission | The app is incapable of making a network request |
| Local-only storage | A single embedded Isar database on your device |
| Airplane-mode complete | 100% of features work with radios off |

This is enforced in the dependency policy, not just documented: no
`firebase_*`, no `sentry_flutter`, no `http`/`dio`. Adding a network client to
this project is a design change, not a chore.

## Features

### Task Management

Three complementary productivity frameworks on top of a full task and project
system.

| Framework | What it gives you |
|-----------|-------------------|
| **Eisenhower Matrix** | Classify by urgency and importance into four quadrants — focus on what truly matters |
| **1-3-5 Rule** | Plan each day as 1 big task, 3 medium, 5 small — structured without being rigid |
| **GTD** | Next actions, contexts, and waiting-for — a full Getting Things Done workflow |

- Projects with subtasks and completion roll-up
- Standalone tasks with due date and time
- Create, edit, delete with 5-second undo (soft delete)
- Recurring tasks — daily, weekly, monthly, custom
- Keyword search
- Filter by project, quadrant, GTD context, or due-date range
- Day Planner enforcing 1-3-5 slot constraints

### Financial Tracking

| Feature | What it gives you |
|---------|-------------------|
| **Income and Expenses** | Log every transaction with categories and notes |
| **Budgets** | Monthly limits per category, tracked in real time with under/near/over states |
| **Savings Goals** | Targets with contribution history and progress |
| **Debts** | What you owe and what others owe you, with paid tracking |
| **Recurring Payments** | Subscriptions and fixed bills with due-date tracking |
| **Dashboard** | Balance, net worth, spending donut and per-category bars, month navigation |

Tasks can be linked to a savings goal or a debt, so financial commitments show
up in your actual workload.

## Screenshots

<div align="center">

| Tasks | Finances | Dashboard |
|:-----:|:--------:|:---------:|
| *(coming soon)* | *(coming soon)* | *(coming soon)* |

</div>

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI | Flutter 3.41.4 (Android + iOS) |
| State | BLoC / Cubit (`flutter_bloc`) |
| Database | Isar Community 3.3.2 (embedded, on-device) |
| Dependency Injection | GetIt + Injectable |
| Routing | go_router |
| Charts | fl_chart |
| Localization | `flutter_localizations` + `intl` (PT-BR default, EN toggle) |
| Testing | `flutter_test` + `bloc_test` + `mocktail` |
| Linting | `very_good_analysis` (strict) |

> **Note on Isar** — the original `isar` package was abandoned in April 2023.
> This project uses the actively maintained community fork, `isar_community`.
> Import paths are `package:isar_community/isar_community.dart`.

## Getting Started

### Prerequisites

- Flutter SDK `>=3.38.1` (tested on `3.41.4`)
- Dart SDK `>=3.7.0`
- Android SDK with a connected device or emulator
- Xcode, for iOS builds

### Setup

```bash
git clone https://github.com/lizzyman04/agenda.git
cd agenda

flutter pub get

# Code generation — Isar schemas + DI graph
dart run build_runner build --delete-conflicting-outputs

# Localizations
flutter gen-l10n

flutter run
```

## Testing

```bash
flutter test --no-pub              # full suite
flutter test --no-pub --coverage   # with coverage
flutter analyze --no-fatal-infos   # static analysis
```

## Project Structure

Strict layering — each layer may depend only on the ones above it.

```
lib/
├── core/            Constants, extensions, failures, Result type
├── domain/          Entities and repository interfaces (pure Dart)
├── data/            Isar models, DAOs, mappers, database service
├── infrastructure/  Repository implementations, platform services
├── application/     BLoC / Cubit state management
├── presentation/    Screens and widgets, grouped by feature slice
└── config/          DI graph, l10n config, router
```

Further reading in [`docs/`](docs/):

| Document | Contents |
|----------|----------|
| [Architecture](docs/ARCHITECTURE.md) | Layers, data flow, DI graph, state management |
| [Getting Started](docs/GETTING-STARTED.md) | Full setup guide |
| [Development](docs/DEVELOPMENT.md) | Adding features, code generation, error handling |
| [Testing](docs/TESTING.md) | Test patterns, BLoC testing, mocktail usage |
| [Configuration](docs/CONFIGURATION.md) | SDK requirements, build config, localization |

## Architecture Rules

Enforced house rules for this codebase:

1. **No source file exceeds 150 lines.** Long files get split by
   responsibility, not chopped arbitrarily.
2. **Aggressive nesting by domain.** No directory holds more than ~10 related
   files. Feature slices nest as
   `presentation/<area>/<feature>/{screens,widgets}/`.
3. **Every nest is documented.** Each feature directory carries a `README.md`
   stating its responsibility, its contents, and any rules specific to it.
4. **Screens own cubits; widgets do not.** Widgets take domain objects and
   callbacks so they stay renderable in isolation and in tests.
5. **Sheets and dialogs own their controllers.** A sheet body is a
   `StatefulWidget` that creates its `TextEditingController`s in its `State`
   and disposes them there, returning a value via `Navigator.pop`. Controllers
   disposed in a caller's method scope crash the app during the dismiss
   transition — this shipped twice before the rule existed.

See [`lib/presentation/finance/goals/README.md`](lib/presentation/finance/goals/README.md)
for a worked example of a compliant slice.

## Roadmap

| Phase | Milestone | Status |
|:-----:|-----------|--------|
| 01 | Foundation — scaffold, database, DI, l10n, CI | ✅ Complete |
| 02 | Task Management | ✅ Complete |
| 03 | Financial Tracking | 🔨 In verification |
| 04 | Notifications and Backup | ⏳ Planned |
| 05 | App Lock — PIN + biometrics | ⏳ Planned |

## Contributing

This is a personal project, but issues and suggestions are welcome. Please read
[CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request, and note that
participation is governed by our [Code of Conduct](CODE_OF_CONDUCT.md).

- [Open an issue](https://github.com/lizzyman04/agenda/issues)
- [Start a discussion](https://github.com/lizzyman04/agenda/discussions)

## Security

AGENDA stores everything locally and makes no network calls, so the usual
server-side attack surface does not exist. If you find a vulnerability —
particularly anything that could expose on-device data — please report it
privately rather than opening a public issue. See [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE) © [lizzyman04](https://github.com/lizzyman04)

---

<div align="center">

*Built with Flutter — private by design, powerful by choice.*

</div>
