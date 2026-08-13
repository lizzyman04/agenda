---
status: awaiting_human_verify
trigger: "Phase 03 (finance-core) open UAT issue: app-wide undo-timer defect — 5s SnackBars never auto-dismiss (reconfirmed on device 2026-08-12: delete snackbar still on screen after 12s). Reproduces on a physical Infinix X6831, Android 13."
created: 2026-08-13T00:00:00.000Z
updated: 2026-08-13T12:00:00.000Z
---

## Current Focus
<!-- OVERWRITE on each update - always reflects NOW -->

hypothesis: "Flutter 3.41's `SnackBar.persist` field defaults to `action != null` (snack_bar.dart:303). All three undo SnackBars pass a SnackBarAction, so persist==true, so ScaffoldMessengerState's auto-dismiss Timer (scaffold.dart:619-626) fires on schedule but returns early at the `if (snackBar.persist) return;` guard instead of calling hideCurrentSnackBar. The SnackBar therefore stays on screen forever. This is a framework default, not a device/OEM timer problem."
test: "Widget test on host with a controllable clock: show a SnackBar with duration 5s AND a SnackBarAction, pump 6s, assert it is gone. Expected to FAIL on current Flutter."
expecting: "If the test fails (SnackBar still found after 6s) the framework default is confirmed and the device is exonerated. If it passes, persist is not the cause and investigation returns to the ScaffoldMessenger ticker/route-isCurrent guard."
next_action: "DONE and committed — `persist: false` applied at all three call sites with three real-screen regression tests. REMAINING: on-device re-test, deferred because no device was attached at fix time (`adb devices` empty on 2026-08-13). When the Infinix X6831 is reattached, run: (a) swipe-delete in Financas and in Tarefas, plus task-detail delete-confirm — each SnackBar must vanish on its own at ~5s; (b) delete a task, wait past 5s WITHOUT touching the screen, force-stop the app, relaunch — the task must stay deleted. Step (b) is the one that settles symptom 2. Do not move this file to resolved/ until (a) and (b) both pass on hardware."
reasoning_checkpoint:
  hypothesis: "Flutter 3.41's `SnackBar.persist` defaults to `action != null`. Because all three undo SnackBars pass a SnackBarAction and never set persist explicitly, ScaffoldMessenger's auto-dismiss timer fires on time but early-returns at `if (snackBar.persist) return;` instead of hiding — so the SnackBar stays up indefinitely."
  confirming_evidence:
    - "snack_bar.dart:303 — `persist = persist ?? action != null;` (direct source read of the pinned SDK at /home/lizzyman04/snap/flutter/common/flutter, Flutter 3.41.4)."
    - "scaffold.dart:619-626 — the timer callback's first statement is `if (snackBar.persist) { return; }`, which pre-empts `hideCurrentSnackBar(reason: SnackBarClosedReason.timeout)`."
    - "Host widget test reproduced the defect with NO device involved: SnackBar(duration: 5s, action: SnackBarAction(...)) is still found after `tester.pump(Duration(seconds: 6))`; the identical SnackBar with `persist: false` is gone at 6s. This is a deterministic host repro, so Transsion/XOS power management is definitively not the cause."
    - "Exactly 3 of the 11 showSnackBar call sites in lib/ pass an action, and they are precisely the 3 undo SnackBars that were reported stuck; the other 8 action-less ones were never reported stuck. Blast radius matches the persist rule exactly."
  falsification_test: "Adding `persist: false` while changing nothing else must make the SnackBar disappear at 5s. If it still hangs, persist is not the cause. (Run and confirmed: the persist:false probe passes.)"
  fix_rationale: "Sets the field the framework actually reads. `persist: false` restores the pre-3.41 auto-dismiss contract that AppConstants.undoSnackbarDuration was written against, at the three call sites that intend a timed undo window. It changes no timer, no cubit, and no Isar behaviour — it removes an unintended framework default rather than papering over a symptom."
  blind_spots: "Symptom two (deleted task reappearing after restart) is NOT reproduced or directly explained by this fix; it is explained by elimination (ItemDao.restoreItem is the only code path that clears deletedAt, and it is reachable only from the undo action) plus the inference that a permanently-visible Desfazer button above the NavigationBar catches stray taps. That inference is unverified. Device re-test must specifically re-check delete-then-restart. RESOLVED since writing: the `persist` argument is available on every SDK the project allows — it landed in Flutter 3.38.0 (commit 264223d9879, `git tag --contains` → 3.38.0) and pubspec.yaml pins `flutter: '>=3.38.1'`, so there is no compile risk on the low end of the constraint."
tdd_checkpoint: null

## Symptoms
<!-- Written during gathering, then immutable -->

expected: "The 5-second undo window expires on its own: the undo SnackBar auto-dismisses and the pending soft delete commits. AppConstants.undoSnackbarDuration = Duration(seconds: 5)."
actual: "Undo SnackBars never auto-dismiss. Fresh app, single swipe-delete: the SnackBar was still on screen at 16s in one run, ~5 minutes in another, and 12s on the 2026-08-12 re-test. Additionally, after deleting a task and restarting the app, the deleted task reappeared — suggesting the TaskListCubit Timer(5s) that commits the soft delete never fired either."
errors: "None. No exception, no red screen, nothing in logcat — silent failure."
reproduction: "Swipe-delete any item, then wait. Reproduces on BOTH Financas (transaction_list_screen.dart:47) and Tarefas (task_list_screen.dart:108) — app-wide, not finance-specific. Physical Infinix X6831 (Transsion XOS), Android 13, arm64-v8a, debug build. Reproduced across multiple sessions on 2026-08-11 and 2026-08-12."
started: "Present since Phase 03 UAT (2026-08-11). Never observed working on this device. Not known whether it reproduces on any other device or emulator — that comparison has never been run."

## Eliminated
<!-- APPEND only - prevents re-investigating after /clear -->

- hypothesis: "Flutter suppresses the SnackBar auto-dismiss timer when MediaQuery.accessibleNavigation is true (documented behaviour)."
  evidence: "`adb shell dumpsys accessibility` on the device reports touchExplorationEnabled=false. Only a JacyBOT USSD service is bound (capabilities=33), with no touch exploration. accessibleNavigation should therefore be false."
  timestamp: 2026-08-11

- hypothesis: "Device animator/transition duration scales are set to a large multiplier, stretching the SnackBar timeout."
  evidence: "Window animation scale and transition animation scale both read 1.0 on the device."
  timestamp: 2026-08-11

- hypothesis: "A global `timeDilation` (package:flutter/scheduler.dart) was left enabled in app code, slowing every timer."
  evidence: "`grep -rn timeDilation lib/ test/` returns zero matches. `package:flutter/scheduler.dart` is not imported anywhere in lib/. No manual `MediaQuery(` override wraps the app either."
  timestamp: 2026-08-13

## Evidence
<!-- APPEND only - facts discovered during investigation -->

- timestamp: 2026-08-11
  checked: "AppConstants.undoSnackbarDuration"
  found: "app_constants.dart:6 — `static const Duration undoSnackbarDuration = Duration(seconds: 5);`. The constant itself is correct."
  implication: "The declared duration is not the bug. Something downstream ignores or outlives it."

- timestamp: 2026-08-11
  checked: "Scope of the defect across features"
  found: "Reproduces on transaction_list_screen.dart:47 (Financas) and task_list_screen.dart:108 (Tarefas). task_detail_screen.dart:45 uses the same constant."
  implication: "App-wide, so the cause is shared infrastructure (MaterialApp/ScaffoldMessenger/event loop), not per-screen logic."

- timestamp: 2026-08-11
  checked: "Task soft-delete persistence after app restart"
  found: "A deleted task returned after restarting the app, implying the Timer at task_list_cubit.dart:68 that commits the soft delete never ran."
  implication: "Strongly suggests the failure is at the Dart Timer layer, not only the SnackBar widget layer. This is the highest-value signal — the two layers are independent, and this one has nothing to do with Flutter's SnackBar code."

- timestamp: 2026-08-12
  checked: "On-device re-test during Phase 06 UAT"
  found: "Delete SnackBar still on screen after 12 seconds against a 5s duration. Defect confirmed still live on current main."
  implication: "Not fixed incidentally by the Phase 06 refactor; still open."

- timestamp: 2026-08-13
  checked: "grep for timeDilation / scheduler.dart / MediaQuery( / accessibleNavigation across lib/ and test/"
  found: "Zero matches for all four."
  implication: "No app-level global animation or media-query override exists. Eliminates the 'test hook left enabled' suspect entirely."

- timestamp: 2026-08-13
  checked: "Flutter SDK source for the SnackBar auto-dismiss timer — /home/lizzyman04/snap/flutter/common/flutter/packages/flutter/lib/src/material/scaffold.dart (Flutter 3.41.4, Dart 3.11.1)"
  found: "ScaffoldMessengerState.build() lines 614-629 creates the auto-dismiss timer unconditionally (no accessibleNavigation guard in this version). The timer callback at lines 619-626 is: `_snackBarTimer = Timer(snackBar.duration, () { assert(...); if (snackBar.persist) { return; } hideCurrentSnackBar(reason: SnackBarClosedReason.timeout); });` — an early return on `snackBar.persist` BEFORE the hide call."
  implication: "The Timer DOES fire. It simply declines to hide the SnackBar when persist is true. The entire 'timers do not fire on this device' framing was wrong."

- timestamp: 2026-08-13
  checked: "SnackBar.persist default — snack_bar.dart:275-303 and its doc comment at lines 461-470"
  found: "The constructor initializer is `persist = persist ?? action != null;`. Doc: 'If true, the snack bar remains visible even after the timeout, until the user taps the action button or the close icon. If not provided, but the snackbar action is not null, the snackbar will persist as well.'"
  implication: "ROOT CAUSE. Any SnackBar with a SnackBarAction and no explicit `persist:` never auto-dismisses. All three undo SnackBars pass a SnackBarAction."

- timestamp: 2026-08-13
  checked: "Every showSnackBar call site in lib/ (11 total) for the presence of a SnackBarAction"
  found: "Exactly three carry an action: task_list_screen.dart:106-117, task_detail_screen.dart:43-54, transaction_list_screen.dart:44-54 — all three are the undo SnackBars. The other eight (goal_form_screen, debt_form_screen, recurring_payment_form_pickers, transaction_form_pickers, add_subtask_sheet, gtd_filter_screen, gtd_guide_sheet, task_form_save_feedback) are action-less feedback SnackBars."
  implication: "Explains the observed blast radius exactly: the defect is app-wide across Tarefas AND Finanças, yet ONLY undo SnackBars were ever reported stuck. Non-undo SnackBars get persist=false and dismiss normally. A device-level timer-throttling cause would have hit all eleven indiscriminately."

- timestamp: 2026-08-13
  checked: "Whether the TaskListCubit undo Timer actually commits the soft delete — task_list_cubit.dart:53-71, item_repository_impl.dart:106-122, item_dao.dart:95-102"
  found: "softDelete() AWAITS `_repository.softDelete(id)` (which runs an Isar writeTxn setting `model.deletedAt = DateTime.now()` and puts it) BEFORE it emits TaskListWithPendingUndo and BEFORE `_undoTimer` is even created. The timer callback body is only `await _reload()` — it commits nothing. The cubit's own docstring says so: 'item stays soft-deleted in Isar whether or not the undo window is used.'"
  implication: "The second symptom (deleted task reappears after restart) CANNOT be caused by the undo timer failing to fire. The UAT note 'suggesting the Timer(5s) commit never fired' was an invalid inference. These are two independent issues, not one."

- timestamp: 2026-08-13
  checked: "Every read path that could resurface a soft-deleted item — item_dao.dart:22-88 and item_query_builder.dart:32-70"
  found: "buildItemFilterQuery starts with `.filter().deletedAtIsNull()` before any optional clause; findByType, findSubtasks, searchByTitle, countSubtasks, countCompletedSubtasks, findDistinctGtdContexts all apply .deletedAtIsNull(). The only code path in the whole app that clears deletedAt is ItemDao.restoreItem, reachable solely from TaskListCubit.restoreItem, reachable solely from the undo SnackBarAction's onPressed."
  implication: "A soft-deleted task can only reappear if the undo action was invoked. Because the undo SnackBar never dismisses (root cause above), its 'Desfazer' button sits permanently at the bottom of the screen directly above the NavigationBar — so a later tap intended for a bottom-nav destination lands on Desfazer and silently restores the task. Symptom two is a downstream consequence of symptom one, and fixing the persist default removes the only reachable restore path outside the intended 5s window."

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: "Flutter 3.38.0 shipped the breaking change 'SnackBar with action no longer auto-dismisses' (flutter/flutter#173084, commit 264223d9879, 2025-08-26). `SnackBar`'s constructor now initialises `persist = persist ?? action != null` (snack_bar.dart:303), and `ScaffoldMessengerState.build` creates its timeout timer with an early return — `if (snackBar.persist) { return; }` — before `hideCurrentSnackBar(reason: SnackBarClosedReason.timeout)` (scaffold.dart:619-626). All three of AGENDA's undo SnackBars pass a `SnackBarAction` and never set `persist`, so they opted in to persist-forever by default: the timer fires exactly on time and then declines to hide anything. pubspec.yaml requires `flutter: '>=3.38.1'`, i.e. the project has never run on a version without this behaviour, which is why the undo SnackBar was never once observed working. The device, Transsion XOS power management, accessibleNavigation, animation scales and the Dart event loop were all innocent — the defect reproduces deterministically in `flutter test` on the host with no device attached. The second symptom (deleted task reappearing after restart) is a SEPARATE, downstream issue, not a timer failure: TaskListCubit.softDelete awaits the Isar write before the timer is even created and the timer body only calls _reload(), so nothing about persistence depends on it. ItemDao.restoreItem is the only code path in the app that clears deletedAt, and it is reachable only from the undo SnackBarAction — which, thanks to the root cause, sat permanently at the bottom of the screen directly above the NavigationBar, where a tap aimed at a nav destination lands on 'Desfazer'."
fix: "Added an explicit `persist: false` to the three undo SnackBars (the official migration for this breaking change), restoring the auto-dismiss contract that AppConstants.undoSnackbarDuration was written against. No timer, cubit, repository or Isar code was touched."
verification: "Red/green proven on the host with a controllable clock. New suite test/presentation/undo_snackbar_auto_dismiss_test.dart drives the three real screens (TaskListScreen via a TaskListWithPendingUndo emission, TransactionListScreen via an actual Dismissible swipe, TaskDetailScreen via the confirm-delete dialog on a pushed route), asserts the SnackBar is visible immediately, pumps undoSnackbarDuration + 1s, and asserts it is gone. All 3 FAIL against the pre-fix code (verified by stashing lib/ and re-running: 0 passed / 3 failed) and all 3 PASS with the fix. Full local gate: `dart run tool/check_architecture.dart` PASS (exit 0), `flutter analyze --no-fatal-infos --fatal-warnings` exit 0 with 65 infos (baseline 65 — held; three new infos introduced by the test file were fixed rather than absorbed), `flutter test --no-pub` 268/268 passing (baseline 265 + 3 new). No regression."
files_changed:
  - "lib/presentation/tasks/screens/task_list_screen.dart — persist: false on the undo SnackBar"
  - "lib/presentation/tasks/screens/task_detail_screen.dart — persist: false on the undo SnackBar"
  - "lib/presentation/finance/screens/transaction_list_screen.dart — persist: false on the undo SnackBar"
  - "test/presentation/undo_snackbar_auto_dismiss_test.dart — new 3-test regression suite"
