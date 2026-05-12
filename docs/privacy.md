---
layout: default
title: Privacy Policy
---

# Privacy Policy

_Last updated: May 11, 2026_

Last Scroll is built to help students cap distracting apps and compete on a school-wide screen-time leaderboard. We collect the minimum amount of information required to run the app, operate the leaderboard, and keep the contest fair.

## What we collect

**On your device only (never transmitted):**

- The list of apps and categories you've selected as "distractions" and as the "Productive Pass" whitelist. These are held by Apple's Family Controls framework as opaque tokens — Last Scroll never receives the names of the apps. We can ask the system to block a token, but we cannot read which app it is.
- Your grade level (e.g. Grade 11) — used to pick a motivational quote shown on the shield screen. Stored only in the App Group container; never sent to the server.
- The dates on which you finished a day under your time limit and the dates on which you exceeded it. Stored in an App Group container so the in-app activity monitor extension can update them.
- Your monitoring start time, current shield status, and Pomodoro state, also App-Group-only.

**Sent to our leaderboard server (Supabase):**

- A randomly generated anonymous identifier (a UUID created the first time you launch the app). It is **not** linked to your Apple ID, email, name, phone number, IP-derived identifier, or any other personal information.
- Today's date.
- Your daily score (an integer: `120 − minutes_used`, plus a Hardcore Streak bonus).
- The number of minutes used today against your selected distraction apps.
- Whether the shield is currently active.
- Whether you've been disqualified for the day, and a short reason code (e.g. `auth_revoked`) if so.

That is the entire payload. Nothing else leaves your device.

## What we do not collect

- We do not collect your name, email, phone number, address, or any contact information.
- We do not collect the names of the apps you select, nor any other granular usage data. Apple's Family Controls framework does not expose underlying usage data to us — we only receive threshold callbacks.
- We do not collect crash reports, analytics, advertising identifiers, location, contacts, photos, microphone, or camera data.
- We do not use third-party SDKs that perform tracking.

## How we use the information

The anonymous ID + day + score (+ minutes used, shielded, disqualified) tuple is stored in our `leaderboard` table on Supabase so the in-app leaderboard can display the day's top scores and so contest organizers can verify a fair winner. Because the ID is anonymous and contains no personal information, you cannot be identified from it.

You can reset your anonymous ID at any time by reinstalling the app.

## Data sharing

We do not sell, trade, rent, or share any of your information with third parties.

We do not use your data for advertising, advertising measurement, or share it with data brokers. This is also a contractual requirement of the Family Controls framework license.

## Data retention

Leaderboard rows are retained indefinitely so historical scores remain visible. If you would like your anonymous ID's rows removed from the leaderboard, contact us using the support address below; provide the ID (visible in your in-app **Settings** screen) and we'll delete the matching rows within 30 days.

## Children

Last Scroll is designed for students managing their own screen time. The Family Controls framework supports both individual self-management and parental supervision; this app uses it for individual self-management. We do not knowingly collect information from children under 13. Anonymous IDs never link back to identity.

## Changes to this policy

If we materially change how we collect or use data, we'll update this page and bump the "Last updated" date above. Continuing to use the app after a change constitutes acceptance of the revised policy.

## Contact

Questions or data deletion requests: cheddar.lebel@gmail.com
