# Phase 1: Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-13
**Phase:** 01-foundation
**Areas discussed:** App identity, Failure modeling, Env config, Code quality

---

## App Identity

| Option | Description | Selected |
|--------|-------------|----------|
| com.lizzyman04.agenda | Personal identifier | |
| com.agenda.app | Product-first naming | |
| com.omeu.space.agenda | Custom domain-based | ✓ |
| Android + iOS only | Clean, minimal setup | ✓ |
| All platforms | Includes web/desktop | |
| AGENDA (all caps) | Matches brand name | ✓ |
| Agenda (title case) | Conventional mobile style | |

**User's choice:** Package name `com.omeu.space.agenda`, Android + iOS only, display name `AGENDA`

---

## Failure Modeling

| Option | Description | Selected |
|--------|-------------|----------|
| Sealed Failure hierarchy | Abstract class with sealed subclasses | ✓ |
| Typed exceptions | Custom exception classes | |
| Result<T, F> type | Either-style generic wrapper | |
| Per-layer granularity | DatabaseFailure, ValidationFailure, etc. | ✓ |
| Per-feature granularity | TaskFailure, FinanceFailure, etc. | |
| Generic only | Single UnexpectedFailure class | |

**User's choice:** Sealed Failure hierarchy with per-layer granularity

---

## Env Config

| Option | Description | Selected |
|--------|-------------|----------|
| App constants only | Single AppConfig class | ✓ |
| dart-define flags | --dart-define at build time | |
| Flutter flavors | Full dev/staging/prod setup | |
| Logging only | Debug verbose, release silent | ✓ |
| Feature flags too | Debug-only features | |
| No differences | Same code in both modes | |

**User's choice:** App constants only (`AppConfig` in `core/config/`), logging differences only via `kDebugMode`

---

## Code Quality

| Option | Description | Selected |
|--------|-------------|----------|
| very_good_analysis | Strict VGV rules | ✓ |
| flutter_lints | Official Flutter rules | |
| flutter_lints + custom | Official base + manual rules | |
| Unit tests for core logic | MigrationRunner, failures, AppConfig | ✓ |
| Full coverage target | 80%+ threshold from day one | |
| No tests in Phase 1 | Add in feature phases | |

**User's choice:** `very_good_analysis`, unit tests for core logic only

---

## Claude's Discretion

- Extension methods in `core/extensions/`
- `AppConfig` internal structure (static vs singleton)
- Router choice (go_router recommended)
- CI tooling

## Deferred Ideas

None.
