---
layout: post
title: "Phase 2 Complete: Task Management is Here"
date: 2026-04-21 12:00:00 -0300
lang: en
ref: phase-2-complete
permalink: /blog/2026/04/21/phase-2-complete/
tags: [development, flutter, tasks, phase-2]
excerpt: "The AGENDA task core is done: Eisenhower, 1-3-5, GTD, projects and subtasks, recurring tasks, search and filters."
---

**AGENDA Phase 2** is complete. The task core works end to end, and everything is stored locally on your device.

## What Was Built

**Eisenhower Matrix** — A 2×2 grid that classifies tasks by urgency and importance. Do immediately what is urgent and important. Plan what is important but not urgent. Delegate the urgent but unimportant. Eliminate the rest.

**1-3-5 Rule** — Each day starts with a clear intention: 1 big task, 3 medium, 5 small. AGENDA enforces this constraint automatically, preventing the infinite list that never ends.

**GTD (Getting Things Done)** — Next actions, contexts and waiting-for, plus a guided questionnaire that helps you decide what to do with each item.

Around the three frameworks:

- Projects with subtasks and rolled-up progress
- Recurring tasks (daily, weekly, monthly, yearly)
- Keyword search
- Filters by project, Eisenhower quadrant, GTD context and due-date range
- A 5-second undo after you delete something

## Under the Hood

State lives in Cubits, so the screens only react to state and send intentions.

Everything is stored on the device with Isar Community, the maintained fork of the original Isar (abandoned since 2023). No SQLite and no JSON files — typed queries written directly in Dart.

## What's Next

Phase 3 (finance) started next.

*Update, October 2026: Phase 3 is done too. See the [roadmap]({{ '/dev/' | relative_url }}#roadmap).*
