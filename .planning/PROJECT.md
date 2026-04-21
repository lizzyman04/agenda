# AGENDA

## What This Is

AGENDA is a privacy-first Flutter mobile app (Android + iOS) that serves as a personal HQ for task management and personal finances. It combines structured productivity frameworks (Eisenhower Matrix, 1-3-5 Rule, GTD) with full financial tracking (income, expenses, budgets, savings goals) — all stored exclusively on the user's device, with no server or cloud dependency.

## Core Value

A user should be able to open AGENDA at any moment — morning, midday, or night — and immediately see what needs doing and where their money stands, without ever needing an internet connection.

## Requirements

### Validated

**Task Management (Phase 2 — complete)**
- [x] User can create projects and break them down into subtasks
- [x] User can classify tasks using the Eisenhower Matrix (urgent/important quadrants)
- [x] User can apply the 1-3-5 Rule to plan their day (1 big + 3 medium + 5 small tasks)
- [x] User can tag tasks with GTD attributes (next action, context, waiting for)
- [x] User can set due dates and times on tasks
- [x] User can create recurring tasks
- [x] User can mark tasks as complete
- [x] User can search tasks by keyword
- [x] User can filter tasks by project, Eisenhower quadrant, GTD context, or due date range

**Foundation (Phase 1 — complete)**
- [x] All data stored locally on device using Isar (no cloud, no accounts)
- [x] App works fully offline (no internet required for any feature)

### Active

**Finance Management**
- [ ] User can log income and expenses with categories
- [ ] User can set and track budgets per category
- [ ] User can define and track progress toward savings goals
- [ ] User can track debts (to pay and to receive) with due dates
- [ ] User can log recurring payments (subscriptions, bills)

**Notifications**
- [ ] App sends task reminders when due date/time is approaching
- [ ] App sends a daily morning briefing with the day's tasks
- [ ] App sends budget alerts when user approaches or exceeds a category limit
- [ ] App sends reminders for recurring tasks
- [ ] App sends overdue debt reminders when a debt is approaching its due date
- [ ] App sends goal progress alerts when a financial goal is off track
- [ ] App sends recurring payment reminders for subscriptions and bills
- [ ] App sends motivational quote notifications on a recurring schedule

**Data & Privacy**
- [ ] User can export all data as JSON and/or CSV
- [ ] User can import data from JSON/CSV backup
- [ ] User can set an optional password to lock access to the app

**Experience**
- [ ] App supports English and Portuguese (user-toggled)

### Out of Scope

- Cloud sync / backend server — privacy-first; MVP is local-only by design
- User accounts / authentication — no accounts; optional local password only
- Collaboration / shared tasks — personal use only
- Web version — migrated away from web; native notifications require Flutter mobile
- Bank integrations / open finance — manual entry only in MVP

## Context

AGENDA is a Flutter rebuild of an existing web app that was archived (see git: "chore: archive legacy web version"). The primary motivation for the migration is **native notifications that work with the app closed** — something the web version could not deliver.

The project already reached v1.0.0 and completed two beta tests on the web. The Flutter version starts fresh with a clean architecture, carrying forward the product vision and feature set of the web version.

**Technology decisions are final (pre-decided by owner):**
- Flutter for cross-platform mobile (Android + iOS)
- Isar Community for local embedded database
- BLoC/Cubit for state management
- GetIt + injectable for dependency injection
- flutter_local_notifications for native push
- file_picker + path_provider for backup

**Architecture:** Clean Architecture with layers: `core/`, `domain/`, `data/`, `infrastructure/`, `application/`, `presentation/`, `config/`

**Language convention:** All code, comments, variables, and enums in English. UI text in Portuguese by default, with English toggle.

## Constraints

- **Privacy**: No data may leave the device — no analytics, no crash reporting to external services, no cloud sync in MVP
- **Tech Stack**: Flutter + Isar Community + BLoC/Cubit + GetIt — these are decided, not up for debate
- **Platform**: Mobile only (Android + iOS) — no web, no desktop in MVP
- **Connectivity**: App must be 100% functional offline — no feature may require internet
- **Language**: All code in English; UI text in PT-BR with EN toggle

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Rebuild in Flutter (not improve web app) | Native notifications require platform-level access unavailable in web | Validated — Phase 1 complete |
| Isar Community as local database | Original `isar` abandoned April 2023; community fork is drop-in compatible and actively maintained | Validated — used throughout Phase 1 and 2 |
| BLoC/Cubit for state management | Clean separation of UI and business logic; testable | Validated — TaskListCubit, ProjectCubit, DayPlannerCubit all proven in Phase 2 |
| Local-only in MVP (no cloud sync) | Privacy-first; simplifies architecture; backup via export/import | Validated — no network permission declared |
| Clean Architecture with 7 modular layers | Maintainability and testability as codebase grows | Validated — layer boundaries held cleanly through Phase 2 |
| Productivity frameworks (Eisenhower + 1-3-5 + GTD) | Differentiates from basic to-do apps; matches original AGENDA vision | Validated — all three frameworks implemented in Phase 2 |
| EisenhowerQuadrant computed at domain layer, not stored | Prevents stale quadrant data when urgency/importance flags change | Applied in Phase 2; no issues |
| Soft delete via `deletedAt` field | Enables 5-second undo snackbar without transactional complexity | Applied in Phase 2; works correctly |
| `go_router` declared now, wired in Phase 5 | Routing is currently `IndexedStack` + modal; go_router guard required for PIN lock screen | Deferred — Phase 5 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-21 — Phase 2 complete*
