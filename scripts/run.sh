#!/usr/bin/env bash
# Build Dwell and launch it in the iOS Simulator, without opening Xcode.
#
#   ./scripts/run.sh                    # the booted iPhone simulator, or the newest one
#   ./scripts/run.sh "iPhone 18 Pro"    # a simulator by name
#
# Needs Xcode 26+ installed (xcodebuild comes with it); the Xcode app can stay closed.
set -euo pipefail
cd "$(dirname "$0")/.."

NAME="${1:-}"
BUNDLE_ID="app.dwell.ios"
DERIVED=".build/xcode" # .build/ is gitignored
UUID_PATTERN='[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}'

if [ -n "$NAME" ]; then
  UDID=$(xcrun simctl list devices available | grep -F "    $NAME (" | grep -Eo "$UUID_PATTERN" | head -1 || true)
  [ -n "$UDID" ] || { echo "No simulator called \"$NAME\". Available iPhones:"; xcrun simctl list devices available | grep -E '^ +iPhone'; exit 1; }
else
  UDID=$(xcrun simctl list devices booted | grep -E '^ +iPhone' | grep -Eo "$UUID_PATTERN" | head -1 || true)
  [ -n "$UDID" ] || UDID=$(xcrun simctl list devices available | grep -E '^ +iPhone' | grep -Eo "$UUID_PATTERN" | tail -1 || true)
  [ -n "$UDID" ] || { echo "No iPhone simulator found. Add one in Xcode > Settings > Components."; exit 1; }
fi

echo "Building Dwell…"
xcodebuild -project Dwell.xcodeproj -scheme Dwell -configuration Debug \
  -destination "id=$UDID" -derivedDataPath "$DERIVED" -quiet build

echo "Launching on $(xcrun simctl list devices | grep "$UDID" | sed -E 's/^ +//; s/ \(.*//')…"
xcrun simctl boot "$UDID" 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID "$UDID"
xcrun simctl install "$UDID" "$DERIVED/Build/Products/Debug-iphonesimulator/Dwell.app"
xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" >/dev/null
echo "Running."
