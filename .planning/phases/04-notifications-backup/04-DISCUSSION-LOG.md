# Phase 4: Notifications + Backup - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-10-12
**Phase:** 4-Notifications + Backup
**Areas discussed:** Reminder timing, Budget & goal alerts, Quotes & quiet hours, Backup format & import

---

## Reminder timing

| Question | Options considered | Selected |
|----------|--------------------|----------|
| Task reminder lead | Fixed 30 min / at due time / global configurable / per-task | Fixed 30 min before |
| Debt and bill reminders | 1 day before 09:00 / 3d+1d / due day / configurable | 1 day before, 09:00 |
| Morning briefing | 08:00 configurable / fixed / +finance line / always send | 08:00 configurable, skip if empty |
| Recurring task reminders | Next occurrence / next 4 / native repeating / you decide | Next occurrence only |

## Budget & goal alerts

| Question | Options considered | Selected |
|----------|--------------------|----------|
| Budget alert timing | On save once per threshold per month / every time / daily check / save+daily | On save, once per threshold per month |
| Goal off-track rule | Linear pace weekly / on open only / 30d <50% / you decide | Linear pace, weekly check |

## Quotes & quiet hours

| Question | Options considered | Selected |
|----------|--------------------|----------|
| Quote source | Bundled ~50/lang daily-weekly / daily only / user-editable / small weekly | Bundled ~50 per language, daily/weekly |
| Quiet hours behavior | Defer / drop / silent / defer except critical | Defer to window end |
| Prefs UI location | Standalone page / minimal Settings shell / two pages / you decide | Standalone Notification Settings page |

## Backup format & import

| Question | Options considered | Selected |
|----------|--------------------|----------|
| Format roles | JSON full + CSV per-entity importable / JSON restore only / single CSV / JSON only | JSON full backup; CSV per-entity, importable |
| Import semantics | Replace atomically / merge / user chooses / replace JSON merge CSV | Replace all, atomic |
| File I/O | file_picker + private safety dir / share sheet / Downloads / you decide | file_picker; safety backup in app-private dir |

## Claude's Discretion

Notification IDs and channels, exact-alarm permission flow, permission prompt timing, iOS 64-slot priority, tap-through navigation, JSON/CSV schema details.

## Deferred Ideas

Per-task lead/snooze (v2), user-editable quotes, merge import mode.
