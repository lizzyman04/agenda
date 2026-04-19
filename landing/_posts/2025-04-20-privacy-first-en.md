---
layout: post
title: "Why Privacy-First Matters for Productivity Apps"
date: 2025-04-20 10:00:00 -0300
lang: en
ref: privacy-first
permalink: /blog/2025/04/20/privacy-first/
tags: [privacy, philosophy, architecture, offline]
excerpt: "In a world where productivity apps are data collection vectors, AGENDA takes a different path: your data never leaves the device."
---

When you write down a task in a productivity app, what happens to that information?

In most cases: it goes to a server. It gets analyzed for personalization. It feeds behavioral models. It can be sold, breached, discontinued. And when the service shuts down — because services shut down — your data disappears with it.

AGENDA starts from a different premise: **your data is yours, and it should never leave your device.**

## The Problem with Modern Productivity Apps

Popular productivity apps have a business model that depends on your data or your monthly subscription. This creates incentives that aren't aligned with the user:

- **Mandatory sync**: your data lives on third-party servers because that's what enables the model
- **Behavioral analytics**: how you use the app becomes the product
- **Lock-in**: leaving is hard because your data is trapped in their ecosystem
- **Discontinuation risk**: if the company shuts down or pivots, you lose everything

This isn't conspiracy thinking. It's simply the business model that has come to dominate the market.

## What "Privacy-First" Means in Practice

In AGENDA, privacy is not a feature. It's an architectural constraint.

> If a design decision violates privacy, that decision is wrong — regardless of other benefits.

This has concrete consequences:

### 1. No analytics

No calls to Amplitude, Mixpanel, Firebase Analytics, or any similar service. We know zero about how you use the app. This is intentional.

### 2. No external crash reporting

No Sentry, no Crashlytics. If the app crashes, the log stays on the device. You can send it to us if you want, but we don't send it automatically.

### 3. 100% local database

We use [Isar Community](https://pub.dev/packages/isar_community) — a native database that stores everything on the device, with Dart queries and excellent performance. No data leaves the device.

### 4. 100% offline functionality

AGENDA doesn't have an "offline mode" — it is offline by default. There is no sync code. There is no conditional logic based on connectivity. The app works on a plane, in a bunker, anywhere.

### 5. Open source

The code is at [github.com/lizzyman04/agenda](https://github.com/lizzyman04/agenda). Anyone can audit it, verify the claims above, and contribute.

## The Honest Tradeoff

Local privacy has a real cost: **no automatic cloud backup**.

If you lose your device without having done a manual backup (via CSV/JSON export), your data is not recoverable. We don't have a copy.

This isn't carelessness — it's a direct consequence of the model. We'd like to have a secure automatic backup in the future, but we won't do it in a way that compromises the privacy promise.

For now: **use the export regularly**. Your tasks and finances deserve a local backup.

## Why This Matters Beyond Convenience

Personal productivity involves sensitive information. Your tasks reveal your projects, your concerns, your plans. Your finances reveal your habits, your debts, your goals.

This kind of data shouldn't exist on third-party servers — not because the services are malicious, but because data concentration creates risk. All it takes is one breach, one acquisition, one policy change.

AGENDA is a bet: that there's a segment of users who prefer real control over sync convenience. That "your data, yours alone" is a value proposition strong enough to build something on.

We believe it is.

---

*AGENDA is in active development. Follow the progress on [GitHub](https://github.com/lizzyman04/agenda).*
