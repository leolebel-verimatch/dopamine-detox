#!/usr/bin/env python3
"""Push App Store Connect listing metadata for Last Scroll.

Surgical: only acts on bundle id `com.cheddarlebel.dopaminedetox`.
"""
from __future__ import annotations
import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import jwt

ISSUER_ID = "d40a5bd9-fd5a-4f65-a0aa-21804fbd2c72"
KEY_ID = "24P7LHL3QA"
P8_PATH = Path.home() / ".private_keys" / f"AuthKey_{KEY_ID}.p8"
API_BASE = "https://api.appstoreconnect.apple.com"

APP_ID = "6767400033"
APP_INFO_ID = "7e4279b6-bacf-463e-b652-9e17ff410e91"
APP_INFO_LOC_ID = "792f6fb4-e0e4-44a6-8db6-ea85ee9f609b"  # en-US
VERSION_ID = "f17153c0-fa4d-49c2-9b61-d78549173441"
VERSION_LOC_ID = "e7607770-0e08-47ba-a6cc-69052a26abd6"  # en-US

DESCRIPTION = """Last Scroll caps the apps that pull you away from your day.

Pick your distractions — Instagram, TikTok, X, YouTube, news, whatever owns your thumb — and the app monitors combined daily use through Apple's Family Controls. The moment you cross 120 minutes, those apps go dark for the rest of the day. iOS does the blocking; we just set the limit.

How it works:
• Tap to select the apps and categories you want capped.
• Tap "Start day". Last Scroll arms a 120-minute daily timer against just those apps.
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

Requires iOS 17 or later."""

KEYWORDS = "focus,productivity,screen time,detox,distraction,habit,streak,attention,scroll,doomscroll,blocker"
PROMO = "Pick the apps that drain your day. After 120 minutes they go dark until midnight. Build a streak, climb the leaderboard, and reclaim your attention."
SUBTITLE = "Daily cap on doomscrolling"

# Placeholder until pages is hosted; documented in SETUP.md
SUPPORT_URL = "https://leolebel-verimatch.github.io/dopamine-detox/support.html"
MARKETING_URL = "https://leolebel-verimatch.github.io/dopamine-detox/"
PRIVACY_URL = "https://leolebel-verimatch.github.io/dopamine-detox/privacy.html"


def _tok() -> str:
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 20 * 60, "aud": "appstoreconnect-v1"},
        P8_PATH.read_text(),
        algorithm="ES256",
        headers={"kid": KEY_ID, "typ": "JWT"},
    )


def call(method: str, path: str, body: dict | None = None) -> tuple[int, dict | str]:
    req = urllib.request.Request(
        API_BASE + path,
        data=json.dumps(body).encode() if body is not None else None,
        method=method,
        headers={
            "Authorization": f"Bearer {_tok()}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", errors="replace")


def step(label: str, method: str, path: str, body: dict | None = None) -> None:
    code, data = call(method, path, body)
    if 200 <= code < 300:
        print(f"  ✓ {label}")
    else:
        print(f"  ✗ {label}  ({code})")
        if isinstance(data, str):
            print(f"    {data[:400]}")
        else:
            print(f"    {json.dumps(data)[:400]}")


def main() -> None:
    # 1. Categories on the appInfo
    step(
        "categories: Productivity / Health & Fitness",
        "PATCH",
        f"/v1/appInfos/{APP_INFO_ID}",
        {
            "data": {
                "type": "appInfos",
                "id": APP_INFO_ID,
                "relationships": {
                    "primaryCategory": {
                        "data": {"type": "appCategories", "id": "PRODUCTIVITY"}
                    },
                    "secondaryCategory": {
                        "data": {"type": "appCategories", "id": "HEALTH_AND_FITNESS"}
                    },
                },
            }
        },
    )

    # 2. AppInfoLocalization: subtitle + privacy policy URL
    step(
        "appInfoLocalization: subtitle + privacy URL",
        "PATCH",
        f"/v1/appInfoLocalizations/{APP_INFO_LOC_ID}",
        {
            "data": {
                "type": "appInfoLocalizations",
                "id": APP_INFO_LOC_ID,
                "attributes": {
                    "subtitle": SUBTITLE,
                    "privacyPolicyUrl": PRIVACY_URL,
                },
            }
        },
    )

    # 3. AppStoreVersionLocalization: description, keywords, promo, support, marketing
    step(
        "version 1.0 localization (description / keywords / promo / urls)",
        "PATCH",
        f"/v1/appStoreVersionLocalizations/{VERSION_LOC_ID}",
        {
            "data": {
                "type": "appStoreVersionLocalizations",
                "id": VERSION_LOC_ID,
                "attributes": {
                    "description": DESCRIPTION,
                    "keywords": KEYWORDS,
                    "promotionalText": PROMO,
                    "supportUrl": SUPPORT_URL,
                    "marketingUrl": MARKETING_URL,
                },
            }
        },
    )

    # 4. Age rating declaration — 4+, no objectionable content
    code, _ = call("GET", f"/v1/apps/{APP_ID}/ageRatingDeclaration")
    none_attrs = {
        "alcoholTobaccoOrDrugUseOrReferences": "NONE",
        "contests": "NONE",
        "gamblingAndContests": False,
        "gamblingSimulated": "NONE",
        "horrorOrFearThemes": "NONE",
        "matureOrSuggestiveThemes": "NONE",
        "medicalOrTreatmentInformation": "NONE",
        "profanityOrCrudeHumor": "NONE",
        "sexualContentGraphicAndNudity": "NONE",
        "sexualContentOrNudity": "NONE",
        "unrestrictedWebAccess": False,
        "violenceCartoonOrFantasy": "NONE",
        "violenceRealistic": "NONE",
        "violenceRealisticProlongedGraphicOrSadistic": "NONE",
        "kidsAgeBand": None,
        "ageRatingOverride": "NONE",
    }
    if 200 <= code < 300:
        # Existing record — PATCH it
        existing = call("GET", f"/v1/apps/{APP_ID}/ageRatingDeclaration")[1]
        decl_id = existing.get("data", {}).get("id")
        if decl_id:
            step(
                "age rating: 4+ (no objectionable content)",
                "PATCH",
                f"/v1/ageRatingDeclarations/{decl_id}",
                {
                    "data": {
                        "type": "ageRatingDeclarations",
                        "id": decl_id,
                        "attributes": none_attrs,
                    }
                },
            )
        else:
            print("  ! age rating: no existing declaration id, skipping (browser fallback)")
    else:
        print(f"  ! age rating: GET returned {code}, skipping (browser fallback)")


if __name__ == "__main__":
    main()
