# One-time setup before first build

These three steps need to happen once. Together they take ~10 minutes.

## 1. Create the Supabase project (3 min)

1. Open <https://supabase.com/dashboard/projects> while signed in.
2. Click **New project**.
   - Organization: pick or create (Free tier is fine).
   - Name: `Dopamine Detox`
   - Database password: click **Generate a password** and copy it somewhere safe (you won't need it for the app — only for direct postgres access).
   - Region: closest to your users.
3. Wait ~2 minutes for provisioning.
4. Open **SQL Editor** → **New query**, paste the schema from `README.md` ("Supabase setup" section), and click **Run**.
5. Open **Project Settings → API**:
   - Copy **Project URL** (looks like `https://xxxxxxx.supabase.co`)
   - Copy **anon public** key (long JWT)
6. Edit `project.yml` in the repo:
   ```yaml
   SUPABASE_URL: https://xxxxxxx.supabase.co
   SUPABASE_ANON_KEY: eyJhbGc...
   ```
7. Run `xcodegen generate` and rebuild.

## 2. Register the App Group with Apple (2 min)

Required for the app and the DeviceActivityMonitor extension to share data.

1. Open <https://developer.apple.com/account/resources/identifiers/list/applicationGroup>.
2. Click **+** to register a new App Group.
3. Description: `Dopamine Detox`
4. Identifier: `group.com.cheddarlebel.dopaminedetox`
5. **Continue** → **Register**.

## 3. Register the two App IDs (3 min)

1. Open <https://developer.apple.com/account/resources/identifiers/list>.
2. Click **+** → **App IDs** → **App** → **Continue**.
3. Description: `Dopamine Detox` · Bundle ID: `com.cheddarlebel.dopaminedetox`
4. Capabilities to enable: **Family Controls** (will only appear after Apple approves the entitlement request from the form we already submitted), **App Groups**.
5. Click **Register**.
6. Repeat for the extension: `com.cheddarlebel.dopaminedetox.monitor` (description `Dopamine Detox Monitor`) — same capabilities.

For both App IDs, after registration: open the App ID, click **App Groups → Configure**, check `group.com.cheddarlebel.dopaminedetox`, **Save**.

## 4. Host the privacy / terms / support pages (5 min)

The pages already live in `/docs/`. They need a public URL because Apple requires the privacy policy URL on the App Store listing.

**GitHub Pages** is the obvious choice but the repo is private and the free plan blocks Pages on private repos. Two options:

**A. Make the repo public** (fastest, free)

```bash
gh repo edit leolebel-verimatch/dopamine-detox --visibility public --accept-visibility-change-consequences
gh api -X POST repos/leolebel-verimatch/dopamine-detox/pages \
  -f "source[branch]=main" -f "source[path]=/docs"
```

Site goes live at `https://leolebel-verimatch.github.io/dopamine-detox/` in ~1 minute.

**B. Cloudflare Pages from the private repo** (free, private repo stays private)

1. <https://dash.cloudflare.com> → **Workers & Pages** → **Create** → **Pages** → **Connect to Git**.
2. Select the `dopamine-detox` repo.
3. Build settings:
   - Framework preset: `None`
   - Build command: leave blank
   - Build output directory: `docs`
4. Deploy. Cloudflare gives you a `*.pages.dev` URL.
5. Update the URLs in `store/metadata.md` to point at the Cloudflare URL.

Either way: confirm `/privacy.html`, `/terms.html`, `/support.html` load before submitting to the App Store.

## 5. After Apple approves the Family Controls entitlement

When the approval email arrives:

1. Refresh the App ID page; the Family Controls capability checkbox will become available.
2. Enable it on both App IDs.
3. Open Xcode → DopamineDetox target → Signing & Capabilities → tap **Try Again** if a profile error shows; Xcode will create the matching profile automatically.

After that you can archive and submit. See `SUBMIT.md` for the post-approval submission walkthrough.
