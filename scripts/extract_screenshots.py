#!/usr/bin/env python3
"""Extract PNG attachments from an .xcresult bundle into a flat folder."""
import json
import shutil
import subprocess
import sys
from pathlib import Path


def run(args):
    return subprocess.check_output(args).decode()


def main():
    xcresult = Path(sys.argv[1])
    out = Path(sys.argv[2])
    if not xcresult.exists():
        print(f"missing xcresult: {xcresult}", file=sys.stderr)
        sys.exit(1)
    out.mkdir(parents=True, exist_ok=True)

    root = json.loads(run([
        "xcrun", "xcresulttool", "get", "--legacy",
        "--path", str(xcresult), "--format", "json",
    ]))

    refs = root.get("actions", {}).get("_values", [])
    test_ref_id = None
    for action in refs:
        ref = action.get("actionResult", {}).get("testsRef", {}).get("id", {}).get("_value")
        if ref:
            test_ref_id = ref
            break
    if not test_ref_id:
        print("no testsRef in xcresult", file=sys.stderr)
        sys.exit(1)

    tests = json.loads(run([
        "xcrun", "xcresulttool", "get", "--legacy",
        "--path", str(xcresult), "--id", test_ref_id, "--format", "json",
    ]))

    extracted = 0
    def walk(node):
        nonlocal extracted
        for k, v in (node.items() if isinstance(node, dict) else []):
            if isinstance(v, dict):
                walk(v)
            elif isinstance(v, list):
                for item in v:
                    if isinstance(item, dict):
                        walk(item)
        attachments = node.get("activitySummaries", {}).get("_values", [])
        for activity in attachments:
            for att in activity.get("attachments", {}).get("_values", []):
                name = att.get("name", {}).get("_value", "screenshot")
                payload_id = att.get("payloadRef", {}).get("id", {}).get("_value")
                if not payload_id or not name.endswith(".png") and "screenshot" not in name.lower():
                    continue
                out_name = name if name.endswith(".png") else f"{name}.png"
                out_path = out / out_name
                subprocess.check_call([
                    "xcrun", "xcresulttool", "export", "--legacy",
                    "--path", str(xcresult),
                    "--id", payload_id,
                    "--type", "file",
                    "--output-path", str(out_path),
                ])
                extracted += 1

    walk(tests)
    print(f"extracted {extracted} screenshots to {out}")


if __name__ == "__main__":
    main()
