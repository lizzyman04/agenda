# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-12)

**Core value:** Open AGENDA at any moment and immediately see what needs doing and where the money stands — no internet connection ever required.
**Current focus:** Phase 1 — Foundation

## Current Position

Phase: 1 of 5 (Foundation)
Plan: 0 of 5 in current phase
Status: Ready to plan
Last activity: 2026-04-13 — Roadmap created; phases derived from 44 v1 requirements

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**
- Last 5 plans: —
- Trend: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- **Pre-Phase 1**: Use `isar_community` 3.3.2 — original `isar` package abandoned April 2023; API is drop-in compatible; all import paths use `package:isar_community/isar_community.dart`
- **Pre-Phase 1**: Add `infrastructure/` as sixth architectural layer between `data/` and `application/` — houses notification, backup, and app lock service implementations with Flutter/platform dependencies
- **Pre-Phase 1**: `@enumerated(EnumType.name)` is the project-wide convention for all Isar-persisted enums — prevents ordinal corruption on enum reordering
- **Pre-Phase 1**: Schema migration runner design — `schemaVersion` stored in SharedPreferences; migration blocks run inside `IsarService.open()`; `MigrationRunner` executes sequentially
- **Pre-Phase 1**: Notification ID strategy — deterministic derivation (e.g., `taskId * 10 + notificationType`); no separate ID registry; enables cancellation on delete/update and safe boot rescheduling
- **Pre-Phase 1**: Biometric unlock (DATA-06) is in v1 scope — `FlutterFragmentActivity` must replace `MainActivity` before any auth code is written
- **Pre-Phase 1**: Task search (TASK-11) is in v1 scope — Isar indexed field queries; index strategy finalized during Phase 2 schema design
- **Stack**: Flutter + isar_community + BLoC/Cubit + GetIt + injectable; minimum Flutter SDK 3.38.1
- **Architecture**: core/ → domain/ → data/ → infrastructure/ → application/ → presentation/ → config/; strict outer-depends-on-inner rule
- **Language**: All code/comments/enums in English; UI text in PT-BR by default with EN toggle

### Quick Tasks Completed

| ID | Description | Date | Commit |
|----|-------------|------|--------|
| 260413-ss1 | Set up GitHub Pages landing page for AGENDA | 2026-04-13 | d8072b2 |

### Pending Todos

None yet.

### Blockers/Concerns

- **Phase 2 research flag**: OEM Android notification behavior (Samsung/Xiaomi/Huawei) varies significantly; consider a focused research spike before Phase 4 notification scheduling architecture is finalized
- **Phase 4 research flag**: PT-BR comma decimal separator in CSV round-trip (`1.234,56`) has edge cases; dedicate a spike to locale-aware parsing before the backup feature spec is written
- **Phase 5 research flag**: iOS `inactive` vs `paused` lifecycle states for lock triggering behave differently on simulator vs real device; spike recommended before Phase 5 app lock implementation

## Session Continuity

Last session: 2026-04-13
Stopped at: Roadmap written; REQUIREMENTS.md traceability updated; ready to plan Phase 1
Resume file: None
