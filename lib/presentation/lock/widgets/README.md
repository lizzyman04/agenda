# presentation/lock/widgets

The lock layer mounted in `MaterialApp.builder`.

## Responsibility

Stack the lock screen above the app Navigator while locked, hide the app
from paint, hit-testing and screen readers, and fade the lock out on unlock.

## Files

| File | Lines | Role |
|------|------:|------|
| `lock_gate.dart` | 131 | `LockGate` — `BlocBuilder<AppLockCubit>` → `Stack(fit: expand)` of `Offstage(TickerMode(child))` and the lock layer. The lock layer is its own `Navigator` (in `HeroControllerScope.none`) whose only route is `LockScreen`; it appears instantly on lock (and unfocuses the primary focus) and fades out over 150 ms on unlock (`lockFadeKey`), instantly when `MediaQuery.disableAnimationsOf` is true. While fading it ignores pointers and is excluded from semantics |

## Conventions in this slice

- **Same-frame reveal.** The app is onstage in the frame the cubit emits
  unlocked; only the lock layer animates.
- **Back is not intercepted** (RESEARCH Pitfall 12): the lock layer is not a
  route, so the app Navigator's pop never removes it.

## Upstream dependencies

`application/lock/` (`AppLockCubit`, `AppLockState`) · `../screens/`.
