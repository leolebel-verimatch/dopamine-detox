#!/usr/bin/env python3
"""Upload screenshots from screenshots/<bucket>/*.png to ASC v1.0 en-US.

Replaces the existing AppScreenshotSet contents for each display type before
uploading new images. Idempotent: re-running re-deletes + re-uploads.

Buckets recognized:
  6.9-inch  -> APP_IPHONE_69
  13-inch   -> APP_IPAD_PRO_3GEN_129  (Apple's ID for the iPad Pro 13" — they
              haven't introduced a 13" specific bucket yet; the 12.9" type is
              accepted for iPad Pro 13".)
"""
from __future__ import annotations

import hashlib
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

VERSION_ID = "f17153c0-fa4d-49c2-9b61-d78549173441"
VERSION_LOC_ID = "e7607770-0e08-47ba-a6cc-69052a26abd6"  # en-US

DISPLAY = {
    "6.9-inch": "APP_IPHONE_67",
    "13-inch": "APP_IPAD_PRO_3GEN_129",
}


def _tok() -> str:
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 20 * 60, "aud": "appstoreconnect-v1"},
        P8_PATH.read_text(),
        algorithm="ES256",
        headers={"kid": KEY_ID, "typ": "JWT"},
    )


def call(method: str, path: str, body: dict | None = None) -> tuple[int, dict | str]:
    url = path if path.startswith("http") else API_BASE + path
    req = urllib.request.Request(
        url,
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


def find_or_create_set(display_type: str) -> str:
    s, d = call("GET", f"/v1/appStoreVersionLocalizations/{VERSION_LOC_ID}/appScreenshotSets")
    if s == 200 and isinstance(d, dict):
        for item in d.get("data", []):
            if item.get("attributes", {}).get("screenshotDisplayType") == display_type:
                return item["id"]
    s, d = call(
        "POST",
        "/v1/appScreenshotSets",
        {
            "data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": display_type},
                "relationships": {
                    "appStoreVersionLocalization": {
                        "data": {"type": "appStoreVersionLocalizations", "id": VERSION_LOC_ID}
                    }
                },
            }
        },
    )
    if s in (200, 201) and isinstance(d, dict):
        return d["data"]["id"]
    raise SystemExit(f"create screenshot set failed: {s}\n{d}")


def list_screenshots(set_id: str) -> list[dict]:
    s, d = call("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots?limit=200")
    if s != 200 or not isinstance(d, dict):
        return []
    return d.get("data", [])


def delete_screenshot(asset_id: str) -> None:
    s, d = call("DELETE", f"/v1/appScreenshots/{asset_id}")
    if s not in (200, 204):
        print(f"  ! failed to delete {asset_id}: {s}")


def upload_image(set_id: str, image: Path) -> None:
    data = image.read_bytes()
    size = len(data)
    s, d = call(
        "POST",
        "/v1/appScreenshots",
        {
            "data": {
                "type": "appScreenshots",
                "attributes": {"fileName": image.name, "fileSize": size},
                "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
            }
        },
    )
    if s not in (200, 201) or not isinstance(d, dict):
        raise SystemExit(f"reserve {image.name} failed: {s}\n{d}")
    asset = d["data"]
    asset_id = asset["id"]
    ops = asset["attributes"]["uploadOperations"]
    for op in ops:
        offset = op["offset"]
        length = op["length"]
        chunk = data[offset : offset + length]
        headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        req = urllib.request.Request(op["url"], data=chunk, method=op["method"], headers=headers)
        with urllib.request.urlopen(req) as resp:
            assert resp.status in (200, 201, 204), f"upload chunk: {resp.status}"

    checksum = hashlib.md5(data).hexdigest()
    s, d = call(
        "PATCH",
        f"/v1/appScreenshots/{asset_id}",
        {
            "data": {
                "type": "appScreenshots",
                "id": asset_id,
                "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
            }
        },
    )
    if s not in (200, 204):
        raise SystemExit(f"commit {image.name} failed: {s}\n{d}")
    print(f"  ✓ {image.name}")


def main() -> None:
    root = Path(__file__).resolve().parent.parent / "screenshots"
    for bucket, display_type in DISPLAY.items():
        folder = root / bucket
        if not folder.is_dir():
            print(f"  ! missing folder {folder}")
            continue
        images = sorted(folder.glob("*.png"))
        if not images:
            print(f"  ! no images in {folder}")
            continue
        print(f"==> {bucket} ({display_type}): {len(images)} images")
        set_id = find_or_create_set(display_type)
        existing = list_screenshots(set_id)
        for e in existing:
            delete_screenshot(e["id"])
        for img in images:
            upload_image(set_id, img)


if __name__ == "__main__":
    main()
