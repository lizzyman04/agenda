# Security Policy

## Threat model

AGENDA is an offline, local-first mobile app. It has no backend, no user
accounts, and makes no network requests, so server-side and transport-layer
attack surface does not exist.

What *is* in scope:

- Anything that could expose on-device data (the Isar database, exported
  backups, CSV exports) to another app or user
- Weaknesses in the app lock — PIN storage, biometric bypass
- Data leaking off the device through any channel, since that would break the
  project's core guarantee
- Insecure handling of imported files

Out of scope:

- Attacks requiring a rooted or jailbroken device, or physical access with an
  unlocked screen
- Vulnerabilities in Flutter, Isar, or other third-party dependencies — please
  report those upstream, though a heads-up here is appreciated

## Supported versions

The project is pre-1.0. Only the latest `main` receives fixes.

## Reporting a vulnerability

**Please do not open a public issue for a security problem.**

Report privately via either:

- [GitHub private vulnerability reporting](https://github.com/lizzyman04/agenda/security/advisories/new)
- Email **agenda@lizzyman04.com**

Please include:

- A description of the issue and why you believe it is a security problem
- Steps to reproduce, ideally with a minimal case
- Affected version or commit, plus device and OS version
- Any suggested mitigation

## What to expect

- Acknowledgement within **7 days**
- An initial assessment, with severity and a rough fix timeline, within
  **14 days**
- Credit in the release notes when a report leads to a fix, unless you prefer
  to remain anonymous

This is a personal project maintained in spare time — timelines are
best-effort, and thanks in advance for your patience.
