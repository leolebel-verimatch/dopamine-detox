# Submission — current state (May 10, 2026)

## What's already done

- [x] Code complete, build green, 17 unit + 4 UI + 3 screenshot tests passing
- [x] Repo public + GitHub Pages live at <https://leolebel-verimatch.github.io/dopamine-detox/>
  - `/privacy.html`, `/terms.html`, `/support.html` all 200 OK
- [x] Apple App Group registered (`group.com.cheddarlebel.dopaminedetox`)
- [x] Two App IDs registered with App Groups bound
- [x] Family Controls **distribution entitlement requested** May 4 (status: pending Apple)
- [x] ASC listing created (app id `6767400033`, name **Last Scroll**)
- [x] ASC metadata pushed via API: subtitle, categories (Productivity / Health & Fitness), description, keywords, promo text, support / marketing / privacy URLs, content rights
- [x] Age rating set (4+, no objectionable content, 173 countries)
- [x] App Privacy nutrition labels published (User ID + Other Data, both unlinked, no tracking)
- [x] App Review notes pre-populated via API (review id `da92e413-…-c4ade46237d2`)
- [x] Screenshots captured (5 iPhone 17 Pro Max, 4 iPad Pro 13")
- [x] `scripts/upload.sh` — archive + export + ASC upload via ASC API key (works end-to-end except for the entitlement-embed step which awaits Apple's flip)
- [x] `ci/ExportOptions.plist` ready (app-store-connect, automatic signing, team `465YNNXPJ4`)
- [x] DEVELOPMENT_TEAM and `ITSAppUsesNonExemptEncryption=false` pinned in `project.yml`
- [x] Graceful degradation when Supabase keys not configured — leaderboard tab + submit button hidden, no broken UX visible to reviewers

## What's still blocked

### Apple (waiting on them)

- [ ] **Family Controls Distribution entitlement approval**
  - Submitted May 4. Approval window is typically 1–5 business days.
  - When it lands, Apple emails leo.lebel@me.com and the capability becomes selectable in <https://developer.apple.com/account/resources/identifiers/list>.
  - If approval drags past 7 business days, reply to the original request with: "Reaching out to check on the status of this Family Controls Distribution entitlement request (Team ID 465YNNXPJ4, app `com.cheddarlebel.dopaminedetox`). Happy to clarify any aspect of the proposed use case."

### Optional but recommended before public release

- [ ] **Supabase project + keys** (5 min, your machine — the dashboard hard-blocks browser automation)
  - <https://supabase.com/dashboard/projects> → **New project**
  - Name: `Last Scroll`
  - DB password: `Wh@tismyPW38` (saved in `~/memory/accounts.md`)
  - Run the schema block from `README.md` → "Supabase setup" in **SQL Editor**
  - **Project Settings → API** → copy URL + anon key
  - Edit `project.yml`:
    ```yaml
    SUPABASE_URL: https://<project>.supabase.co
    SUPABASE_ANON_KEY: <anon-key>
    ```
  - `xcodegen generate`
  - With keys present, the Leaderboard tab + Submit-streak button re-enable automatically.

- [ ] **Real-device test** (~15 min, post-entitlement)
  - Plug iPhone in.
  - In Xcode: change run target to your device, Cmd+R.
  - Confirm onboarding → Screen Time grant → pick distraction → Start day.
  - Verify monitoring shows up under iOS Settings → Screen Time.
  - (Optional) temporarily lower `dailyLimitMinutes` to 1 in `Shared/AppConstants.swift` to verify the shield actually fires; revert before archive.

## Once Apple approves (the path to TestFlight)

1. Open <https://developer.apple.com/account/resources/identifiers/list>.
2. Open the `com.cheddarlebel.dopaminedetox` App ID. Tick **Family Controls (Distribution)**. Save.
3. Same for `com.cheddarlebel.dopaminedetox.monitor`. Save.
4. Back in this repo:
   ```bash
   ./scripts/upload.sh
   ```
   This archives + signs + exports + uploads to App Store Connect using the ASC API key. ~3 min build + ~10 min Apple processing.
5. Wait for the "Build is processed" email from Apple (~10–60 min).
6. Open <https://appstoreconnect.apple.com/apps/6767400033/distribution/version> → select the build → submit.
7. Submit for review. Review notes are already attached; no further input needed during submit.

## Files / IDs / URLs you'll need

| | |
|---|---|
| ASC app id | `6767400033` |
| ASC version id | `f17153c0-fa4d-49c2-9b61-d78549173441` (1.0) |
| Bundle id (app) | `com.cheddarlebel.dopaminedetox` |
| Bundle id (extension) | `com.cheddarlebel.dopaminedetox.monitor` |
| App Group | `group.com.cheddarlebel.dopaminedetox` |
| Team id | `465YNNXPJ4` |
| ASC API key | `24P7LHL3QA` (`~/.private_keys/AuthKey_24P7LHL3QA.p8`) |
| ASC issuer | `d40a5bd9-fd5a-4f65-a0aa-21804fbd2c72` |
| Public site | <https://leolebel-verimatch.github.io/dopamine-detox/> |
