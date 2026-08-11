# Contributing to AGENDA

Thanks for your interest. AGENDA is a personal project, but issues, ideas, and
pull requests are welcome.

By participating you agree to abide by our
[Code of Conduct](CODE_OF_CONDUCT.md).

## Ways to contribute

- **Report a bug** — [open an issue](https://github.com/lizzyman04/agenda/issues)
  with steps to reproduce, what you expected, and what happened. Device model
  and Android/iOS version help a lot.
- **Suggest a feature** — open an issue describing the problem you're trying to
  solve, not just the solution you have in mind.
- **Send a pull request** — see below.

## Non-negotiable constraints

Please read these before writing code. A PR that breaks one of them cannot be
merged, however good it otherwise is.

1. **No data leaves the device.** No analytics, no crash reporting, no cloud
   sync, no network client. Do not add `firebase_*`, `sentry_flutter`, `http`,
   `dio`, or `connectivity_plus`.
2. **The app is fully functional offline.** No feature may require an internet
   connection.
3. **The stack is decided.** Flutter + `isar_community` + BLoC/Cubit + GetIt.
   Do not introduce Riverpod, Provider, GetX, Hive, or Mockito.
4. **Mobile only.** Android and iOS. No web or desktop targets.
5. **Code in English, UI in PT-BR with an EN toggle.** All identifiers,
   comments, and commit messages in English; user-facing strings go through
   `l10n`.

## Architecture rules

1. No source file exceeds **150 lines**. Split by responsibility, not
   arbitrarily.
2. Nest aggressively by domain. No directory holds more than ~10 related files.
   Feature slices live at `presentation/<area>/<feature>/{screens,widgets}/`.
3. Every feature directory carries a `README.md` describing its responsibility,
   its contents, and any rules specific to it.
4. Screens own cubits; widgets do not. Widgets take domain objects and
   callbacks.
5. Sheets and dialogs own their controllers — a sheet body is a
   `StatefulWidget` that creates its `TextEditingController`s in its `State`,
   disposes them there, and returns a value via `Navigator.pop`. Never dispose
   controllers in the caller's method scope after `await showModalBottomSheet`;
   that crashes during the dismiss transition.
6. Respect the layering: `core → domain → data → infrastructure → application →
   presentation → config`. Inner layers never import outer ones. `domain/` is
   pure Dart — no Flutter, no Isar.

[`lib/presentation/finance/goals/`](lib/presentation/finance/goals/) is a
worked example of a compliant slice.

## Pull request process

1. Fork and branch from `main`. Do not commit directly to `main`.
2. Make your change, with tests.
3. Verify locally — all three must be clean:

   ```bash
   flutter analyze --no-fatal-infos
   flutter test --no-pub
   dart format --set-exit-if-changed lib test
   ```

4. Write [Conventional Commits](https://www.conventionalcommits.org/):
   `fix(finance): rebuild contributions list instead of mutating it`.
   Explain *why* in the body when it isn't obvious from the diff.
5. Open the PR describing the problem, the approach, and how you verified it.

## Testing expectations

- Bug fixes ship with a regression test. Confirm it **fails against the
  unfixed code** — a test that passes either way proves nothing.
- Cubits are tested with `bloc_test`, mocks with `mocktail`.
- Widget tests that involve an autofocused `TextField` must never call
  `pumpAndSettle` — the blinking cursor is a periodic timer that never settles
  and will hang the suite. Pump explicit durations instead, and unmount the
  tree at the end of the test.

## Code generation

Isar schemas and the DI graph are generated. After changing an `@collection`,
`@embedded`, or `@injectable` annotation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Commit the regenerated `*.g.dart` and `injection.config.dart` alongside your
change.

## Questions

Open a [discussion](https://github.com/lizzyman04/agenda/discussions) or email
**agenda@lizzyman04.com**.
