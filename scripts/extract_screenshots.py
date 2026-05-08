#!/usr/bin/env python3
"""Export PNG attachments from an .xcresult bundle, renamed via manifest."""
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path


def main():
    xcresult = Path(sys.argv[1])
    out = Path(sys.argv[2])
    if not xcresult.exists():
        print(f"missing xcresult: {xcresult}", file=sys.stderr)
        sys.exit(1)
    out.mkdir(parents=True, exist_ok=True)

    subprocess.check_call(
        [
            "xcrun", "xcresulttool", "export", "attachments",
            "--path", str(xcresult),
            "--output-path", str(out),
        ],
        stdout=subprocess.DEVNULL,
    )

    manifest_path = out / "manifest.json"
    if not manifest_path.exists():
        print("no manifest.json — nothing exported", file=sys.stderr)
        return

    manifest = json.loads(manifest_path.read_text())
    renamed = 0
    for entry in manifest:
        for att in entry.get("attachments", []):
            src = out / att["exportedFileName"]
            suggested = att.get("suggestedHumanReadableName") or att["exportedFileName"]
            # The suggested name is like "01-control-center-idle_0_<UUID>.png" — strip the suffix.
            base = re.sub(r"_\d+_[0-9A-F-]+\.png$", ".png", suggested, flags=re.I)
            dst = out / base
            if src.exists():
                src.rename(dst)
                renamed += 1
    print(f"renamed {renamed} screenshots in {out}")


if __name__ == "__main__":
    main()
