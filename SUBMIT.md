# Submission walkthrough — once Apple approves the entitlement

This is the path from "approval email arrived" to "submitted for review". Reckon ~90 minutes start to finish.

## 0. Prerequisites (already done)

- [x] Repo on GitHub: `leolebel-verimatch/dopamine-detox`
- [x] Family Controls entitlement request submitted (form at developer.apple.com)
- [x] App Group `group.com.cheddarlebel.dopaminedetox` registered
- [x] App IDs `com.cheddarlebel.dopaminedetox` and `…monitor` registered with App Groups capability
- [x] DEVELOPMENT_TEAM `465YNNXPJ4` pinned in `project.yml`
- [x] Privacy policy + terms + support pages in `/docs` ready for GitHub Pages
- [x] App Store metadata drafted in `/store/metadata.md`
- [x] Screenshot capture script at `/scripts/capture_screenshots.sh`
- [x] CI green on macos-15 + Xcode 16

## 1. When the approval email arrives (~minutes)

Apple emails when the entitlement is granted to your team. Then:

1. Go to <https://developer.apple.com/account/resources/identifiers/list>.
2. Open `com.cheddarlebel.dopaminedetox`. The **Family Controls** capability checkbox is now selectable. Tick it. **Save**.
3. Open `com.cheddarlebel.dopaminedetox.monitor`. Tick **Family Controls**. **Save**.

## 2. Wire Supabase (~5 min)

If you haven't already, finish steps 1.1–1.6 in `SETUP.md`:

```bash
# After you've copied the URL + anon key from Supabase dashboard
# into project.yml, regenerate:
xcodegen generate
```

## 3. Enable GitHub Pages (~2 min)

1. <https://github.com/leolebel-verimatch/dopamine-detox/settings/pages>
2. Source: **Deploy from a branch** → **main** → **/docs** → **Save**.
3. Wait ~1 min. The site goes live at `https://leolebel-verimatch.github.io/dopamine-detox/`.
4. Sanity check:
   - `https://leolebel-verimatch.github.io/dopamine-detox/privacy.html`
   - `https://leolebel-verimatch.github.io/dopamine-detox/support.html`

## 4. Capture screenshots (~10 min)

```bash
cd ~/clawd/dopamine-detox
./scripts/capture_screenshots.sh
```

Check `screenshots/6.9-inch/` and `screenshots/13-inch/` for the PNGs. Apple requires at least:

- **iPhone 6.9"** (iPhone 16/17 Pro Max): 5–10 screenshots
- **iPad 13"** (iPad Pro M5): 5–10 screenshots — only if you keep iPad as a supported device family.

If iPad screenshots are too plain, drop iPad support by setting `TARGETED_DEVICE_FAMILY: "1"` in `project.yml`.

## 5. Test on a real device (~15 min)

```bash
# Connect iPhone, then in Xcode:
# - Select your device as the run target
# - Cmd+R
```

Verify:
- [ ] First launch shows onboarding
- [ ] Granting Screen Time prompt works
- [ ] FamilyActivityPicker presents real apps
- [ ] After picking and starting a day, monitoring is visible in iOS Settings → Screen Time
- [ ] Emergency unlock view accepts the exact phrase (case-insensitive, whitespace-trim)
- [ ] Leaderboard fetches from Supabase
- [ ] Submit streak round-trips and disables the button

If the shield won't fire and you can't wait 2 hours: temporarily set `dailyLimitMinutes` to 1 in `Shared/AppConstants.swift`, run, use the apps for 60 seconds, observe the shield, revert before archive.

## 6. Bump version + archive (~5 min)

```bash
# bump if you've already uploaded earlier 1.0.0 build
# update MARKETING_VERSION + CURRENT_PROJECT_VERSION in project.yml
xcodegen generate
```

In Xcode:

1. Scheme → **DopamineDetox**
2. Run target → **Any iOS Device (arm64)**
3. Product → Archive
4. Wait ~3 min
5. Organizer opens → **Distribute App** → **App Store Connect** → **Upload**
6. Sign with automatic — Xcode will create the matching distribution profile
7. Wait for processing (~10–60 min). You'll get an email when the build is ready in App Store Connect.

## 7. Create the App Store Connect listing (~20 min)

1. <https://appstoreconnect.apple.com/apps> → **+** → **New App**
2. Platform: iOS · Name: **Last Scroll** · Primary Language: English (U.S.) · Bundle ID: pick `com.cheddarlebel.dopaminedetox` · SKU: `dopamine-detox-ios` · User Access: Full Access
3. Fill every field from `store/metadata.md`:
   - **App Information** tab: subtitle, category, age rating questionnaire, content rights, copyright
   - **Pricing and Availability**: Free, all territories
   - **App Privacy**: answer per `metadata.md` — User ID + Other Data, both not linked, no tracking
   - **Version 1.0**:
     - Promotional Text
     - Description
     - Keywords
     - Support URL: `https://leolebel-verimatch.github.io/dopamine-detox/support.html`
     - Marketing URL: `https://leolebel-verimatch.github.io/dopamine-detox/`
     - Privacy Policy URL: `https://leolebel-verimatch.github.io/dopamine-detox/privacy.html`
     - Upload screenshots (drag PNGs from `screenshots/`)
     - Build: select the one that just finished processing
     - **App Review Information**: paste the Notes block from `metadata.md`

## 8. Submit for review

1. Top right → **Add for Review** → **Submit to App Review**
2. Apple typically responds in 1–3 days. Family Controls apps may take longer and often get a clarification request — answer it within 24h to keep momentum.

## 9. After approval

- **Manual release** vs **Automatic release**: pick automatic for v1 unless you want to coordinate marketing.
- Watch the Crashes view in App Store Connect for the first 48 hours.
- Email Apple's Family Controls team if you ever need to bump the daily limit, change the permitted use case, or add new categories of behavior — that's a clarification, not a re-application.
