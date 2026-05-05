# Dopamine Detox

A SwiftUI iOS app that lets you cap daily usage of distracting apps. After 120 minutes of combined use, a system-level shield blocks access for the rest of the day. Lifting the shield requires manually typing a long motivational sentence — friction is the point.

Architecture:

| Layer | Tech |
|---|---|
| UI | SwiftUI, iOS 17, dark-only |
| Permissions | `FamilyControls` |
| Tracking | `DeviceActivity` (host + monitor extension) |
| Enforcement | `ManagedSettings` shield store |
| Backend | Supabase (`leaderboard` table) |
| IPC | App Group UserDefaults (`group.com.cheddarlebel.dopaminedetox`) |

## Repo layout

```
DopamineDetox/                     main app target
  DopamineDetoxApp.swift           @main, request authorization
  Theme.swift                      colors + constants
  Views/
    ControlCenterView.swift        circular gauge + actions
    CircularGaugeView.swift        reusable gauge
    AppSelectionView.swift         FamilyActivityPicker wrapper
    EmergencyUnlockView.swift      type-the-sentence unlock
  Services/
    ScreenTimeManager.swift        auth, selection, monitoring
    SupabaseService.swift          POST to leaderboard
  DopamineDetox.entitlements       Family Controls + App Group
  Info.plist

DopamineDetoxMonitor/              DeviceActivityMonitor extension
  DopamineDetoxMonitor.swift       eventDidReachThreshold → apply shield
  DopamineDetoxMonitor.entitlements
  Info.plist                       NSExtension principal class
```

## Generate the Xcode project

```bash
brew install xcodegen      # one-time
xcodegen generate          # from project root
open DopamineDetox.xcodeproj
```

`project.yml` is the source of truth — do not edit `.xcodeproj` by hand. Re-run `xcodegen` after any file moves.

## Required: enable the Family Controls entitlement

`com.apple.developer.family-controls` is **not** included in the standard development profile. You must request it from Apple before the app will build for a device or release configuration.

### 1. Request the entitlement from Apple

1. Open <https://developer.apple.com/contact/request/family-controls-distribution>.
2. Fill out the form. Apple usually approves personal-use Screen Time apps within a few business days.
3. Wait for the approval email. (You can develop in the simulator with the entitlement turned on without approval, but device builds will fail until Apple flips the bit on your team.)

### 2. Add the capability in Xcode

Once approved:

1. Select the `DopamineDetox` target → **Signing & Capabilities**.
2. Click **+ Capability** → **Family Controls**. Xcode adds the entry to the entitlements file.
3. Repeat for the `DopamineDetoxMonitor` target — both the app and the extension need the entitlement.

The `.entitlements` files in this repo already contain the key:

```xml
<key>com.apple.developer.family-controls</key>
<true/>
```

### 3. Configure the App Group

Both targets share state via an App Group. In **Signing & Capabilities** for each target:

1. Click **+ Capability** → **App Groups**.
2. Add `group.com.cheddarlebel.dopaminedetox` (rename to match your team prefix if you fork).

Both entitlement files in this repo already include the group; you only need to confirm Xcode recognizes it.

### 4. Set your development team

Open `project.yml` and set `DEVELOPMENT_TEAM` under `settings.base`, or override per target in Xcode after generating. Re-run `xcodegen` after editing.

## Supabase setup

The app upserts a daily streak score per anonymous user. Until you configure Supabase the app still runs — submit/leaderboard show "not configured" instead of crashing.

1. Create a Supabase project at <https://supabase.com>.
2. Run this SQL in **SQL Editor** to create the table and policies:

   ```sql
   create table public.leaderboard (
     id uuid primary key default gen_random_uuid(),
     user_id text not null,
     day date not null,
     score integer not null check (score >= 0 and score <= 100000),
     updated_at timestamptz not null default now(),
     unique (user_id, day)
   );

   create index if not exists leaderboard_day_score_idx
     on public.leaderboard (day desc, score desc);

   alter table public.leaderboard enable row level security;

   -- anon can read today's board
   create policy "leaderboard_read_anon" on public.leaderboard
     for select to anon using (true);

   -- anon can insert only for their own client-generated user_id and only for today
   create policy "leaderboard_insert_anon" on public.leaderboard
     for insert to anon
     with check (day = (now() at time zone 'utc')::date);

   -- anon can update only their own row, only for today
   create policy "leaderboard_update_anon" on public.leaderboard
     for update to anon
     using (day = (now() at time zone 'utc')::date)
     with check (day = (now() at time zone 'utc')::date);

   -- maintain updated_at on update
   create or replace function public.leaderboard_touch_updated_at()
     returns trigger language plpgsql as $$
     begin new.updated_at = now(); return new; end;
   $$;
   drop trigger if exists leaderboard_touch on public.leaderboard;
   create trigger leaderboard_touch before update on public.leaderboard
     for each row execute function public.leaderboard_touch_updated_at();
   ```

3. Copy the project URL and the **anon** public key from the Supabase dashboard.
4. Open `project.yml` and replace `SUPABASE_URL` and `SUPABASE_ANON_KEY` under the `DopamineDetox` target settings:

   ```yaml
   SUPABASE_URL: https://<your-project>.supabase.co
   SUPABASE_ANON_KEY: <anon-key>
   ```

5. Re-run `xcodegen generate`.

The values are baked into `Info.plist` at build time and read by `SupabaseService` via `Bundle.main.object(forInfoDictionaryKey:)`. The anon key is intended to be exposed in the client; the policies above prevent users from writing to past or future days, or to other users' rows.

### Score semantics

The score is a streak — the number of consecutive days the user finished without being shielded. Each day the app upserts on `(user_id, day)` so a single row per user per day exists; the most recent value wins. The leaderboard view sorts by `score` desc for the current day.

## How it works

1. On first launch the user is taken through a 3-page onboarding and asked to grant Family Controls authorization (`AuthorizationCenter.shared.requestAuthorization(for: .individual)`).
2. The user picks distracting apps via `FamilyActivityPicker`. The `FamilyActivitySelection` is JSON-encoded and stored in App Group `UserDefaults` so the extension can read it.
3. Tapping **Start day** registers a `DeviceActivitySchedule` (00:00–23:59, repeating) with one `DeviceActivityEvent` whose threshold is 120 minutes against the selected app/category tokens.
4. iOS runs `DopamineDetoxMonitor.eventDidReachThreshold` in the extension exactly once when combined usage hits 120 minutes. The extension reads the saved selection and applies it to a `ManagedSettingsStore` shield, then writes `shielded = true` to the App Group.
5. At end of day (`intervalDidEnd`) the extension records the day's outcome (shielded or not) in a shared `DayHistory`. Streak = trailing consecutive days with `shielded == false`. The host app also reconciles this on every foreground in case the extension callback was missed.
6. **Emergency unlock** clears the shield only after the user retypes a long motivational phrase. `ManagedSettingsStore.shield.applications = nil` removes the block, but the day is still recorded as shielded so the streak resets.
7. The leaderboard tab fetches the day's top streaks from Supabase. Submitting upserts the user's current streak with `(user_id, day)` as the conflict key — idempotent.

## Testing on a device

The Family Controls APIs return mock data in the simulator. To test the real shield you need:

- An iPhone running iOS 17+
- Your Apple ID signed into iOS Settings → Screen Time
- A development build signed with a profile that includes the approved entitlement

## Conventions

- All UI text is system font; no decorative typefaces.
- One accent color (`Theme.accent`, muted amber) and one danger color. No gradients.
- The gauge animates linearly off `monitoringStartedAt` for a visual hint of progress; the shield itself fires off real device usage via the extension.
