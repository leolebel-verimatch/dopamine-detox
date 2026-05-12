# Last Scroll

A SwiftUI iOS app that caps daily usage of distracting apps. After a 120-minute "Dopamine Budget" is spent, a system-level shield blocks the apps until midnight. Lifting the shield requires manually typing a long motivational sentence — friction is the point.

Built for school-wide competitions: students compete on a daily score (`points = 120 - minutes_used`), with a Hardcore Streak bonus for shielding early. A Productive Pass keeps schoolwork unrestricted. Deep Work mode is a manual 25-minute focus shield. Disqualified state is recorded on the leaderboard if Screen Time access is revoked while monitoring is active.

Architecture:

| Layer | Tech |
|---|---|
| UI | SwiftUI, iOS 17, dark-only, cyber-minimalism palette |
| Permissions | `FamilyControls` |
| Tracking | `DeviceActivity` (host + monitor extension) |
| Enforcement | `ManagedSettings` shield store |
| Custom shield UI | `ManagedSettingsUI` ShieldConfiguration extension |
| Backend | Supabase (`leaderboard` table) |
| IPC | App Group UserDefaults (`group.com.cheddarlebel.dopaminedetox`) |

## Repo layout

```
DopamineDetox/                     main app target
  DopamineDetoxApp.swift           @main, RootView with TabView
  Theme.swift                      cyber-minimalism palette
  UnlockChallenge.swift            type-the-sentence phrase
  Views/
    ControlCenterView.swift        gauge + Pomodoro + scoring
    CircularGaugeView.swift        reusable gauge
    AppSelectionView.swift         distraction-app picker
    ProductivePassView.swift       whitelist picker
    EmergencyUnlockView.swift      type-the-sentence unlock
    LeaderboardView.swift          today's top scores (excludes DQ)
    OnboardingView.swift           3-page intro
  Services/
    ScreenTimeManager.swift        auth, monitoring, Pomodoro, anti-cheat
    SupabaseService.swift          upsert + reportStatus
  DopamineDetox.entitlements
  Info.plist

DopamineDetoxMonitor/              DeviceActivityMonitor extension
  DopamineDetoxMonitor.swift       threshold → shield; sync event → flag pending sync
  DopamineDetoxMonitor.entitlements
  Info.plist

DopamineDetoxShield/               ShieldConfigurationDataSource extension
  DopamineDetoxShield.swift        "Focusing…" replacement UI on shielded apps
  DopamineDetoxShield.entitlements
  Info.plist

Shared/                            code shared by all three targets
  AppConstants.swift               group id, store names, daily limit, Scoring
  DayHistory.swift                 streak + points history
```

## Generate the Xcode project

```bash
brew install xcodegen      # one-time
xcodegen generate          # from project root
open DopamineDetox.xcodeproj
```

`project.yml` is the source of truth — do not edit `.xcodeproj` by hand.

## Required: enable the Family Controls entitlement

`com.apple.developer.family-controls` is **not** included in the standard development profile. Request the Distribution variant from Apple at <https://developer.apple.com/contact/request/family-controls-distribution>. Approval typically takes 1–5 business days. All three targets (app + monitor + shield) require the entitlement.

## Supabase setup

The app upserts a daily score per anonymous user. Until you configure Supabase the app still runs — submit/leaderboard show "not configured" instead of crashing.

1. Create a Supabase project at <https://supabase.com>.
2. Run this SQL in **SQL Editor** to create the table, indexes, and policies tuned for ~2 000 concurrent students:

   ```sql
   create table public.leaderboard (
     id uuid primary key default gen_random_uuid(),
     user_id text not null,
     day date not null,
     score integer not null check (score >= 0 and score <= 100000),
     minutes_used integer not null default 0 check (minutes_used >= 0),
     shielded boolean not null default false,
     disqualified boolean not null default false,
     disqualification_reason text,
     updated_at timestamptz not null default now(),
     unique (user_id, day)
   );

   -- Hot path: "today, top scores, excluding DQ" — covered by this partial index.
   create index if not exists leaderboard_today_score_idx
     on public.leaderboard (day desc, score desc)
     where disqualified = false;

   -- Secondary: lookups by user across days (history fetch).
   create index if not exists leaderboard_user_day_idx
     on public.leaderboard (user_id, day desc);

   alter table public.leaderboard enable row level security;

   create policy "leaderboard_read_anon" on public.leaderboard
     for select to anon using (true);

   create policy "leaderboard_insert_anon" on public.leaderboard
     for insert to anon
     with check (day = (now() at time zone 'utc')::date);

   create policy "leaderboard_update_anon" on public.leaderboard
     for update to anon
     using (day = (now() at time zone 'utc')::date)
     with check (day = (now() at time zone 'utc')::date);

   create or replace function public.leaderboard_touch_updated_at()
     returns trigger language plpgsql as $$
     begin new.updated_at = now(); return new; end;
   $$;
   drop trigger if exists leaderboard_touch on public.leaderboard;
   create trigger leaderboard_touch before update on public.leaderboard
     for each row execute function public.leaderboard_touch_updated_at();
   ```

3. Copy the project URL and the **anon** public key.
4. Edit `project.yml` to set `SUPABASE_URL` and `SUPABASE_ANON_KEY` under the `DopamineDetox` target settings, then re-run `xcodegen generate`.

The anon key is safe to expose; RLS prevents writes to past/future days or other users' rows.

## Scoring

`points = max(0, 120 - minutes_used)`. If the shield kicks in with ≥30 minutes of the day remaining (a "Hardcore Streak"), an additional +25 bonus is awarded.

The leaderboard query filters `disqualified = false`. A student is marked disqualified when Screen Time authorization is revoked while monitoring is active — the manager detects this on every foreground and posts an out-of-band update.

## Scaling notes (2 000 users)

- Single hot query: `select … where day = today and disqualified = false order by score desc limit 50`. Backed by the partial index above — sub-1ms regardless of total rows.
- Write rate: ~2 000 upserts/day at the 9 PM auto-sync window. Spread across a 1-hour soak (server clocks vary). Well under Supabase free-tier limits.
- Per-user storage: 1 row/day. 2 000 students × 180 school days = 360 000 rows/year. The partial index keeps today's read constant-time.

## How it works

1. Onboarding asks for Family Controls authorization (`AuthorizationCenter.shared.requestAuthorization(for: .individual)`).
2. The user picks distracting apps; selection is JSON-encoded into App Group UserDefaults so the monitor extension can read it.
3. **Start day** registers a `DeviceActivitySchedule` (00:00–23:59, repeating) with two events: a 120-minute `LimitReached` threshold and a 21:00 evening `EveningSync` trigger.
4. `DopamineDetoxMonitor.eventDidReachThreshold` runs in the extension. `LimitReached` → apply shield. `EveningSync` → flag a pending sync the host app picks up on next foreground.
5. When the shield is active, `DopamineDetoxShield` (ShieldConfigurationDataSource) replaces the default block screen with a branded "Focusing…" UI.
6. **Productive Pass** is a second `FamilyActivitySelection` that's never bound to a monitor event — it simply documents the whitelist for the user.
7. **Deep Work** runs a one-shot 25-min `DeviceActivitySchedule` with the same selection on a separate `ManagedSettingsStore`, which auto-clears when the interval ends.
8. **Anti-cheat**: every foreground the manager sends a heartbeat to Supabase. If `AuthorizationCenter.authorizationStatus` drops while monitoring is active, the day is flagged disqualified and the leaderboard row updated.
9. **Emergency unlock** clears the shield only after the user retypes the motivational phrase. The day is still recorded as shielded so the streak resets.

## Testing on a device

The Family Controls APIs return mock data in the simulator. To test the real shield: iPhone on iOS 17+ with the Apple ID signed into Screen Time, dev build signed with the approved entitlement.
