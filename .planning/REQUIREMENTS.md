# Requirements: AGENDA

**Defined:** 2026-04-13
**Core Value:** A user should be able to open AGENDA at any moment and immediately see what needs doing and where their money stands, without ever needing an internet connection.

## v1 Requirements

### Task Management

- [x] **TASK-01**: User can create projects with a title and optional description
- [x] **TASK-02**: User can create subtasks within a project
- [x] **TASK-03**: User can create standalone tasks with title, due date, and time
- [x] **TASK-04**: User can edit any task or project
- [x] **TASK-05**: User can delete tasks with a 5-second undo snackbar (soft delete)
- [x] **TASK-06**: User can mark tasks as complete
- [x] **TASK-07**: User can classify tasks using the Eisenhower Matrix (urgent/important quadrants)
- [x] **TASK-08**: User can plan their day using the 1-3-5 Rule (1 big + 3 medium + 5 small tasks)
- [x] **TASK-09**: User can tag tasks with GTD attributes (next action, context, waiting for)
- [x] **TASK-10**: User can create recurring tasks (daily, weekly, monthly, custom interval)
- [x] **TASK-11**: User can search tasks by keyword
- [x] **TASK-12**: User can filter tasks by project, Eisenhower quadrant, GTD context, or due date

### Finance Management

- [ ] **FIN-01**: User can log income transactions with amount, category, date, and optional note
- [ ] **FIN-02**: User can log expense transactions with amount, category, date, and optional note
- [ ] **FIN-03**: User can edit and delete transactions
- [ ] **FIN-04**: User can set a monthly budget limit per expense category
- [ ] **FIN-05**: User can define savings goals with target amount and optional deadline
- [ ] **FIN-06**: User can track savings goal progress (amount saved vs. target)
- [ ] **FIN-07**: User can log debts with direction (to pay vs. to receive), amount, and due date
- [ ] **FIN-08**: User can log recurring payments (subscriptions and bills) with amount and cycle
- [ ] **FIN-09**: User can view a dashboard with current balance and net worth overview
- [ ] **FIN-10**: User can view spending summary charts — monthly breakdown by category (pie and bar)

### Notifications

- [ ] **NOTF-01**: App sends task reminders when due date/time is approaching
- [ ] **NOTF-02**: App sends a daily morning briefing with tasks due that day
- [ ] **NOTF-03**: App sends budget alerts when spending reaches 80% and 100% of a category limit
- [ ] **NOTF-04**: App sends reminders for recurring tasks before they are due
- [ ] **NOTF-05**: App sends overdue debt reminders when a debt is approaching its due date
- [ ] **NOTF-06**: App sends goal progress alerts when a savings goal is off track
- [ ] **NOTF-07**: App sends recurring payment reminders before a bill is due
- [ ] **NOTF-08**: App sends motivational quote notifications (default OFF; user-configurable frequency and time)
- [ ] **NOTF-09**: User can toggle each notification type independently in Settings
- [ ] **NOTF-10**: Notifications respect quiet hours (default 10pm–7am; user-configurable)
- [ ] **NOTF-11**: All scheduled notifications are rescheduled automatically after device reboot

### Data & Privacy

- [x] **DATA-01**: All data is stored locally on the device using Isar; no data is transmitted externally
- [ ] **DATA-02**: User can export all data as a JSON backup file
- [ ] **DATA-03**: User can export all data as a CSV backup file
- [ ] **DATA-04**: User can import data from a JSON or CSV backup file (with pre-import safety backup and atomic transaction)
- [ ] **DATA-05**: User can set an optional PIN to lock access to the app on cold start
- [ ] **DATA-06**: User can unlock the app using biometrics (Face ID or fingerprint) when PIN is enabled

### Experience

- [ ] **UX-01**: App supports English and Portuguese (user-toggled in Settings)
- [x] **UX-02**: App is fully functional offline — no feature requires internet access
- [ ] **UX-03**: App displays a privacy statement on first launch ("Your data never leaves this device")
- [ ] **UX-04**: All screens display meaningful empty states with action prompts when no data exists

## v2 Requirements

### Notifications
- **NOTF-V2-01**: User can snooze a task reminder (15 min / 1 hr / tomorrow)

### Finance
- **FIN-V2-01**: User can toggle budget rollover per category (unused balance carries to next month)
- **FIN-V2-02**: App supports multiple currencies with per-account currency selection

### Tasks
- **TASK-V2-01**: User can input tasks using natural language ("Buy groceries tomorrow at 5pm")

### Sync
- **SYNC-V2-01**: User can opt in to cloud sync across devices (with end-to-end encryption)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Cloud sync / backend server | Privacy-first; MVP is local-only by design. v2 candidate only if E2E encrypted. |
| User accounts / authentication | No accounts exist; optional local PIN only |
| Collaboration / shared tasks | Personal use only |
| Web app | Migrated away from web; native notifications require Flutter mobile |
| Bank integrations / open finance | Manual entry only; API integrations raise privacy concerns |
| Multi-currency UI | Data model supports currency code storage; UI deferred to v2 |
| Natural language task input | v2 — NLP complexity not justified for MVP |
| Budget rollover toggle | v2 — differentiator, not MVP blocker |
| Snooze on notifications | v2 — basic reminders sufficient for MVP |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DATA-01 | Phase 1: Foundation | Complete |
| UX-02 | Phase 1: Foundation | Complete |
| TASK-01 | Phase 2: Task Core | Complete |
| TASK-02 | Phase 2: Task Core | Complete |
| TASK-03 | Phase 2: Task Core | Complete |
| TASK-04 | Phase 2: Task Core | Complete |
| TASK-05 | Phase 2: Task Core | Complete |
| TASK-06 | Phase 2: Task Core | Complete |
| TASK-07 | Phase 2: Task Core | Complete |
| TASK-08 | Phase 2: Task Core | Complete |
| TASK-09 | Phase 2: Task Core | Complete |
| TASK-10 | Phase 2: Task Core | Complete |
| TASK-11 | Phase 2: Task Core | Complete |
| TASK-12 | Phase 2: Task Core | Complete |
| FIN-01 | Phase 3: Finance Core | Pending |
| FIN-02 | Phase 3: Finance Core | Pending |
| FIN-03 | Phase 3: Finance Core | Pending |
| FIN-04 | Phase 3: Finance Core | Pending |
| FIN-05 | Phase 3: Finance Core | Pending |
| FIN-06 | Phase 3: Finance Core | Pending |
| FIN-07 | Phase 3: Finance Core | Pending |
| FIN-08 | Phase 3: Finance Core | Pending |
| FIN-09 | Phase 3: Finance Core | Pending |
| FIN-10 | Phase 3: Finance Core | Pending |
| UX-04 | Phase 3: Finance Core | Pending |
| NOTF-01 | Phase 4: Notifications + Backup | Pending |
| NOTF-02 | Phase 4: Notifications + Backup | Pending |
| NOTF-03 | Phase 4: Notifications + Backup | Pending |
| NOTF-04 | Phase 4: Notifications + Backup | Pending |
| NOTF-05 | Phase 4: Notifications + Backup | Pending |
| NOTF-06 | Phase 4: Notifications + Backup | Pending |
| NOTF-07 | Phase 4: Notifications + Backup | Pending |
| NOTF-08 | Phase 4: Notifications + Backup | Pending |
| NOTF-09 | Phase 4: Notifications + Backup | Pending |
| NOTF-10 | Phase 4: Notifications + Backup | Pending |
| NOTF-11 | Phase 4: Notifications + Backup | Pending |
| DATA-02 | Phase 4: Notifications + Backup | Pending |
| DATA-03 | Phase 4: Notifications + Backup | Pending |
| DATA-04 | Phase 4: Notifications + Backup | Pending |
| DATA-05 | Phase 5: App Lock + Settings + Polish | Pending |
| DATA-06 | Phase 5: App Lock + Settings + Polish | Pending |
| UX-01 | Phase 5: App Lock + Settings + Polish | Pending |
| UX-03 | Phase 5: App Lock + Settings + Polish | Pending |

**Coverage:**
- v1 requirements: 44 total
- Mapped to phases: 44
- Unmapped: 0
- Complete: 14 (DATA-01, UX-02, TASK-01 through TASK-12)

---
*Requirements defined: 2026-04-13*
*Last updated: 2026-04-21 — Phase 2 complete; TASK-01–12, DATA-01, UX-02 marked complete*
