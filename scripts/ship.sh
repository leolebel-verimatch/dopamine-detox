#!/usr/bin/env bash
# Full release: archive, upload to ASC, wait for processing, submit for review.
# Run this after Apple has approved the Family Controls Distribution
# entitlement and you've ticked the capability on both App IDs.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

"$ROOT/scripts/upload.sh"

echo
echo '==> Waiting for Apple to finish processing the build (up to 60 min)'
python3 "$ROOT/scripts/submit.py" --wait 60
