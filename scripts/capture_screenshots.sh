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
