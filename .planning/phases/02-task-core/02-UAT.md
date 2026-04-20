---
status: complete
phase: 02-task-core
source: 02-01-SUMMARY.md, 02-02-SUMMARY.md, 02-03-SUMMARY.md, 02-04-SUMMARY.md, 02-05-SUMMARY.md
started: 2026-04-19T00:00:00Z
updated: 2026-04-19T00:01:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test
expected: Kill any running Flutter process. Run `flutter run` from the project root on a connected device or emulator. The app boots without errors, Isar schema v2 opens (ItemModel registered), DI initializes with no GetIt exceptions, MigrationRunner runs case 2 silently, and the app shell renders on screen without crash.
result: pass

### 2. Task List Screen — Empty State
expected: Navigate to the task list. With no tasks created yet, you see an empty state message (not a crash, not a blank white screen). The FAB (add button) is visible.
result: pass

### 3. Create a Task
expected: Tap the FAB on the task list. The task form opens. Fill in a title (e.g., "Buy groceries"), choose a priority, set a due date. Tap Save. The form closes and the task appears in the task list.
result: pass

### 4. Edit a Task
expected: Tap an existing task in the list. The task form opens pre-filled with the existing values (title, priority, due date, etc.). Change the title to something new. Save. The updated title is visible in the task list.
result: pass

### 5. Delete a Task with Undo
expected: Tap the delete icon on a task card. The task disappears from the list immediately. A Snackbar appears at the bottom with an Undo button and a countdown (5 seconds). Tapping "Desfazer" (Undo) restores the task to the list.
result: pass

### 6. Eisenhower Matrix
expected: Navigate to the Eisenhower screen. Tasks are displayed in a 2×2 grid: "Do Now" (urgent + important), "Schedule" (not urgent + important), "Delegate" (urgent + not important), "Eliminate" (not urgent + not important). A task created with isUrgent=true and isImportant=true appears in the "Do Now" quadrant. An empty quadrant shows an "Empty" label.
result: pass

### 7. Day Planner (1-3-5 Rule)
expected: Navigate to the Day Planner screen. Three slot sections are visible: Big Task (1 slot), Medium Tasks (3 slots), Small Tasks (5 slots), each showing current count / max (e.g., "Medium Tasks (0/3)"). Tapping the Add button on a slot opens a task picker sheet. Selecting a task assigns it to that slot and increments the count. Assigning more than the slot maximum shows a yellow warning banner.
result: pass

### 8. Search Tasks
expected: On the task list screen, a search bar is visible at the top. Type a word that matches an existing task title. The list filters in real time to show only matching tasks. Clearing the search bar shows all tasks again.
result: pass

### 9. GTD Filter
expected: On the task list screen, an filter icon (funnel icon) is visible in the app bar. Tapping it opens the GTD filter screen showing chips for each distinct GTD context that exists on tasks. Selecting a context chip and tapping Apply filters the task list to that context. Tapping Clear removes the filter.
result: pass

### 10. Recurring Task — Set Recurrence
expected: Open the task form (create or edit). Select a due date. A "Recurrence" section appears below with radio options: No recurrence, Daily, Weekly, Monthly, Yearly. Select "Daily" and save. The task shows with a recurrence rule set.
result: pass

### 11. Recurring Task — Complete Creates Next Occurrence
expected: Check off (complete) a recurring task. The original task is marked complete and disappears from the active list. A new task appears with the same title and the next due date calculated (e.g., tomorrow for a daily task, same day next week for weekly).
result: pass

### 12. Project Screen — Subtask List and Progress
expected: Create a task of type "Project." Tap it to open the Project screen. A completion ratio progress bar is visible at the top (0% initially). Tap the FAB to add a subtask. The subtask appears in the list. Mark a subtask complete. The progress bar updates to reflect the new completion ratio.
result: pass

### 13. All 109 Tests Pass
expected: Run `flutter test test/domain/tasks/ test/data/tasks/ test/infrastructure/tasks/ test/application/tasks/ test/presentation/tasks/ --no-pub` in the project root. All 109 tests pass. Exit code 0, zero failures, zero errors.
result: pass

## Summary

total: 13
passed: 13
issues: 0
skipped: 0
pending: 0

## Gaps

[none yet]
