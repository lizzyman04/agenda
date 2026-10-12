# Phase 4: Notifications + Backup - Context

**Gathered:** 2026-10-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver every notification type (task reminders, morning briefing, recurring-task reminders, budget 80%/100% alerts, debt reminders, goal off-track alerts, recurring-payment reminders, motivational quotes), boot-safe rescheduling, per-type toggles and quiet hours (NOTF-01..11), plus JSON/CSV export and atomic import with a safety backup (DATA-02..04). The Settings screen, PIN lock, language toggle and onboarding stay in Phase 5.

</domain>

<decisions>
## Implementation Decisions

### Reminder timing
- **D-01:** Task reminders fire a **fixed 30 minutes before** the due time. No per-task or global lead setting. Date-only tasks (no time) fire at the morning-briefing hour on the due day.
- **D-02:** Debt-due and recurring-payment (bill/subscription) reminders fire **1 day before the due date at 09:00**, once. No repeat for overdue debts.
- **D-03:** Morning briefing defaults to **08:00**, time **user-configurable** in notification prefs. Body: count of tasks due today + top 3 titles. **Skipped on days with nothing due.**
- **D-04:** Recurring-task reminders schedule the **next occurrence only**; reschedule when an occurrence is completed and on app start. Keeps usage under the iOS 64-notification cap.

### Budget and goal alerts
- **D-05:** Budget alerts are evaluated **on transaction save/edit** (app open), not by a scheduled job. Thresholds 80% and 100% each fire **at most once per category per calendar month**. Fired state must be persisted so it survives restarts.
- **D-06:** Goal off-track = saved amount is more than **10% below linear expected progress** between goal creation and deadline. Evaluated on app open and by a **weekly scheduled check (Mon 09:00)**; max one alert per goal per week. Goals without a deadline are never flagged.

### Quotes and quiet hours
- **D-07:** Motivational quotes come from a **bundled static list, ~50 per language** (PT-BR + EN, following app locale). Default **OFF**. User picks **daily or weekly** plus a time. Pre-schedule the next ~7 in random non-repeating order.
- **D-08:** Quiet hours default **22:00-07:00**, configurable. A notification landing inside the window is **deferred to the window end** (not dropped), for all types including the morning briefing if its time falls inside.
- **D-09:** Notification preferences live on a **standalone Notification Settings page + cubit** in Phase 4, reachable from a temporary entry point. Phase 5 mounts it as a section of the Settings screen with no rework. Prefs stored in SharedPreferences.

### Backup and import
- **D-10:** **JSON** is the full, versioned backup/restore format (every collection in one file). **CSV** is exported **one file per entity** (tasks, transactions, budgets, goals, debts, recurring payments) and is also importable (DATA-04). CSV decimals are locale-aware.
- **D-11:** Import is **replace-all, atomic**: automatic safety backup first, then wipe + load in a single Isar transaction. A failed import leaves the database unchanged. A confirmation screen shows record counts and date range before commit.
- **D-12:** Exports are written to a **user-chosen location via file_picker** (no share_plus, to avoid routing data to other apps). The pre-import safety backup goes to the **app-private documents directory** (keep last 3); its path is shown if import fails.

- **D-13:** `android:allowBackup` is set to **false** with exclusion rules, so Android Auto Backup never uploads the Isar DB or safety backups to Google Drive. State it in the privacy text; reinstall requires restoring from an exported JSON.
- **D-14:** CSV import replaces **only the entity collections for which a file was supplied** (multi-file pick), within the same safety-backup + single-transaction flow. A single-file import never touches other collections.
- **D-15 (research recommendations accepted as defaults):** goal off-track tolerance is 10 percentage points; JSON export includes soft-deleted rows, CSV exports active rows only; `RecurringPayment.nextDueDate` is advanced in memory for scheduling only (no DB write); import confirmation date range is min..max record `createdAt` plus `exportedAt`; temporary settings entry point is a task-list AppBar action.

### Claude's Discretion
- Notification ID strategy and channel layout per type.
- Android exact-alarm permission flow/fallback and notification permission prompt timing.
- iOS 64-slot priority ordering when the cap is reached.
- Tap-through navigation targets from each notification.
- JSON schema versioning and CSV column layout.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and scope
- `.planning/ROADMAP.md` - Phase 4 goal, success criteria, planned 04-01..04-05 breakdown
- `.planning/REQUIREMENTS.md` - NOTF-01..11, DATA-02..04, v2 exclusions (snooze, multi-currency)
- `.planning/PROJECT.md` - privacy and offline constraints, tech stack decisions

### Prior decisions
- `.planning/phases/03-finance-core/03-CONTEXT.md` - currency, budget, goal, debt, recurring payment model decisions
- `.planning/phases/02-task-core/02-CONTEXT.md` - task/recurrence model
- `.planning/phases/01-foundation/01-CONTEXT.md` - Isar, migration runner, DI conventions

### Project conventions
- `.planning/phases/06-architecture-compliance/` - 150-line file limit, nested modules, per-nest README (enforced by CI guard)
- `CLAUDE.md` - stack constraints; forbidden packages (no firebase, dio/http, connectivity_plus)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `pubspec.yaml` has commented Phase 4 deps ready to enable: file_picker 11.0.2, flutter_local_notifications 21.0.0, flutter_timezone 5.0.2, timezone 0.11.0. `path_provider` already present.
- `lib/data/finance/recurring/` and `lib/infrastructure/finance/recurring_payment_repository_impl.dart` - recurring payment source for bill reminders.
- `lib/config/di/infrastructure_module.dart` - where notification and backup services register.
- `lib/core/failures/failure.dart` - sealed Failure types for Result-returning services.

### Established Patterns
- Clean Architecture layers (core/domain/data/infrastructure/application/presentation/config); Cubits with Equatable state.
- Phase 6 rules: no hand-written file over 150 lines, max ~10 files per directory, README in each feature nest.
- SharedPreferences for non-sensitive prefs (currency, locale).

### Integration Points
- Transaction save path in finance cubits triggers budget alert evaluation.
- Task/goal/debt/recurring-payment repositories trigger (re)scheduling on create/edit/complete/delete.
- MigrationRunner/Isar transaction used for atomic import.
- App start reschedules pending notifications; boot receiver covers device reboot.

</code_context>

<specifics>
## Specific Ideas

No specific requirements - open to standard approaches.

</specifics>

<deferred>
## Deferred Ideas

- Per-task reminder lead time and snooze (NOTF-V2-01) - v2.
- User-editable quotes - possible future phase.
- Merge-by-id import mode - not in MVP.
- Phase 3 `03-VERIFICATION.md` status `gaps_found` (BL-01) was noted in STATE.md; not part of this phase.

</deferred>

---

*Phase: 4-Notifications + Backup*
*Context gathered: 2026-10-12*
