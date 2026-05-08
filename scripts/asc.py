#!/usr/bin/env python3
"""Tiny App Store Connect API client. Read-mostly, surgical writes.

Usage:
    python3 scripts/asc.py whoami            # confirm auth + list user info
    python3 scripts/asc.py find <bundleId>   # find one app by bundle id
    python3 scripts/asc.py list              # list app IDs (names only — no edits)
    python3 scripts/asc.py create-dopamine-detox

We deliberately do NOT touch any apps other than com.cheddarlebel.dopaminedetox.
The `create-dopamine-detox` command no-ops if the app already exists.
"""
from __future__ import annotations

import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

import jwt  # PyJWT

ISSUER_ID = "d40a5bd9-fd5a-4f65-a0aa-21804fbd2c72"
KEY_ID = "24P7LHL3QA"
P8_PATH = Path.home() / ".private_keys" / f"AuthKey_{KEY_ID}.p8"
API_BASE = "https://api.appstoreconnect.apple.com"

DOPAMINE_BUNDLE_ID = "com.cheddarlebel.dopaminedetox"
DOPAMINE_APP_NAME = "Dopamine Detox"
DOPAMINE_SKU = "dopamine-detox-ios"
DOPAMINE_PRIMARY_LOCALE = "en-US"


def _token() -> str:
    private_key = P8_PATH.read_text()
    now = int(time.time())
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + 20 * 60,
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(
        payload, private_key, algorithm="ES256", headers={"kid": KEY_ID, "typ": "JWT"}
    )


def _request(method: str, path: str, body: dict | None = None) -> dict:
    url = API_BASE + path if path.startswith("/") else path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {_token()}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        body_text = e.read().decode("utf-8", errors="replace")
        raise SystemExit(f"HTTP {e.code} {e.reason} on {method} {path}\n{body_text}") from None


def _get(path: str) -> dict:
    return _request("GET", path)


def _post(path: str, body: dict) -> dict:
    return _request("POST", path, body)


def whoami() -> None:
    apps = _get("/v1/apps?limit=1")
    print(f"OK — auth works. Visible apps: {apps.get('meta', {}).get('paging', {}).get('total', '?')}")


def find_app_by_bundle_id(bundle_id: str) -> dict | None:
    resp = _get(f"/v1/apps?filter[bundleId]={bundle_id}")
    apps = resp.get("data", [])
    return apps[0] if apps else None


def list_apps_minimal() -> None:
    resp = _get("/v1/apps?limit=200&fields[apps]=name,bundleId,sku")
    for app in resp.get("data", []):
        attrs = app.get("attributes", {})
        print(f"{app['id']}  {attrs.get('bundleId', '?'):40s}  {attrs.get('name', '?')}")


def find_bundle_id_resource(bundle_id: str) -> dict | None:
    resp = _get(f"/v1/bundleIds?filter[identifier]={bundle_id}&limit=1")
    items = resp.get("data", [])
    return items[0] if items else None


def create_dopamine_detox() -> None:
    existing = find_app_by_bundle_id(DOPAMINE_BUNDLE_ID)
    if existing:
        attrs = existing.get("attributes", {})
        print(
            f"Already exists — id={existing['id']}  name={attrs.get('name')}  "
            f"sku={attrs.get('sku')}.  No changes made."
        )
        return

    bundle = find_bundle_id_resource(DOPAMINE_BUNDLE_ID)
    if not bundle:
        raise SystemExit(
            f"Bundle ID {DOPAMINE_BUNDLE_ID} is not registered with the dev portal yet."
        )

    body = {
        "data": {
            "type": "apps",
            "attributes": {
                "name": DOPAMINE_APP_NAME,
                "bundleId": DOPAMINE_BUNDLE_ID,
                "sku": DOPAMINE_SKU,
                "primaryLocale": DOPAMINE_PRIMARY_LOCALE,
            },
            "relationships": {
                "bundleId": {"data": {"type": "bundleIds", "id": bundle["id"]}}
            },
        }
    }
    created = _post("/v1/apps", body)
    new_id = created.get("data", {}).get("id")
    print(f"Created Dopamine Detox in App Store Connect.  id={new_id}")


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cmd = sys.argv[1]
    if cmd == "whoami":
        whoami()
    elif cmd == "find" and len(sys.argv) >= 3:
        app = find_app_by_bundle_id(sys.argv[2])
        if not app:
            print("not found")
            return
        print(json.dumps(app, indent=2))
    elif cmd == "list":
        list_apps_minimal()
    elif cmd == "create-dopamine-detox":
        create_dopamine_detox()
    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
