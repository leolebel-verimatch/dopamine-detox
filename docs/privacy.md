---
layout: default
title: Privacy Policy
---

# Privacy Policy

_Last updated: May 4, 2026_

Last Scroll is built to help you reclaim time from distracting apps. We collect the minimum amount of information required to run the app and operate the leaderboard.

## What we collect

**On your device only (never transmitted):**

- The list of apps and categories you've selected as "distractions". This is held by Apple's Family Controls framework as opaque tokens — Last Scroll never receives the names of the apps. We can ask the system to block a token, but we cannot read which app it is.
- The dates on which you finished a day under your time limit and the dates on which you exceeded it. These are stored in an App Group container so the in-app activity monitor extension can update them.
- Your monitoring start time and current shield status, also App-Group-only.

**Sent to our leaderboard server (Supabase):**

- A randomly generated anonymous identifier (a UUID created the first time you launch the app). It is **not** linked to your Apple ID, email, name, phone number, IP-derived identifier, or any other personal information.
- Today's date.
- Your current streak (an integer).

That is the entire payload. Nothing else leaves your device.

## What we do not collect

- We do not collect your name, email, phone number, address, or any contact information.
- We do not collect device usage data of any kind beyond the streak counter described above. Apple's Family Controls framework does not give us the underlying usage data either — we only receive a "threshold reached" callback.
- We do not collect crash reports, analytics, advertising identifiers, location, contacts, photos, microphone, or camera data.
- We do not use third-party SDKs that perform tracking.

## How we use the information

The anonymous ID + day + streak triple is stored in our `leaderboard` table on Supabase so that the in-app leaderboard can display the day's longest streaks. Because the ID is anonymous and contains no personal information, you cannot be identified from it.

You can reset your anonymous ID at any time by reinstalling the app.

## Data sharing

We do not sell, trade, rent, or share any of your information with third parties.

We do not use your data for advertising, advertising measurement, or share it with data brokers. This is also a contractual requirement of the Family Controls framework license.

## Data retention

Leaderboard rows are retained indefinitely so historical streaks remain visible. If you would like your anonymous ID's rows removed from the leaderboard, contact us using the support address below; provide the ID (visible in your in-app **Settings → Reset identity** screen) and we'll delete the matching rows within 30 days.

## Children

Last Scroll does not knowingly collect any information from children under 13. The Family Controls framework is designed to support both individual self-management and parental supervision; this app uses it for individual self-management only.

## Changes to this policy

If we materially change how we collect or use data, we'll update this page and bump the "Last updated" date above. Continuing to use the app after a change constitutes acceptance of the revised policy.

## Contact

Questions or data deletion requests: cheddar.lebel@gmail.com
