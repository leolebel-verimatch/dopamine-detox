# App Store Connect Metadata — Dopamine Detox

Copy-paste source for the App Store Connect listing. Each section maps to a field in the **App Information**, **Pricing**, **App Privacy**, or **Version** tab.

---

## App Information

| Field | Value |
|---|---|
| Name | `Dopamine Detox` |
| Subtitle | `Cap your distracting apps daily` |
| Bundle ID | `com.cheddarlebel.dopaminedetox` |
| SKU | `dopamine-detox-ios` |
| Primary Category | `Productivity` |
| Secondary Category | `Health & Fitness` |
| Content Rights | I do not own or have licensed rights to any third-party content (no third-party content used) |
| Age Rating | 4+ (no objectionable content) |

## Pricing

- **Price:** Free (Tier 0)
- **Availability:** All territories
- **Pre-order:** No

## URLs

| Field | Value |
|---|---|
| Marketing URL (optional) | `https://leolebel-verimatch.github.io/dopamine-detox/` |
| Support URL (required) | `https://leolebel-verimatch.github.io/dopamine-detox/support.html` |
| Privacy Policy URL (required) | `https://leolebel-verimatch.github.io/dopamine-detox/privacy.html` |

---

## Version 1.0

### Promotional Text (170 chars)

```
Pick the apps that drain your day. After 120 minutes they go dark until midnight. Build a streak, climb the leaderboard, and reclaim your attention.
```

### Description (4000 char max)

```
Dopamine Detox caps the apps that pull you away from your day.

Pick your distractions — Instagram, TikTok, X, YouTube, news, whatever owns your thumb — and the app monitors combined daily use through Apple's Family Controls. The moment you cross 120 minutes, those apps go dark for the rest of the day. iOS does the blocking; we just set the limit.

How it works:
• Tap to select the apps and categories you want capped.
• Tap "Start day". Dopamine Detox arms a 120-minute daily timer against just those apps.
• Use them as you normally would. When you reach the limit, they're shielded until midnight.
• Survive the day under the limit and your streak grows by one. Get shielded and it resets.
• Submit your streak to a public daily leaderboard with one tap.

The "emergency unlock" is intentionally inconvenient. Lifting the shield requires retyping a long motivational sentence — friction is the whole point. If you wanted easy, you wouldn't need this app.

Privacy:
• We never see which apps you selected. Apple's Family Controls hands us opaque tokens, not names. We can ask the system to block a token, but we cannot read it.
• The leaderboard uses an anonymous random ID. It is not tied to your Apple ID, email, name, or any other personal information.
• No analytics. No advertising. No third-party SDKs that track you. The only thing we send to our server is { anonymous ID, today's date, your streak }.
• Read the full policy at the privacy link below before you install.

Built for individual self-management. Not for surveilling another adult, not for organizational deployment, not for ad blocking.

Requires iOS 17 or later.
```

### Keywords (100 chars total, comma-separated, no spaces after commas)

```
focus,productivity,screen time,detox,distraction,habit,streak,attention,scroll,doomscroll,blocker
```

### What's New (4000 char max)

```
First release.
```

### Support URL

`https://leolebel-verimatch.github.io/dopamine-detox/support.html`

### Marketing URL

`https://leolebel-verimatch.github.io/dopamine-detox/`

### Copyright

`© 2026 Leo Lebel`

### Routing App Coverage File

Not applicable.

### Trade Representative Contact Information (optional, for Korea)

Skip.

---

## App Privacy (Privacy nutrition labels)

When App Store Connect asks "Do you or your third-party partners collect data from this app?":

**Answer: Yes, we collect data not linked to the user.**

### Data Types Collected

Toggle exactly these on:

- **Identifiers → User ID**
  - Used for: App Functionality, Analytics
  - Linked to user: **No**
  - Tracking: **No**
  - Description: A randomly generated UUID created on first launch. Submitted with the daily streak so the leaderboard can deduplicate users.

- **Other Data → Other Data Types: "Daily streak count"**
  - Used for: App Functionality
  - Linked to user: **No**
  - Tracking: **No**
  - Description: An integer representing how many consecutive days the user finished without exceeding their self-set time limit.

Everything else (Contact Info, Health & Fitness, Financial Info, Location, Sensitive Info, Contacts, User Content, Browsing History, Search History, Purchases, Diagnostics, etc.) → **Not Collected**.

### Tracking

`We do not track users.`

---

## Review Information

| Field | Value |
|---|---|
| First Name | Leo |
| Last Name | Lebel |
| Phone | [your phone] |
| Email | cheddar.lebel@gmail.com |
| Demo Account | Not required (no login in app) |
| Notes | See below ↓ |

### Review Notes (paste into "Notes" box)

```
Dopamine Detox uses Apple's Family Controls / DeviceActivity / ManagedSettings frameworks for individual self-management of screen time, in line with the Family Controls entitlement that has been granted to our team (request submitted via the developer.apple.com/contact/request/family-controls-distribution form on May 4, 2026).

To test:
1. On first launch, tap through the 3 onboarding screens and grant Screen Time access.
2. Tap "Choose distraction apps" and pick at least one app or category.
3. Tap "Start day". Monitoring engages.
4. To verify the shield mechanism without waiting 2 hours: in iOS Settings → Screen Time, you can see "Always Allowed" and observe that the selected apps are tracked. When the 120-minute threshold fires, they will be blocked at the system level.
5. The leaderboard tab fetches public daily streak scores from our Supabase backend over HTTPS. The user_id is an anonymous UUID created on first launch.

We do not collect any personal information. No login. No advertising. No third-party tracking SDKs. The full privacy policy is at the URL above.

The "emergency unlock" requires retyping a 25-word motivational sentence to lift the shield mid-day. This is intentional friction, not a UX bug.
```

---

## Build

After Family Controls entitlement is approved by Apple:

1. Xcode → DopamineDetox target → Signing & Capabilities → ensure Family Controls capability is added.
2. Set scheme to **Any iOS Device (arm64)**.
3. Product → Archive.
4. Window → Organizer → Distribute App → App Store Connect → Upload.
5. Wait for processing (~10–60 min).
6. Select the build under **Build** in this listing.
7. Submit for review.

Apple's Family Controls review tends to be detailed — expect 1–3 review cycles asking about data handling. The Review Notes above pre-empt the most common asks.

---

## Localization

English (U.S.) only for v1.0.

## Devices

- iPhone (primary)
- iPad (works, no iPad-specific UI)

## In-App Purchases

None for v1.0.

## App Store Connect Categorization

Sub-category does not apply for Productivity.

## Encryption

Standard iOS HTTPS only. ITSAppUsesNonExemptEncryption is added as `false` in `Info.plist` to skip the export compliance prompt at upload time.
