# Phase 05 — UI Review

**Audited:** 2026-11-17
**Baseline:** 05-UI-SPEC.md (approved 2026-11-16)
**Screenshots:** not captured (Flutter mobile app, no dev server; code-only audit)
**Interaction captures:** off (workflow.ui_interaction_capture is false)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | All phase surfaces use contract ARB keys. The only hardcoded strings are outside this phase's scope. |
| 2. Visuals | 2/4 | Matches the contract to the pixel, but the contract itself produces flat, generic surfaces (grey 72dp outline icon empty state, monochrome lock screen) |
| 3. Color | 3/4 | Accent use is exactly the 6 declared elements, with no hardcoded colors. The 10% accent share is close to 0% on Settings and the empty states. |
| 4. Typography | 3/4 | Only TextTheme roles, no fontSize/FontWeight. Settings section headers (titleMedium 16/500) barely differ from tile titles (bodyLarge 16/400). |
| 5. Spacing | 4/4 | Every gap matches the spec scale (48/24/16/8, 72dp keys, 24 col / 16 row, 16dp dots, 40dp status slot) |
| 6. Experience Design | 3/4 | Cooldown, live region, reduced motion, 150 ms unlock fade and destructive confirm are all present. There are minor gaps in busy and disabled feedback. |

**Overall: 19/24**

---

## Top 3 Priority Fixes

1. **Empty states look dated (shared `AppEmptyState`).** This is WARNING-level and affects many screens. The bare grey `Icons.check_box_outline_blank` at 72dp, plus a heading and a hug-width FilledButton, gives the first screen a new user sees no focal point and no brand. Fix: put the icon inside a 112dp `cs.primaryContainer` circle (icon `cs.onPrimaryContainer`, size 48), raise the heading to `titleLarge`, and make the CTA `FilledButton.icon(Icons.add)`. Every Finance, Task and GTD empty state gets the fix at once (lib/presentation/shared/widgets/app_empty_state.dart:49-69).
2. **The theme in `lib/app.dart:73-74` is the bare `ColorScheme.fromSeed(deepPurple)`.** This is WARNING-level and is the root cause of the "dated" feel across the app. There are no component themes for AppBar, ListTile, cards, FilledButton shape or input decoration, and no dark theme. Fix: set up a design pass (new UI-SPEC) that adds `AppBarTheme(centerTitle:false, scrolledUnderElevation)`, `ListTileTheme(iconColor: cs.primary)`, a FilledButton shape and a custom seed, and adds `darkTheme`. Phase 05 was correctly told not to change the theme, so this is follow-up work.
3. **Weak hierarchy in Settings.** This is WARNING-level. `SettingsSectionHeader` (settings_section_header.dart:15) uses `titleMedium` in `cs.onSurface`, which differs from row titles only in weight (500 vs 400). The 5 sections also have no dividers, so the list reads as one undifferentiated column. Fix: use `labelLarge` with `cs.primary` for headers, which is the M3 settings convention (this needs a spec amendment, since the current spec forbids primary here), or add a `Divider(height: 1)` between sections.

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)
- Lock, PIN setup, privacy statement, Settings and the empty states all resolve through `AppLocalizations`. A grep for literal `Text('...')` under lock/, settings/, onboarding/ and shared/ returned nothing.
- The empty-state copy matches the contract: `noTasks`/`tasksEmptyBody`/`tasksEmptyCta`, and search shows `tasksSearchEmptyBody(query)` (task_list_view.dart:29-41).
- Cross-app (out of scope, WARNING): `gtd_text_node.dart:57 'Próximo →'` and `finance_link_sheet.dart:66 'Sem vínculo'` are hardcoded PT. The redesign audit lists about 45 more.

### Pillar 2: Visuals (2/4)
- The implementation follows the contract (lock_screen.dart:98-140 maps 1:1 to the spec table). The score reflects how the result looks, not missed requirements.
- WARNING: the lock screen is entirely `surface` + `onSurfaceVariant` + `surfaceContainerHighest` keys. Nothing marks it as AGENDA. Consider a `primaryContainer` icon badge in place of the plain grey 48dp lock icon.
- WARNING: `AppEmptyState` has no container, illustration or tint (see Fix 1). It is the single most visible piece of visual debt, because every list screen uses it.
- WARNING: the PIN setup screen has no visual cue for the step (create / confirm). Only the title text cross-fades. A "Step 1 of 2" caption or a progress indicator would help orientation.
- Icon-only controls are labelled: backspace and biometric keys have tooltips, and the gear has a tooltip (`settingsTitle`).

### Pillar 3: Color (3/4)
- `cs.primary` appears only on PIN dots (pin_dots.dart:121), the biometric key, the shield hero (privacy_statement_screen.dart:79), the Get Started button, and the Switch/Radio defaults. This matches the contract exactly.
- `cs.error` is limited to the error dots, the status line errors and the disable dialog confirm. Cooldown correctly uses `onSurfaceVariant`.
- There are no hex values and no `Colors.*` except the theme seed and `Colors.transparent`.
- WARNING: the effective accent share on Settings is about 0% (a switch thumb only). The screen is all neutral, which adds to the "dated" impression.
- Minor: `KeypadIconKey` disables at `color.withValues(alpha: .38)` of `onSurfaceVariant` (keypad_key.dart:112). The spec's M3 convention is `onSurface` at 38%. This is a small visual mismatch with the disabled digit keys.

### Pillar 4: Typography (3/4)
- No `fontSize` or `FontWeight` appears in phase files. Roles used: headlineMedium (digits), headlineSmall (titles), titleMedium, bodyLarge and bodyMedium. Two weights (400/500), as contracted.
- WARNING: section header vs row title contrast is too low (Fix 3).
- WARNING: the empty-state heading is `titleMedium`, the same size as body text in the rest of the list. Hierarchy relies on weight alone.

### Pillar 5: Spacing (4/4)
- Lock column: 48 / 16 / 8 / 40 (status) / 24 / 48 / keypad / 24 / 32. Keypad: 72dp keys, column gap 24, row gap 16 (pin_keypad.dart:43-58). Dots: 16dp, gap 16, 2dp outline.
- Privacy: horizontal 24, gaps 48/24/8/32/16/24, button inset `fromLTRB(24,16,24,24)`, 48dp minimum height.
- Settings header `fromLTRB(16,16,16,4)` and bottom `SizedBox(32)`. The empty state uses 32 horizontal padding with 16/8/24 gaps.
- No off-scale values found.

### Pillar 6: Experience Design (3/4)
- Present: escalating cooldown with keys disabled, `Semantics(liveRegion)` status line, dots announced as one label, shake skipped under `disableAnimations`, unlock `FadeTransition` 150 ms (lock_gate.dart:84,123), `PopScope(canPop:false)`, the switch never flipping optimistically, the disable confirm dialog plus current PIN, and a double-tap guard on Get Started.
- WARNING: `_GetStartedButton` (privacy_statement_screen.dart:126-130) only disables while busy, with no progress indicator. A slow flag write looks like a dead button.
- WARNING: the backspace key's long-press-to-clear has no affordance or semantics hint (keypad_key.dart:105-108). Screen-reader users won't discover it.
- Minor: the lock screen content height (about 700dp) needs to scroll on short or landscape devices. It does not overflow (SingleChildScrollView), but the keypad can sit below the fold.
- The task-list empty state CTA is wired to the same create flow as the FAB. The search-empty state correctly omits a CTA.

---

## Cross-app recommendations (not graded)
- Theme modernization and dark theme (`lib/app.dart`), and an `AppEmptyState` redesign. Both should go through a dedicated UI-SPEC phase.
- Finish i18n for the ~45 hardcoded strings and raw enum names in task chips (task_card.dart:76,99).

Registry audit: not applicable (Flutter, no shadcn).

---

## Files Audited
- lib/app.dart
- lib/presentation/lock/keypad/{keypad_key,pin_dots,pin_keypad,biometric_key,lock_status_line}.dart
- lib/presentation/lock/screens/{lock_screen,pin_setup_screen,forgot_pin_button,forgot_pin_dialog}.dart
- lib/presentation/lock/widgets/{lock_gate,privacy_overlay}.dart
- lib/presentation/onboarding/screens/privacy_statement_screen.dart, widgets/privacy_bullet.dart
- lib/presentation/settings/screens/settings_screen.dart, security/*.dart, widgets/*.dart
- lib/presentation/shared/widgets/app_empty_state.dart
- lib/presentation/tasks/widgets/task_list_view.dart, screens/gtd_filter_screen.dart
