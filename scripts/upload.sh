#!/usr/bin/env bash
# Upload Last Scroll v1.0 to App Store Connect.
# Run this once Apple has approved the Family Controls entitlement and the
# capability has been ticked on both App IDs in the Developer Portal.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCHIVE="$ROOT/build/Last_Scroll.xcarchive"
EXPORT="$ROOT/build/export"
KEY="${ASC_KEY:-24P7LHL3QA}"
ISSUER="${ASC_ISSUER:-d40a5bd9-fd5a-4f65-a0aa-21804fbd2c72}"
P8="${ASC_P8:-$HOME/.private_keys/AuthKey_${KEY}.p8}"

cd "$ROOT"
rm -rf "$ARCHIVE" "$EXPORT"

echo '==> Archive'
xcodebuild archive \
  -project DopamineDetox.xcodeproj \
  -scheme DopamineDetox \
  -destination 'generic/platform=iOS' \
  -configuration Release \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  -authenticationKeyPath "$P8" \
  -authenticationKeyID "$KEY" \
  -authenticationKeyIssuerID "$ISSUER" | xcbeautify --quiet

echo '==> Export + upload'
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT" \
  -exportOptionsPlist ci/ExportOptions.plist \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$P8" \
  -authenticationKeyID "$KEY" \
  -authenticationKeyIssuerID "$ISSUER" | xcbeautify --quiet

echo
echo "Build uploaded. Watch processing at https://appstoreconnect.apple.com/apps/6767400033/testflight/builds"
