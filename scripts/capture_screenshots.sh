#!/usr/bin/env bash
set -euo pipefail

# Capture App Store screenshots on the device sizes Apple requires.
# Output: screenshots/<size>/<name>.png

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/screenshots"
mkdir -p "$OUT"

# 6.9" / 6.7" (iPhone 16 Pro Max or 17 Pro Max — required)
# 6.5" iPad (iPad Pro 13" — required if iPad supported)
DEVICES=(
  "iPhone 17 Pro Max:6.9-inch"
  "iPad Pro 13-inch (M5):13-inch"
)

for spec in "${DEVICES[@]}"; do
  device="${spec%%:*}"
  bucket="${spec##*:}"
  echo "==> Capturing on $device ($bucket)"
  rm -rf "$OUT/$bucket"
  mkdir -p "$OUT/$bucket"

  # Stale simulator state (orphaned XPC handles, dyld caches) trips the
  # XCUITest runner with "Application failed preflight checks". Reset.
  xcrun simctl shutdown all >/dev/null 2>&1 || true
  device_id=$(xcrun simctl list devices available | grep -F "$device (" | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
  if [ -n "$device_id" ]; then
    xcrun simctl erase "$device_id" 2>/dev/null || true
  fi

  xcodebuild test \
    -project "$ROOT/DopamineDetox.xcodeproj" \
    -scheme DopamineDetox \
    -only-testing:DopamineDetoxUITests/ScreenshotTests \
    -destination "platform=iOS Simulator,name=$device" \
    -derivedDataPath "$ROOT/build" \
    -resultBundlePath "$OUT/$bucket/result.xcresult" \
    CODE_SIGNING_ALLOWED=NO \
    -quiet || true

  # Extract attachments from the xcresult
  python3 "$ROOT/scripts/extract_screenshots.py" "$OUT/$bucket/result.xcresult" "$OUT/$bucket"
done

echo
echo "Done. Screenshots in $OUT"
