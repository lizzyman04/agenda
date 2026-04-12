# Features Research — AGENDA

**Domain:** Combined productivity (task management) + personal finance mobile app
**Researched:** 2026-04-12
**Scope:** 2025 mobile app landscape — Android + iOS

---

## Task Management

### Table Stakes
**Confidence: HIGH** (verified across Todoist, Notion, Google Tasks, Asana community feedback, multiple 2025 review sources)

| Feature | Why Non-Negotiable | Notes for AGENDA |
|---|---|---|
| Create, edit, delete tasks | Absolute baseline | Covered |
| Due date + time per task | Users abandon apps that can't schedule time-of-day | Covered |
| Mark task complete | Core interaction loop | Covered |
| Recurring tasks | Bills, habits, weekly reviews — users need this | Covered |
| Projects / grouping | Flat task lists feel unusable past ~20 tasks | Covered via Projects |
| Subtasks | Breaking work down is universal expectation | Covered |
| Search | Users expect instant keyword search across all tasks | **Not listed — should add** |
| Basic prioritization | Even "high/medium/low" is expected | Covered via Eisenhower |
| Offline functionality | Losing tasks because of no network is unforgivable | Covered (local-only) |
| Notifications / reminders | A task app without reminders is a static list | Covered |

### Differentiators
**Confidence: MEDIUM** (supported by community forums, user studies, competitor analysis — not all independently verified against AGENDA's exact feature set)

| Feature | Value | Complexity | Notes |
|---|---|---|---|
| Eisenhower Matrix view | Rare in simple apps; power users actively seek it — GTD forum shows explicit demand | Medium | Covered — genuine differentiator |
| 1-3-5 Rule daily planning | Almost no mainstream app implements this explicitly | Medium | Covered — rare and valued by productivity enthusiasts |
| GTD context + next action + waiting for | GTD is a major user segment; dedicated GTD apps are either overbuilt (OmniFocus) or dead | High | Covered — positions AGENDA in an underserved niche |
| Privacy / no cloud / no account | Growing user segment (Super Productivity, Brisqi, Vikunja) actively seeking local-first; privacy concerns post-2023 breaches | Medium | Covered — strong differentiator |
| Bilingual PT-BR + EN | No significant task app is built for Brazilian market with full PT-BR | Low | Covered — regional differentiator |
| Daily briefing notification | Morning digest replaces checking app; Todoist's "Today" view partially solves this but push briefings are rare | Low | Covered |
| Combined task + finance in one app | No mainstream app successfully bridges both; users currently juggle 2+ apps | High | Covered — core AGENDA bet |

### Anti-features
**Confidence: HIGH** (consistently reported as churn triggers in app store reviews, UX studies, and Todoist/Notion community feedback)

| Anti-feature | Why It Hurts | What to Do Instead |
|---|---|---|
| Paywalling core features on first use | Todoist's free-tier frustration is the #1 complaint; users churn before seeing value | AGENDA is free/local — no paywall risk |
| Mandatory account creation | Users abandon apps at sign-up friction; local-only apps win on first open | No accounts in AGENDA — correct call |
| Notification spam out of the box | 64% of users disable notifications if >5/week arrive | Default to minimal notifications; let user configure each type independently |
| "Flexibility becomes burden" trap (Notion problem) | When setup takes more time than using, users abandon | Opinionated defaults — task goes into inbox, user can optionally categorize; don't force framework on creation |
| Complex onboarding before first task | Users need a task created in under 30 seconds on first open | First task creation must have zero friction; frameworks are optional, not gated |
| Inconsistent recurring task behavior | Bugs in recurrence are catastrophic trust-breakers | Test recurrence exhaustively; edge cases: monthly on 31st, daylight saving time |
| No undo on delete | Users delete tasks accidentally; no undo = lost trust | Implement soft delete with 5-second undo snackbar |
| Overloaded creation screen | Requiring due date + project + priority before saving kills momentum | Minimal task creation: just a title; all other fields optional and collapsed |

---

## Finance Management

### Table Stakes
**Confidence: HIGH** (verified via YNAB, Wallet/BudgetBakers 340K+ reviews, NerdWallet analysis, multiple 2025 finance app roundups)

| Feature | Why Non-Negotiable | Notes for AGENDA |
|---|---|---|
| Log income + expenses | Core action; app is useless without this | Covered |
| Category assignment | Users need to know where money goes; uncategorized = unusable reports | Covered |
| Budget per category | Most-demanded finance feature after basic tracking | Covered |
| Balance / net worth overview | One-number answer to "how am I doing" — expected on home screen | Should be on dashboard |
| Savings goals with progress | Visual progress bars for goals drive motivation; universally expected | Covered |
| Debt tracking | "Money I owe" and "money owed to me" are distinct user mental models | Covered (to pay + to receive) |
| Recurring payments / subscriptions | Subscriptions are the #1 source of budget surprises; users expect a dedicated view | Covered |
| Date-based transaction history | Scrollable chronological list is the most-used finance view | Covered implicitly |
| Basic charts / spending summary | Pie or bar chart by category — users expect at minimum a monthly summary | **Not listed — should add** |
| Export data | Users expect data portability; Koody, Emma, Moneyspire all feature CSV export as key differentiator | Covered (JSON + CSV) |

### Differentiators
**Confidence: MEDIUM** (supported by review analysis and UX studies; some claims based on limited independent verification)

| Feature | Value | Complexity | Notes |
|---|---|---|---|
| Debt direction tracking (owe vs. owed) | Most apps only track "debts to pay"; tracking "money owed to me" is rare | Low | Covered — genuine differentiator |
| Recurring payment reminders | "Forgot about Netflix" is universal; proactive reminders days before charge | Low | Covered |
| Goal progress alerts when off track | Not just visual progress — push notification when falling behind goal pace | Medium | Covered |
| Budget alerts at threshold (e.g., 80%) | Early warning beats "you exceeded" by a full day | Low | Covered — specify configurable threshold, not just 100% |
| Manual-only with full local privacy | Post-2025 finance app breach news (6 apps exposing data) — growing demand for local | Low | Covered — strong differentiator for privacy-conscious users |
| Combined context with tasks | Seeing "car payment due" alongside "schedule car service" — unique to AGENDA | High | Core AGENDA value proposition |

### Anti-features
**Confidence: HIGH** (directly observed from YNAB, Wallet BudgetBakers, and fintech UX research)

| Anti-feature | Why It Hurts | What to Do Instead |
|---|---|---|
| Information overload on finance home | BudgetBakers users explicitly complain of "too many options"; money is already stressful | Lead with 3 numbers: balance, this month's spend, biggest budget at risk |
| Financial jargon without explanation | Terms like "envelope budgeting" or "zero-based" alienate users new to structured finance | Use plain language; tooltip explanations where terms are unavoidable |
| Graphs before context | Showing complex charts before user has any data confuses and discourages | Show empty state with action prompt, not empty charts |
| Requiring too many fields to log a transaction | If logging an expense takes >3 taps, users stop logging | Minimum: amount + category; date defaults to today; notes optional |
| No confirmation before deleting transactions | Deleted financial records can't be recovered from local storage | Require confirmation with summary of what will be deleted |
| Budget that resets with no rollover option | Users expect to choose whether unused budget rolls over or resets | Offer rollover toggle per budget category |
| Single currency only (YNAB's gap) | Brazilian users traveling or earning in USD have no option | Consider multi-currency as v2 differentiator; at minimum don't hard-code one symbol |

---

## Notifications

### Table Stakes
**Confidence: HIGH** (verified via push notification studies, Smashing Magazine 2025 guidelines, mobile UX research)

| Feature | Why Non-Negotiable | Implementation Note |
|---|---|---|
| Task due reminders | Core reason users install task apps; missing = app fails its job | Allow per-task reminder time offset (e.g., 30 min before, 1 day before) |
| Budget limit alerts | Users cite "surprise overspend" as primary finance app failure; alerts prevent this | Fire at configurable threshold (suggest default: 80% of budget) |
| Recurring payment reminders | Subscription surprise charges are top user pain point | Fire N days before due date; configurable N |
| Debt due reminders | Late payment fees are emotional triggers; timely reminder = high-value notification | Fire at least 3 days before due date |
| Per-type opt-in/opt-out | Users MUST be able to disable individual notification types without disabling all | Each category (tasks, finance, motivational) needs independent toggle |
| Respect quiet hours | Notifications outside 7am-10pm are aggression, not helpfulness | Default quiet hours 10pm-7am; user-configurable |

### Anti-features
**Confidence: HIGH** (backed by Localytics data: 52% of users who disable push notifications eventually churn; Appbot 2026 best practices)

| Anti-feature | Consequence | Prevention |
|---|---|---|
| Sending all notification types enabled by default | Users feel bombarded on day 1; disable all → churn path begins | Default to task reminders ON; daily briefing ON; motivational quotes OFF; budget alerts ON; user explicitly enables the rest |
| Motivational quotes on aggressive schedule | Motivational quotes are the most likely to be perceived as spam; they have no time-sensitivity | Default OFF; user enables; max 1/day; configurable time |
| Non-dismissible or repeating alerts | Re-firing the same reminder every 30 minutes after dismissal is the fastest path to uninstall | Fire once per event; mark as acknowledged on open |
| Budget alert at 100% only (too late) | Seeing "You exceeded your budget" is worse UX than "You're at 80%" because nothing can be done | Alert at 80% (warning) + 100% (exceeded); distinct notification text |
| No way to snooze task reminders | Sometimes users see a reminder and aren't ready; snooze is a standard expectation | Implement snooze action on notification (15 min, 1 hour, tomorrow) |
| Daily briefing at wrong time | A daily briefing at 3pm is useless; users expect it in the morning | Default daily briefing at 8:00 AM; user-configurable time |
| Notification for every completed goal milestone (spam) | Progress notifications every 10% feel like achievement badge spam | Fire only at meaningful milestones: 25%, 50%, 75%, 100% |

---

## Data / Privacy

### Table Stakes
**Confidence: HIGH** (verified via privacy-focused app research, Actual Budget, cognitofi.com privacy rankings, growing local-first movement in 2025)

| Feature | Why Non-Negotiable | Notes for AGENDA |
|---|---|---|
| All data local, no cloud | Growing user demand; privacy breaches in finance apps (2025) made this a selling point, not a limitation | Covered — core architecture |
| No account required | Friction elimination; users expect to open and use immediately | Covered |
| JSON export | Machine-readable full backup; restoration must be lossless | Covered |
| CSV export | Human-readable; usable in spreadsheets; most-requested export format | Covered |
| Import from backup | Export without import is useless; round-trip must be verified | Covered |
| App lock (PIN) | Finance data on a shared device needs protection; YNAB, BNAB, Wallet all offer this | Covered |
| Biometric unlock (fingerprint/Face ID) | PIN alone is friction; biometrics are now expected alongside PIN | **Not explicitly listed — should add as preferred method** |
| No analytics / telemetry | Privacy-first positioning is undermined by silent data collection | Covered per constraints |
| Clear privacy communication at onboarding | Users need explicit "your data never leaves this device" message to build trust | Should be in onboarding UI |

---

## Competitive Landscape

**Confidence: MEDIUM** — based on 2025 review aggregations, app store data, and comparative analyses. Not from direct product access.

### Todoist
**Does well:** Natural language task input, recurring tasks (industry-leading), cross-platform, Wear OS/Apple Watch support, minimal UI, fast task capture.
**Misses:** No finance module, no Eisenhower Matrix or 1-3-5 views (only labels/filters approximate it), many GTD features behind paywall, no local-only mode, no PT-BR focus.
**AGENDA advantage:** Explicit productivity frameworks + finance + local-only privacy.

### Notion
**Does well:** Extreme flexibility, templates, wiki-style knowledge base, custom databases.
**Misses:** "Flexibility becomes burden" — users spend more time configuring than doing. No native task completion loop (no checkbox-first UX). Poor notification system. Not suitable for quick daily task management. No finance module.
**AGENDA advantage:** Opinionated defaults, structured frameworks, finance integration, offline-first.

### YNAB (You Need A Budget)
**Does well:** Zero-based budgeting philosophy, strong behavior-change framing, clear budget-to-goal mapping, iOS/Android parity.
**Misses:** Steep learning curve, $14.99/month cost (major churn driver), no forecasting/future income modeling, single currency, no task management, requires account + internet.
**AGENDA advantage:** Free, local, no account, debt tracking with directionality (owe vs. owed), combined task context.

### Wallet by BudgetBakers
**Does well:** 4.5+ stars on 340K+ Play Store reviews, bank sync, multi-currency, custom savings goals, clean charts.
**Misses:** "Too many options" complaint is common, bank sync failures are the #1 negative review topic, requires account, no task management.
**AGENDA advantage:** No bank sync complexity, local privacy, task + finance unified, simpler UX target.

### Brisqi / Super Productivity (local-first niche)
**Does well:** Privacy-first users actively seek these; no-account offline apps have dedicated communities.
**Misses:** Finance features absent, PT-BR not supported, limited notification systems.
**AGENDA advantage:** Broader feature set covering both productivity and finance for same privacy-conscious user.

### The Gap AGENDA Fills
No mainstream app in 2025 combines:
1. Structured productivity frameworks (Eisenhower + 1-3-5 + GTD) with full implementation
2. Personal finance tracking (income/expenses/budgets/goals/debts/recurring)
3. Local-only privacy with no cloud dependency
4. Native mobile notifications (including daily briefing + budget alerts)
5. PT-BR language support

The closest competitors (Notion for flexibility, YNAB for finance, Todoist for tasks) all require cloud accounts, charge subscriptions, and cover only one domain. AGENDA's bet is that the combination — not any individual feature — is the differentiator.

---

## Feature Gaps Identified During Research

The following features are standard expectations in 2025 that are not explicitly listed in PROJECT.md. They do not require new infrastructure but should be confirmed as in-scope:

| Gap | Category | Priority | Rationale |
|---|---|---|---|
| Search across tasks | Task Management | High | Universal expectation; users abandon apps without it |
| Biometric app unlock (fingerprint/Face ID) | Data/Privacy | High | PIN alone is friction; biometrics now expected alongside PIN in finance apps |
| Spending summary charts (monthly by category) | Finance | High | Most-requested finance visualization; bare minimum is a category breakdown |
| Undo on task delete (snackbar, 5s) | Task Management | Medium | Accidental delete without undo destroys trust |
| Snooze action on task reminder notifications | Notifications | Medium | Standard iOS/Android notification interaction expectation |
| Empty state designs with action prompts | UX | Medium | Empty charts and empty lists without guidance cause abandonment |
| Onboarding privacy statement ("data stays on device") | UX/Trust | Medium | Essential for local-first trust-building on first open |
| Budget rollover toggle per category | Finance | Low | YNAB gap that users consistently mention; differentiator |

---

## Sources

- Capterra: Task Management Mobile Apps Users Love — https://www.capterra.com/resources/task-management-mobile-apps/
- OctalSoftware: Task Management Software Development Features 2025 — https://www.octalsoftware.com/blog/task-management-software-development
- WildnetEdge: Personal Finance Apps — What Users Expect in 2025 — https://www.wildnetedge.com/blogs/personal-finance-apps-what-users-expect-in-2025
- NerdWallet: Best Budget Apps 2026 — https://www.nerdwallet.com/finance/learn/best-budget-apps
- NerdWallet: YNAB App Review 2025 — https://www.nerdwallet.com/finance/learn/ynab-app-review
- Fortune: YNAB Pros and Cons — https://fortune.com/article/ynab-pros-and-cons/
- Beebom: Wallet App by BudgetBakers Review — https://beebom.com/wallet-app-by-budgetbakers-review/
- UseMoion: Notion vs Todoist — https://www.usemotion.com/blog/notion-vs-todoist
- LeanCode: Offline Mobile App Design Best Practices — https://leancode.co/blog/offline-mobile-app-design
- Appbot: Push Notifications Best Practices 2026 — https://appbot.co/blog/app-push-notifications-2026-best-practices/
- Smashing Magazine: Design Guidelines for Better Notifications UX 2025 — https://www.smashingmagazine.com/2025/07/design-guidelines-better-notifications-ux/
- Cognitofi: Best Personal Finance Apps for Privacy 2026 — https://cognitofi.com/blog/best-personal-finance-apps-privacy-2026
- Super Productivity (privacy-first local task app) — https://super-productivity.com/use-cases/privacy-productivity/
- Brisqi (offline-first Kanban) — https://brisqi.com/
- GTD Forums: Eisenhower Matrix + GTD combined app demand — https://forum.gettingthingsdone.com/threads/looking-for-an-gtd-friendly-app-that-has-a-2d-urgency-vs-importance-eisenhower-matrix-view.15062/
- Onething Design: Budget App Design and Retention — https://www.onething.design/post/budget-app-design
- Eleken: Budget App Design Tips from Fintech UX Experts — https://www.eleken.co/blog-posts/budget-app-design
- BountisphereL State of Personal Finance Apps 2025 — https://bountisphere.com/blog/personal-finance-apps-2025-review
