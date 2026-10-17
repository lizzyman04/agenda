---
status: testing
phase: 04-notifications-backup
source: [04-VERIFICATION.md]
started: 2026-10-17T05:26:48Z
updated: 2026-10-17T05:26:48Z
---

## Current Test

number: 1
name: iOS: confirm the Documents directory and the backups directory are excluded from iCloud/iTunes backup
expected: |
  On a device or simulator build, URLResourceValues.isExcludedFromBackup reads true for Documents and Documents/backups after launch, and a fresh import adds files that stay excluded
awaiting: user response

## Tests

### 1. iOS: confirm the Documents directory and the backups directory are excluded from iCloud/iTunes backup
expected: On a device or simulator build, URLResourceValues.isExcludedFromBackup reads true for Documents and Documents/backups after launch, and a fresh import adds files that stay excluded
result: [pending]

### 2. Android: build and launch the debug APK
expected: flutter build apk --debug completes (after accepting SDK licences); manifest merge and core-library desugaring succeed; the new MainActivity channel compiles; app launches with the task list unchanged
result: [pending]

### 3. Android and iOS: each reminder kind fires at the expected time
expected: Task due reminder (30 min lead), recurring task reminder, morning briefing, debt due, goal off-track, recurring payment and a budget alert at 80% and 100% each arrive; a quote notification arrives only after being enabled
result: [pending]

### 4. Reboot survival and swipe-kill
expected: Pending reminders still fire after a reboot and after the app is swiped away
result: [pending]

### 5. Quiet hours and time zone
expected: A reminder due at 23:00 is shown at 07:00; a budget alert raised at 23:00 is deferred to 07:00; changing the device time zone and reopening re-times reminders
result: [pending]

### 6. Permission flows including Open settings (WR-06, WR-07)
expected: A fresh install with an off-track goal shows no permission prompt at launch. Denying in the settings screen flips the banner button to Open settings; tapping it opens the app notification page (Android) or the app page in Settings (iOS); granting there and returning removes the banner. Exact-alarm banner upgrades scheduling mode on return
result: [pending]

### 7. File picker, scoped storage and picker cache
expected: JSON export and the six CSV exports save through the system dialog; picking a JSON or CSV files shows the confirmation screen with record counts and date range; more than 6 files or more than 50 MiB is rejected; a truncated file is rejected with data unchanged; the picker cache holds no copy afterwards
result: [pending]

### 8. Safety backups section on the Backup screen (WR-04)
expected: After an import the count shows 1; Save copy opens the system save dialog and the saved file imports back through Import; Delete asks for confirmation and the count returns to 0
result: [pending]

### 9. Android Auto Backup is off
expected: adb shell dumpsys backup shows the app is not eligible for backup
result: [pending]

### 10. iOS: more than 64 pending items and notification tap routing
expected: No crash above 64 pending reminders, the settings page shows the waiting count, tapping a delivered notification routes to the right screen
result: [pending]

## Summary

total: 10
passed: 0
issues: 0
pending: 10
skipped: 0
blocked: 0

## Gaps
