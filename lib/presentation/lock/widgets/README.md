# presentation/lock/widgets

The lock layer mounted in `MaterialApp.builder`.

## Responsibility

Stack the lock screen above the app Navigator while locked, hide the app
from paint, hit-testing and screen readers, and fade the lock out on unlock.
Forward app-lifecycle changes to `AppLockCubit` and paint the privacy
overlay above everything while the app is not in the foreground.

## Files

| File | Lines | Role |
|------|------:|------|
| `lock_gate.dart` | 149 | `LockGate` (stateful) — owns an `AppLifecycleListener` forwarding `onInactive` / `onHide` / `onResume` to `AppLockCubit`; `BlocBuilder<AppLockCubit>` → `Stack(fit: expand)` of, bottom to top, `Offstage(TickerMode(child))`, the lock layer and `PrivacyOverlay` (while `obscured`). The lock layer is its own `Navigator` (in `HeroControllerScope.none`) whose only route is `LockScreen`; it appears instantly on lock (and unfocuses the primary focus, closing a soft keyboard opened behind it) and fades out over 150 ms on unlock (`lockFadeKey`), instantly when `MediaQuery.disableAnimationsOf` is true. While fading it ignores pointers and is excluded from semantics |
| `privacy_overlay.dart` | 38 | `PrivacyOverlay` — full-bleed `ColoredBox(cs.surface)` with `Icons.lock_outline` (64, `onSurfaceVariant`), gap 16 and `l10n.appName` in `titleMedium`; no motion (D-04) |

## Conventions in this slice

- **Same-frame reveal.** The app is onstage in the frame the cubit emits
  unlocked; only the lock layer animates.
- **Overlay on `inactive`.** Frames stop at `hidden`, so the overlay must
  be painted on `inactive` (RESEARCH Pattern 3). On resume the overlay is
  replaced by the lock screen in one state change: no content frame.
- **Back is not intercepted** (RESEARCH Pitfall 12): the lock layer is not a
  route, so the app Navigator's pop never removes it.

## Upstream dependencies

`application/lock/` (`AppLockCubit`, `AppLockState`) · `../screens/`.
