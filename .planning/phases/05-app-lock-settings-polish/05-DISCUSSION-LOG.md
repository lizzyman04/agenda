# Phase 5: App Lock + Settings + Polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-16
**Phase:** 05-app-lock-settings-polish
**Areas discussed:** Lock timing, PIN and biometrics, Settings screen, Privacy statement

---

## Lock timing

| Question | Options | Selected |
|----------|---------|----------|
| Lock on resume from background? | After timeout / Always immediately / Cold start only | After timeout |
| Default timeout, configurable? | 1 min configurable / Immediate configurable / Fixed 1 min | 1 min configurable |
| Lock after app-initiated file picker / permission dialog? | Don't lock / Lock normally | Don't lock |
| Hide content in app switcher? | Only with PIN (+FLAG_SECURE) / Always / Overlay without FLAG_SECURE | Only with PIN |

## PIN and biometrics

| Question | Options | Selected |
|----------|---------|----------|
| PIN length | 4 / 6 / user chooses | 4 |
| Forgot PIN | Device credential resets / Wipe data / No recovery | Device credential resets |
| Wrong attempts | Escalating cooldown / No limit / Wipe after 10 | Escalating cooldown |
| Biometric prompt | Auto + toggle / Button only | Auto + toggle |

## Settings screen

| Question | Options | Selected |
|----------|---------|----------|
| Entry point | AppBar gear / Shell tab / Drawer | AppBar gear |
| Layout | Sectioned list / All inline | Sectioned list |
| Language | 2 options / + follow system | 2 options |
| Dark theme | Defer / Include | Defer |

## Privacy statement

| Question | Options | Selected |
|----------|---------|----------|
| First-launch content | 1 screen privacy + language / privacy only / 2-3 pages | 1 screen privacy + language |
| Bullets (multi) | Offline/no account, No tracking, Backup is yours, Optional PIN | All four |
| Re-readable | Settings > About / No | Settings > About |

## Claude's Discretion

Lock screen widget choice, PIN hashing, lock gate placement, no-device-credential fallback, polish scope.

## Deferred Ideas

Dark theme; follow-system language; multi-page onboarding.
