#!/usr/bin/env python3
"""End-to-end App Store submission for Last Scroll v1.0.

Steps, idempotent at each phase:
  1. Find the latest processed iOS build for app 6767400033.
  2. Attach the build to v1.0 (appStoreVersion).
  3. Create a reviewSubmission for the app if one isn't already open.
  4. Add an appStoreVersion-for-review item pointing at v1.0.
  5. Submit the reviewSubmission.

Usage:
    python3 scripts/submit.py                # do everything that's ready
    python3 scripts/submit.py --wait <min>   # poll until build is processed
"""
from __future__ import annotations

import argparse
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
VERSION_ID = "f17153c0-fa4d-49c2-9b61-d78549173441"
BUNDLE_ID = "com.cheddarlebel.dopaminedetox"


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


def latest_build() -> dict | None:
    s, d = call(
        "GET",
        f"/v1/builds?filter[app]={APP_ID}&filter[preReleaseVersion.platform]=IOS"
        f"&sort=-uploadedDate&limit=1&fields[builds]=version,uploadedDate,processingState,expired",
    )
    if s != 200 or not isinstance(d, dict):
        raise SystemExit(f"GET builds failed: {s}\n{d}")
    items = d.get("data", [])
    return items[0] if items else None


def wait_for_build(timeout_min: int) -> dict:
    deadline = time.time() + timeout_min * 60
    last_state = None
    while time.time() < deadline:
        b = latest_build()
        if not b:
            print("  no build yet…")
        else:
            state = b["attributes"].get("processingState")
            if state != last_state:
                print(f"  build {b['id']} state={state} version={b['attributes'].get('version')}")
                last_state = state
            if state == "VALID":
                return b
            if state in ("INVALID", "FAILED"):
                raise SystemExit(f"build processing failed: {b}")
        time.sleep(60)
    raise SystemExit(f"timed out after {timeout_min} min waiting for build to process")


def attach_build_to_version(build_id: str) -> None:
    s, d = call(
        "PATCH",
        f"/v1/appStoreVersions/{VERSION_ID}/relationships/build",
        {"data": {"type": "builds", "id": build_id}},
    )
    if s not in (200, 204):
        raise SystemExit(f"attach build failed: {s}\n{d}")
    print(f"  ✓ attached build {build_id} to v1.0")


def open_review_submission() -> str:
    s, d = call(
        "GET",
        f"/v1/reviewSubmissions?filter[app]={APP_ID}"
        f"&filter[state]=READY_FOR_REVIEW,WAITING_FOR_REVIEW,IN_REVIEW",
    )
    if s == 200 and isinstance(d, dict):
        for sub in d.get("data", []):
            return sub["id"]
    s, d = call(
        "POST",
        "/v1/reviewSubmissions",
        {
            "data": {
                "type": "reviewSubmissions",
                "attributes": {"platform": "IOS"},
                "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
            }
        },
    )
    if s not in (201, 200) or not isinstance(d, dict):
        raise SystemExit(f"create reviewSubmission failed: {s}\n{d}")
    return d["data"]["id"]


def add_version_item(submission_id: str) -> None:
    s, d = call("GET", f"/v1/reviewSubmissions/{submission_id}/items")
    existing = []
    if s == 200 and isinstance(d, dict):
        for it in d.get("data", []):
            rel = it.get("relationships", {}).get("appStoreVersion", {}).get("data")
            if rel:
                existing.append(rel.get("id"))
    if VERSION_ID in existing:
        print("  ✓ version 1.0 already in submission")
        return
    s, d = call(
        "POST",
        "/v1/reviewSubmissionItems",
        {
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": VERSION_ID}},
                },
            }
        },
    )
    if s not in (201, 200) or not isinstance(d, dict):
        raise SystemExit(f"add reviewSubmissionItem failed: {s}\n{d}")
    print(f"  ✓ added v1.0 to submission {submission_id}")


def submit(submission_id: str) -> None:
    s, d = call(
        "PATCH",
        f"/v1/reviewSubmissions/{submission_id}",
        {"data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}},
    )
    if s not in (200, 204):
        # state-mutating may want POST instead
        s, d = call("POST", f"/v1/reviewSubmissions/{submission_id}/actions/submit", {})
    if s not in (200, 201, 204):
        raise SystemExit(f"submit failed: {s}\n{d}")
    print(f"  ✓ submitted {submission_id} for review")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--wait", type=int, default=0, help="poll Apple build processing N minutes (default: don't wait)")
    args = p.parse_args()

    print("1. Build")
    if args.wait > 0:
        build = wait_for_build(args.wait)
    else:
        build = latest_build()
        if not build:
            raise SystemExit("no build uploaded yet; run scripts/upload.sh first")
        state = build["attributes"].get("processingState")
        if state != "VALID":
            raise SystemExit(f"latest build state is {state}; re-run with --wait once processing")
    bid = build["id"]
    print(f"  using build {bid} version {build['attributes'].get('version')}")

    print("2. Attach build to v1.0")
    attach_build_to_version(bid)

    print("3. Review submission")
    sid = open_review_submission()
    print(f"  submission id: {sid}")

    print("4. Add v1.0 as an item")
    add_version_item(sid)

    print("5. Submit")
    submit(sid)

    print()
    print("Submitted. Watch status at:")
    print(f"  https://appstoreconnect.apple.com/apps/{APP_ID}/distribution/version")


if __name__ == "__main__":
    main()
